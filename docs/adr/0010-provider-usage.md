# 0010. Usage of the google and google-beta providers

- Status: Proposed
- Date: 2026-09-28

## Context

The challenge requires the `google` and `google-beta` providers.
Most resources needed here are generally available in the `google` provider.
Using beta resources without a reason adds instability.

## Decision

- Both providers are declared and pinned in every root module, configured with the same project and region.
- `google` is the default for every resource.
- `google-beta` is used only for resources or fields that are beta-only and bring real value to this design.
- Candidate resources will be verified against the current provider documentation during implementation.
- If no beta-only feature brings value, this record will explain it instead of forcing a beta resource.

## Consequences

- Beta usage is explicit and justified in code through the `provider = google-beta` argument.
- This record moves to Accepted once the concrete usage is confirmed.
