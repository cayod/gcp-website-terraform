# 0006. MIG runtime: Container-Optimized OS without internet egress

- Status: Accepted
- Date: 2026-09-28

## Context

The VMs of approach B need a web server.
Installing it at boot from public package mirrors makes boot slow, non-reproducible, and dependent on internet egress.
Internet egress for private VMs requires Cloud NAT, and public IPs on VMs increase the attack surface.

## Decision

- VMs run Container-Optimized OS and start an nginx container pinned by image digest.
- The image is pulled from an Artifact Registry remote repository that proxies Docker Hub.
- The subnet has Private Google Access, so VMs reach Artifact Registry without any internet route.
- VMs have no external IP, no Cloud NAT, and no SSH access.
- The HTML is delivered through cloud-init metadata in the instance template.
- The instance template uses `name_prefix` with `create_before_destroy`, and the MIG uses a proactive rolling update policy.
- A dedicated service account runs the VMs, never the Compute Engine default service account.
- Firewall rules only allow load balancer health check ranges (`35.191.0.0/16`, `130.211.0.0/22`) on the serving port.

## Consequences

- Boot is fast and deterministic; every VM runs the same nginx build.
- There is no path from the VMs to the internet.
- The remote repository also avoids Docker Hub rate limits.
- Debugging requires logs rather than SSH.
  Break-glass access through Identity-Aware Proxy is documented but not implemented.
- For a regional MIG, `max_surge` must be zero or at least the number of zones.

## Alternatives considered

- Debian with `apt install nginx` and Cloud NAT: fragile boot, version drift, and unnecessary egress.
- VMs with public IPs: attack surface with no benefit, since the load balancer is the only entry point.
- Custom image built with Packer: most immutable, but adds an image build pipeline that a static site does not need.
