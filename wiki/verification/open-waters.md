---
type: Verification
title: Open Waters
description: Verified rendering of the Open Waters style with the downstream patch applied.
tags: [ verification, open-waters ]
status: draft
---
## What was verified

With the [style-spec patch](../references/fork-patches.md) applied (and the [assert relaxation](../references/fork-patches.md) for Debug):

| Check | Before patch | After patch |
|-------|--------------|-------------|
| Symbol layers dropped | ~16 (`buoys`, `beacons`, `lights`, `topmarks`, …) | 0 |
| `doesn't support property` warnings | 16 | 0 |
| `data expressions not supported` warnings | 2 | 0 |
| Icons rendered | none (text only) | buoys, marks, lights, landmarks |
| Remaining log line | — | `[General]: Invalid geometry in line layer` (data issue, harmless) |

Windows and Android arm64-v8a both show the full feature set.

## Related

- [Open Waters rendering flow](../flows/open-waters-rendering.md) · [Open Waters runbook](../runbooks/open-waters.md) · [Style-spec properties](../concepts/style-spec-properties.md)
