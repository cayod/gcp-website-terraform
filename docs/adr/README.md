# Architecture Decision Records

This directory records the significant architectural decisions of this project.
Each record follows a lightweight format: context, decision, consequences, and alternatives considered.

| ADR | Title | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-hosting-approaches.md) | Hosting approaches: Cloud Storage and Managed Instance Group | Accepted |
| [0003](0003-layered-configuration.md) | Layered configuration: foundation and stacks | Accepted |
| [0004](0004-remote-state-per-project.md) | Remote state in one bucket per project | Accepted |
| [0005](0005-environment-parameterization.md) | Environment parameterization with tfvars and a Makefile | Accepted |
| [0006](0006-mig-runtime.md) | MIG runtime: Container-Optimized OS without internet egress | Accepted |
| [0007](0007-stable-endpoint-and-tls.md) | Stable endpoint and TLS | Accepted |
| [0008](0008-ci-github-actions-wif.md) | CI/CD with GitHub Actions and Workload Identity Federation | Accepted |
| [0009](0009-least-privilege-iam.md) | Least-privilege IAM model | Accepted |
| [0010](0010-provider-usage.md) | Usage of the google and google-beta providers | Proposed |
