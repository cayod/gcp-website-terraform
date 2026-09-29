# 0008. CI/CD with GitHub Actions and Workload Identity Federation

- Status: Accepted
- Date: 2026-09-28

## Context

A change to the HTML must cause a redeployment.
CI must authenticate to Google Cloud without long-lived keys.
Production changes should be reviewed before they apply.

## Decision

Authentication uses Workload Identity Federation with GitHub OIDC tokens.
No service account key exists anywhere.

`ci.yml` runs on pull requests and on pushes to `main`:

1. gitleaks over the full history, `terraform fmt -check`, `terraform validate`, tflint, and trivy config scanning.
2. `terraform test` for the modules.
3. On pull requests only, a matrix of `{dev, prod} x {gcs, mig}` running `make plan` with the read-only plan identity.
   The summary is written to the job summary, so the workflow needs no permission to write to pull requests.

`deploy.yml` runs on pushes to `main` that touch `site/**`, `modules/**`, `stacks/**`, `envs/**`, or `scripts/**`:

1. Apply both stacks to `dev`, then run a smoke test.
2. Apply both stacks to `prod` through the `prod` GitHub Environment, which requires manual approval, then run a smoke test.
3. Both stages call the same reusable workflow, `apply.yml`, so `dev` and `prod` run identical steps.
4. A concurrency group per environment and stack prevents parallel applies.
5. `workflow_dispatch` allows manual runs.

Every third-party action is pinned by commit SHA and every container image by digest, because tags can be moved.

Project IDs and the Workload Identity provider names are repository variables, not secrets, because they are not sensitive.
The foundation layer is never applied by CI.

## Consequences

- Any HTML change merged to `main` reaches `dev` automatically and `prod` after approval.
- Pull requests from forks cannot obtain credentials.
- The repository contains no secrets.

## Alternatives considered

- Cloud Build: equally valid, but GitHub Actions keeps code, review, and pipeline in one place.
- Service account JSON keys stored as GitHub secrets: long-lived credentials that can leak, explicitly discouraged by the challenge.
