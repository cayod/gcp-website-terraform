SHELL := /bin/bash
.DEFAULT_GOAL := help

ENVS   := dev prod
STACKS := foundation gcs mig

ENV   ?=
STACK ?=

# Extra flags, for example PLAN_ARGS=-lock=false in CI or APPLY_ARGS=-auto-approve.
PLAN_ARGS  ?=
APPLY_ARGS ?=

empty :=
space := $(empty) $(empty)

ROOT_DIR        = $(if $(filter foundation,$(STACK)),foundation,stacks/$(STACK))
ENV_DIR         = $(CURDIR)/envs/$(ENV)
BACKEND_CONFIG  = $(ENV_DIR)/backend.gcs.tfbackend
VAR_FILES       = $(foreach f,$(wildcard $(ENV_DIR)/common.tfvars $(ENV_DIR)/$(STACK).tfvars),-var-file=$(f))
TF              = terraform -chdir=$(ROOT_DIR)
TF_ROOTS        = foundation $(wildcard stacks/*)
TF_TESTED_DIRS  = $(patsubst %/tests/,%,$(dir $(wildcard modules/*/tests/)))

BOOTSTRAP_OVERRIDE = foundation/bootstrap_override.tf
APP_STACKS         = $(filter-out foundation,$(STACKS))

.PHONY: help check-args bootstrap teardown init plan apply destroy output smoke-test fmt fmt-check validate test

help: ## Show available targets
	@echo "Usage: make <target> ENV=<$(subst $(space),|,$(ENVS))> STACK=<$(subst $(space),|,$(STACKS))>"
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

check-args:
	@case "$(ENV)" in $(subst $(space),|,$(ENVS))) ;; *) echo "ENV must be one of: $(ENVS)" >&2; exit 1;; esac
	@case "$(STACK)" in $(subst $(space),|,$(STACKS))) ;; *) echo "STACK must be one of: $(STACKS)" >&2; exit 1;; esac

# The state bucket does not exist before the foundation creates it, so the first apply
# uses a temporary local backend and then migrates the state into the new bucket.
bootstrap: STACK = foundation
bootstrap: check-args ## Create the foundation of ENV with local state, then migrate it to the bucket
	printf 'terraform {\n  backend "local" {}\n}\n' > $(BOOTSTRAP_OVERRIDE)
	$(TF) init -reconfigure -input=false
	$(TF) apply -input=false $(VAR_FILES) $(APPLY_ARGS)
	rm $(BOOTSTRAP_OVERRIDE)
	$(TF) init -migrate-state -force-copy -input=false \
		-backend-config=$(BACKEND_CONFIG) \
		-backend-config="prefix=$(ROOT_DIR)"
	rm -f $(ROOT_DIR)/terraform.tfstate $(ROOT_DIR)/terraform.tfstate.backup

# Mirror of bootstrap. The state bucket belongs to the foundation, so the state moves back to a
# local backend first, and the bucket may only be deleted with its content during a teardown.
teardown: STACK = foundation
teardown: check-args ## Destroy the foundation of ENV, after its stacks, moving its state back to local
	@set -e; for stack in $(APP_STACKS); do \
		$(MAKE) --no-print-directory init ENV=$(ENV) STACK=$$stack >/dev/null; \
		if [ -n "$$(terraform -chdir=stacks/$$stack state list)" ]; then \
			echo "Stack $$stack still has resources in $(ENV): run make destroy ENV=$(ENV) STACK=$$stack first" >&2; exit 1; \
		fi; \
	done
	$(MAKE) --no-print-directory init ENV=$(ENV) STACK=foundation
	printf 'terraform {\n  backend "local" {}\n}\n' > $(BOOTSTRAP_OVERRIDE)
	$(TF) init -migrate-state -force-copy -input=false
	$(TF) apply -input=false $(VAR_FILES) -var=state_bucket_force_destroy=true -target=google_storage_bucket.tfstate $(APPLY_ARGS)
	$(TF) destroy -input=false $(VAR_FILES) -var=state_bucket_force_destroy=true $(APPLY_ARGS)
	rm -f $(BOOTSTRAP_OVERRIDE) $(ROOT_DIR)/terraform.tfstate $(ROOT_DIR)/terraform.tfstate.backup

init: check-args ## Initialize the backend of STACK for ENV
	$(TF) init -reconfigure -input=false \
		-backend-config=$(BACKEND_CONFIG) \
		-backend-config="prefix=$(ROOT_DIR)"

plan: init ## Plan STACK for ENV
	$(TF) plan -input=false $(VAR_FILES) $(PLAN_ARGS)

apply: init ## Apply STACK for ENV
	$(TF) apply -input=false $(VAR_FILES) $(APPLY_ARGS)

destroy: init ## Destroy STACK for ENV
	$(TF) destroy -input=false $(VAR_FILES)

output: init ## Show the outputs of STACK for ENV
	$(TF) output

smoke-test: init ## Check that the site of STACK in ENV serves its page over HTTPS
	scripts/smoke-test.sh "$$($(TF) output -raw url)" "<dd>$(ENV)</dd>"

fmt: ## Format all Terraform files
	terraform fmt -recursive

fmt-check: ## Fail if any Terraform file is not formatted
	terraform fmt -recursive -check -diff

validate: ## Validate every root module without a backend
	@set -e; for dir in $(TF_ROOTS); do \
		echo "==> $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

test: ## Run terraform test for every module that has tests
	@set -e; for dir in $(TF_TESTED_DIRS); do \
		echo "==> $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done
