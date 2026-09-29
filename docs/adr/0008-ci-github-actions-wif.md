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

`ci.yml` runs on pull requests:

1. gitleaks, `terraform fmt -check`, `terraform validate`, tflint, and trivy config scanning.
2. `terraform test` for the modules.
3. A matrix of `{dev, prod} x {gcs, mig}` running `make plan` with the read-only plan identity; the summary is posted to the pull request.

`deploy.yml` runs on pushes to `main` that touch `site/**`, `modules/**`, `stacks/**`, or `envs/**`:

1. Apply both stacks to `dev`, then run a smoke test.
2. Apply both stacks to `prod` through the `prod` GitHub Environment, which requires manual approval, then run a smoke test.
3. A concurrency group per environment prevents parallel applies.
4. `workflow_dispatch` allows manual runs.

Project IDs and the Workload Identity provider name are repository variables, not secrets, because they are not sensitive.
The foundation layer is never applied by CI.

## Consequences

- Any HTML change merged to `main` reaches `dev` automatically and `prod` after approval.
- Pull requests from forks cannot obtain credentials.
- The repository contains no secrets.

## Alternatives considered

- Cloud Build: equally valid, but GitHub Actions keeps code, review, and pipeline in one place.
- Service account JSON keys stored as GitHub secrets: long-lived credentials that can leak, explicitly discouraged by the challenge.
