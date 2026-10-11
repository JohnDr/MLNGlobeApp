---
type: Verification
title: Android
description: Verified Android build, sign, install and launch on the Galaxy S23.
tags: [ verification, android ]
status: draft
---
## What was verified

| Check | Result |
|-------|--------|
| Library for Android arm64-v8a | `libQMapLibre_arm64-v8a.so` + QML plugin built and installed. |
| App APK (arm64-v8a) | `MapLibreEarth.apk` (~80 MB), package `org.qtproject.example.MapLibreEarth`. |
| Sign + install | `zipalign` + `apksigner` (debug keystore) → `adb install` **Success**. |
| Launch | `monkey … LAUNCHER 1` → pid live, map + UI render. |
| Style warnings | **0** `ParseStyle`, 0 *data expressions*, 0 *doesn't support property* on the device. |
| WebP plugin | Bundled via `QT_ANDROID_EXTRA_LIBS` (path fixed with `file(TO_CMAKE_PATH)`). |

## Device

Galaxy S23, `adb` serial `RFCW910087W`.

## Related

- [Android build](../runbooks/build-android.md) · [Deploy](../runbooks/deploy-android.md)
