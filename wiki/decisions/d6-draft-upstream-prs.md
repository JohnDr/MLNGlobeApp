---
type: ADR
title: D6 — Hold upstream PRs as drafts
description: The upstream PRs were opened and then marked draft; no further upstreaming until the project stabilises.
tags: [ adr, process ]
status: accepted
---
## Status

Accepted (2026-10-11).

## Context

Five PRs were opened early — MapLibre Native Qt **#323–#326** and MapLibre Native **#4752**. Work continued afterwards (the [MLNGlobeApp split](./d1-standalone-app.md), Debug support, the assert-relaxation patch). That post-PR work is local/fork-only and does not change the PR contents.

## Decision

- Mark the five PRs as **Draft**.
- **Hold** any new upstream PRs until the project stabilises.

## Consequences

- No premature review; the PR branches can still receive commits if a change is genuinely in scope.
- Resume by taking them out of Draft when ready, and rebase #324–#326 after #323.

## Related

- [Upstream PRs](../references/upstream-prs.md) · [Next steps](../next-steps.md)
