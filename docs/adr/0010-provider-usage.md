# 0010. Usage of the google and google-beta providers

- Status: Accepted
- Date: 2026-09-29

## Context

Some Google Cloud features ship first in the `google-beta` provider, so both providers are part of this design.
Most resources needed here are generally available in the `google` provider.
Using beta resources without a reason adds instability.

## Decision

- Both providers are declared, version-pinned, and configured with the same project, region, and labels in every root module.
- `google` is the default for every resource.
- `google-beta` is used only for resources or fields that are beta-only and bring real value to this design, through an explicit `provider = google-beta` argument.

## Outcome of the implementation

The candidates were found by comparing the schemas of both providers at the pinned version, for the resources this design uses.

`google-beta` is used for the regional managed instance group, for `update_policy.min_ready_sec`.
During a rolling update, the MIG retires an old instance as soon as its replacement passes the autohealing health check, while the load balancer routes to the new instance only after its own probes succeed `healthy_threshold` times.
`min_ready_sec` makes the rollout wait longer than that, so no zone is left without an instance the load balancer can use.
The value is derived from the health check settings, and a module test enforces the relation.

Every other resource is generally available in `google` 8.x and stays on the stable provider.
The other beta-only fields of these resources, such as request mirroring, circuit breakers, and graceful shutdown, bring no value to a static site.

## Consequences

- Beta usage is limited to one resource and one field, with the reason written next to it.
- When `min_ready_sec` reaches general availability, the resource moves back to `google` by removing its `provider` argument.
