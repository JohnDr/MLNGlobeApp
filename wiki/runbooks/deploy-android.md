---
type: Runbook
title: Deploy (Android)
description: Sign and install the unsigned MLNGlobeApp APK on the Galaxy S23.
tags: [ runbook, android, deploy ]
status: draft
---
## Summary

The release APK produced by the [Android build](./build-android.md) is **unsigned**. Sign it with the debug keystore, then install and launch.

## Sign

```powershell
$bt = "C:\Users\JohnD\AppData\Local\Android\Sdk\build-tools\36.0.0"
& "$bt\zipalign.exe" -p -f 4 `
    "C:\hda\dev\tmp\build-maplibreearth-android\android-build\MLNGlobeApp.apk" aligned.apk
& "$bt\apksigner.bat" sign --ks "$env:USERPROFILE\.android\debug.keystore" `
    --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android `
    --out MLNGlobeApp-signed.apk aligned.apk
```

## Install + launch

```powershell
$adb = "C:\Users\JohnD\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb -s RFCW910087W install -r MLNGlobeApp-signed.apk
& $adb -s RFCW910087W shell monkey -p org.qtproject.example.MLNGlobeApp `
    -c android.intent.category.LAUNCHER 1
```

## Notes

- Package name: `org.qtproject.example.MLNGlobeApp`.
- Verify per the [Android verification](../verification/android.md) checklist (app stays up; 0 `ParseStyle` warnings in `logcat`).

## Related

- [Android build](./build-android.md) · [Verification](../verification/android.md) · [Environment](../architecture/environment.md)
