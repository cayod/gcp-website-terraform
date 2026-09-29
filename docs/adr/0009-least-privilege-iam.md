# 0009. Least-privilege IAM model

- Status: Accepted
- Date: 2026-09-28

## Context

The challenge evaluates whether IAM grants are the minimum necessary.
Different actors need different permissions: planning, applying, and running workloads.

## Decision

| Identity | Roles | Scope |
|---|---|---|
| Plan service account (pull requests) | `roles/viewer`, `roles/iam.securityReviewer`, `roles/storage.objectViewer` | Project; `securityReviewer` lets plans read IAM policies, `objectViewer` lets them read state and site objects |
| Apply service account (main and approved deploys) | `roles/compute.instanceAdmin.v1`, `roles/compute.loadBalancerAdmin`, `roles/compute.networkUser`, `roles/storage.admin`, `roles/iam.serviceAccountUser` | Project, except `serviceAccountUser`, which is granted only on the VM service account |
| VM service account | `roles/logging.logWriter`, `roles/monitoring.metricWriter`, `roles/artifactregistry.reader` | Project for logging and monitoring, the remote repository only for Artifact Registry |

Workload Identity Federation bindings:

- The provider accepts only tokens where `repository` matches this repository.
- The plan identity is bound to pull request tokens of this repository.
- The apply identity of each environment is bound to `repo:<owner>/<repo>:environment:<env>`.

Plans run with `-lock=false` so the plan identity needs no write access to the state bucket.

## Consequences

- CI cannot create identities, change project IAM, or modify the network.
- A compromised pull request workflow can read but not change infrastructure.
- `roles/storage.admin` is project-level because the stack creates the site bucket.
  Moving the bucket to the foundation would narrow it, at the cost of an almost empty stack.
- The site bucket grants `roles/storage.objectViewer` to `allUsers`, which backend buckets require.
  The bucket contains only public site content.
- The exact role set will be validated during implementation and narrowed further if possible.

## Alternatives considered

- `roles/editor` or `roles/owner` for CI: simple, but violates least privilege.
- Custom roles: tightest possible scope, but costly to maintain and hard to review for this size.
