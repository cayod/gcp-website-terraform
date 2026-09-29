# 0005. Environment parameterization with tfvars and a Makefile

- Status: Accepted
- Date: 2026-09-28

## Context

The same code must deploy to two projects, `dev` and `prod`, with different parameters such as region, machine type, and domain.
With two stacks and two environments there are four combinations of backend and variables, and a wrong combination could apply `dev` values to `prod`.

## Decision

- Each root module has one code path shared by all environments.
- Environment values live in `envs/<env>/`, committed because they contain no secrets:
  - `common.tfvars` holds values every root module declares, such as the project and region.
  - `<stack>.tfvars` holds values specific to one root module, such as the machine type for `mig`.
  - `backend.gcs.tfbackend` names the state bucket of the target project.
- Splitting values per root module avoids passing undeclared variables to a module, which Terraform reports as warnings.
- Backend settings are passed at init time with `-backend-config`, and the state prefix is derived from the root module path.
- A `Makefile` is the single entry point: `make plan ENV=dev STACK=mig` and `make apply ENV=prod STACK=gcs`.
  It validates `ENV` and `STACK` and derives the backend prefix.
- CI calls the same Makefile targets, so documented commands and pipeline commands are identical.
- Reviewers deploy into their own projects by editing the project IDs in `envs/<env>/common.tfvars` and the bucket in `backend.gcs.tfbackend`.

Planned differences between environments:

| Variable | dev | prod |
|---|---|---|
| `region` | us-central1 | us-central1 |
| `machine_type` | e2-micro | e2-micro |
| `instance_count` | 1 (zonal) | 2 (regional, high availability) |
| `domain` | derived `<ip>.sslip.io` | derived `<ip>.sslip.io` |
| `budget_amount` | 50 | 100 |

All variables are typed and validated.

Both environments use the same region on purpose.
Parity between `dev` and `prod` means that what is validated in `dev` behaves the same in `prod`:
machine type availability, quotas, and prices are regional, and a region-specific issue would otherwise reach `prod` untested.
The region remains a parameter; a different region is justified only when environments serve users in different geographies.
`us-central1` also qualifies for the Compute Engine free tier.

## Consequences

- Adding an environment means adding one `envs/<env>/` directory and applying the foundation once.
- Operators never type backend or var-file flags by hand.

## Alternatives considered

- Terraform workspaces: all workspaces share one backend and one set of credentials, which breaks the isolation required by [ADR 0004](0004-remote-state-per-project.md).
- One directory per environment with duplicated root modules: duplicates code and lets environments drift.
- Terragrunt: solves the same problem with an extra tool, which is not justified at this size.
