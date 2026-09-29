# 0007. Stable endpoint and TLS

- Status: Accepted
- Date: 2026-09-28

## Context

The DNS name or IP address must stay the same after a redeployment.
TLS is optional but recommended.
No registered domain or Cloud DNS zone is available for this project.

## Decision

- Each stack uses a global static external IP reserved in the foundation layer, not in the stack.
  The endpoint survives redeployments and even a full destroy and recreate of a stack.
- The hostname is derived from the IP with sslip.io, for example `34-1-2-3.sslip.io`.
- A Google-managed SSL certificate is issued for that hostname.
- HTTP requests are redirected to HTTPS with a permanent redirect.
- A `domain` variable overrides the derived hostname when a real domain is available.

## Consequences

- IP and hostname are stable by construction.
- TLS works without buying a domain.
- Certificate provisioning takes 15 to 60 minutes after the first apply; HTTP answers meanwhile.
- The public sslip.io resolver is an external dependency, acceptable for a demonstration and replaceable through `domain`.
- A reserved but unused IP costs about USD 7 per month if a stack is destroyed while the foundation remains.

## Alternatives considered

- IP reserved inside each stack: a destroy, recreate, or resource rename changes the endpoint.
- Registering a domain with Cloud DNS: the most production-like option, but outside the budget and scope; supported through the `domain` variable.
- Self-signed certificate: browsers reject it, which defeats the purpose.
