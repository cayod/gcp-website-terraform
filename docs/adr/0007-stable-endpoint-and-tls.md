# 0007. Stable endpoint and TLS

- Status: Accepted
- Date: 2026-09-28

## Context

The DNS name or IP address must stay the same after a redeployment.
Traffic must be encrypted with a certificate that browsers trust.
The site must be reachable over TLS without depending on a registered domain.

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
- A new certificate takes 10 to 20 minutes to become active, and up to 60 in the worst case; HTTP answers with a redirect meanwhile.
- The public sslip.io resolver is an external dependency, replaceable at any time through `domain`.
- A reserved but unused IP costs about USD 7 per month if a stack is destroyed while the foundation remains.

## Alternatives considered

- IP reserved inside each stack: a destroy, recreate, or resource rename changes the endpoint.
- Registering a domain with Cloud DNS: the most production-like option, and a one-variable change through `domain` once a domain exists.
- Self-signed certificate: browsers reject it, which defeats the purpose.
