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

Every resource of this design is generally available in `google` 8.x:
load balancing, managed certificates, SSL policies, Cloud CDN, managed instance groups, Artifact Registry remote repositories, Workload Identity Federation, and billing budgets.
No resource currently uses `google-beta`.

Forcing a beta resource only to use the provider would trade stability for appearance.
The provider stays configured, so a beta-only feature can be adopted with a one-line `provider` argument, for example Cloud Armor features that are still in preview.

## Consequences

- Production resources run on the stable API surface only.
- The beta provider is ready for use without further setup.
