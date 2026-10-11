---
type: ADR
title: D4 — Right-drag zoom
description: Why right-drag smooth zoom needs a right-button PinchHandler and for the MapQuickItem to accept the right mouse button.
tags: [ adr, gestures ]
status: accepted
---
## Status

Accepted (2026-10-11; commit `1177540`).

## Context

The example's right-drag smooth zoom used a `DragHandler`. On Windows it did nothing: a `QQuickItem` accepts only `Qt::LeftButton` by default, so a right-button press was never delivered to the map item or its handlers. A right-button `MouseArea` did receive the press, but then only tracked a single move.

## Decision

- **Library**: the `MapQuickItem` constructor calls `setAcceptedMouseButtons(Qt::LeftButton \| Qt::RightButton)`.
- **Example**: implement right-drag zoom as a **one-point `PinchHandler`** (`acceptedButtons: Qt::RightButton`), mirroring the working pan handler — not a `DragHandler`, which activated but never tracked right-button translation.

## Consequences

- Right-drag smooth zoom works on desktop; left-drag pans; pinch and wheel are unchanged.
- Prepared upstream as PR **#325** (draft).

## Related

- [Gestures](../flows/gestures.md) · [The QML map item](../concepts/qml-map-item.md) · [Upstream PRs](../references/upstream-prs.md)
