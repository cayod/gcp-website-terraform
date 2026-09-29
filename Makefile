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

.PHONY: help check-args init plan apply destroy output fmt fmt-check validate test

help: ## Show available targets
	@echo "Usage: make <target> ENV=<$(subst $(space),|,$(ENVS))> STACK=<$(subst $(space),|,$(STACKS))>"
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

check-args:
	@case "$(ENV)" in $(subst $(space),|,$(ENVS))) ;; *) echo "ENV must be one of: $(ENVS)" >&2; exit 1;; esac
	@case "$(STACK)" in $(subst $(space),|,$(STACKS))) ;; *) echo "STACK must be one of: $(STACKS)" >&2; exit 1;; esac

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
