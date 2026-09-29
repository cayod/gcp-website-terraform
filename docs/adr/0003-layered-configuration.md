# 0003. Layered configuration: foundation and stacks

- Status: Accepted
- Date: 2026-09-28

## Context

Some resources are created once and change rarely: the project, enabled APIs, the state bucket, identities, IAM, the network, and static IPs.
Other resources change on every deployment: the site content, instance templates, and load balancer wiring.
Mixing both in one configuration forces the CI identity to hold permissions to manage IAM and identities, which violates least privilege.

## Decision

We split the code into layers with different lifecycles and different operators.

| Layer | Applied by | Contents | Frequency |
|---|---|---|---|
| `foundation/` | A human with elevated credentials | Project (optional creation), APIs, state bucket, Workload Identity Federation, service accounts, VPC, subnet, firewall, static IPs, Artifact Registry repository, budget | Once per environment |
| `stacks/gcs` | CI | Site bucket, backend bucket, CDN, load balancer, certificate | On every change |
| `stacks/mig` | CI | Instance template, MIG, health check, backend service, load balancer, certificate | On every change |

Reusable building blocks live in `modules/` (`https-lb`, `site-gcs`, `site-mig`) and are composed by the stacks.
Stacks read foundation values through input variables populated from foundation outputs.

## Consequences

- The CI identity never creates service accounts, changes project IAM, or modifies the network.
- A stack can be destroyed and recreated without losing its IP address.
- Setting up a new environment has one manual, documented step: applying the foundation.
- There are two more root modules to maintain, which is acceptable given the security benefit.

## Alternatives considered

- Single root module: simpler, but requires the CI identity to be effectively a project owner.
- One stack for both approaches: couples the lifecycles of two independent designs and makes each harder to reason about.
