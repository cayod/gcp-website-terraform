# 0004. Remote state in one bucket per project

- Status: Accepted
- Date: 2026-09-28

## Context

Terraform state must not live on a local disk.
State contains resource details and must be isolated between environments.
The state bucket must exist before any configuration can use it, which is a bootstrap problem.

## Decision

Each environment project owns its own Cloud Storage state bucket, created by the foundation layer.
The bucket has object versioning, soft delete, uniform bucket-level access, and public access prevention enforced.
State paths use one prefix per root module: `foundation`, `stacks/gcs`, and `stacks/mig`.

Bootstrap sequence:

1. Apply `foundation/` with local state.
2. Run `terraform init -migrate-state` to move the foundation state into the bucket it created.
3. Delete the local state file.

Teardown sequence, the mirror of the bootstrap (`make teardown`):

1. Refuse to run while any stack of the environment still has resources.
2. Move the foundation state back to a local backend.
3. Allow the state bucket to be deleted with its content, through a variable that only the teardown sets.
4. Destroy the foundation and delete the local state file.

The state bucket is never deletable with its content outside a teardown, so a mistaken destroy cannot erase the state.

## Consequences

- Credentials for `dev` cannot read or corrupt the `prod` state.
- Versioning and soft delete allow recovery from a corrupted or deleted state.
- The GCS backend provides native state locking.
- The one-time local state step is documented in the README.

## Alternatives considered

- A central admin project holding all state: common in organizations, but it adds a third project and a shared blast radius for a two-environment setup.
- Terraform Cloud or another remote backend: adds an external dependency and account for no benefit here.
