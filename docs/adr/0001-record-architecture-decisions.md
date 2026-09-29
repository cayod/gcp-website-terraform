# 0001. Record architecture decisions

- Status: Accepted
- Date: 2026-09-28

## Context

This project must explain the reasons behind its architecture, not only the result.
Decisions made during design are easily lost once the code exists.

## Decision

We record every significant architectural decision as an Architecture Decision Record in `docs/adr/`.
Each record is numbered, immutable once accepted, and superseded by a new record when a decision changes.

## Consequences

- Reviewers can follow the reasoning behind each choice without reading the code.
- The README stays short and links to the ADRs for detail.
- Changing a decision requires a new record, which keeps the history of reasoning intact.
