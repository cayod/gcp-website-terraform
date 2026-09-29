# 0002. Hosting approaches: Cloud Storage and Managed Instance Group

- Status: Accepted
- Date: 2026-09-28

## Context

The challenge asks for two ways to serve a website on Google Cloud, with the reasons for the choice and for the rejected options.
The site is static HTML.
Requirements: redeployment on HTML change, a stable DNS name or IP, optional TLS, low cost, and deployment to two projects with different parameters such as machine type and region.

## Decision

We implement two approaches that contrast managed storage with managed compute.

### Approach A: Cloud Storage behind a global external Application Load Balancer

```
User -> static global IP -> HTTPS LB (managed cert, HTTP to HTTPS redirect)
     -> Cloud CDN -> backend bucket -> Cloud Storage bucket
```

- This is the canonical way to serve static content on Google Cloud: no servers, no patching, scales automatically.
- Redeployment: Terraform tracks the HTML content hash and uploads the object again when it changes.
- `index.html` is served with `Cache-Control: no-cache` so the CDN revalidates and never serves a stale page after a deploy.

### Approach B: Managed Instance Group behind a global external Application Load Balancer

```
User -> static global IP -> HTTPS LB -> backend service + health check
     -> regional MIG (Container-Optimized OS + nginx)
```

- Demonstrates compute-based hosting: instance templates, rolling updates, health checks, autohealing, and a configurable machine type.
- Redeployment: the HTML is part of the instance template metadata.
  A change produces a new template, and the MIG performs a proactive rolling update without downtime.
- Runtime details are in [ADR 0006](0006-mig-runtime.md).

## Alternatives considered

| Option | Reason for rejection |
|---|---|
| Cloud Run | Strong production choice, but requires an image build pipeline to serve a single HTML file. It is the natural evolution if the site becomes dynamic. |
| Firebase Hosting | Abstracts away the infrastructure this challenge evaluates, and its Terraform support is partial and beta-only. |
| App Engine | One application per project, region cannot change after creation, and the platform receives little new investment. |
| GKE | Cost and operational overhead are disproportionate for static content. |
| Cloud Functions | Designed for event-driven code, not for serving static content. |

## Consequences

- Both approaches share the same load balancer module, so TLS, redirect, and static IP behavior are identical.
- The load balancer is the dominant fixed cost in both approaches, about USD 18 per month per project.
  Both stacks in the same project share the first-five forwarding rules price block.
- Approach A has a near-zero marginal cost; approach B adds VM and disk cost.
- Approach B requires more operational concerns (image pinning, health checks, rolling update tuning), which is the point of demonstrating it.
