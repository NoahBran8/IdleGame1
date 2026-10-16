# Android export and device QA

Status: preset included; APK and device QA **not verified**. This cloud image has Godot 4.6.3 and JDK 21, but no Android SDK, adb or Godot export templates were found. Do not mark M4 complete on the strength of desktop checks.

## Build locally
1. Install Godot 4.6.3 export templates using Editor → Manage Export Templates (same version as the engine).
2. Follow the Godot 4.6 Android export setup for a supported JDK and Android SDK: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html . Use that version's required SDK components; do not substitute host Java detection for verified compatibility.
3. Set Java SDK Path and Android SDK Path in Editor Settings → Export → Android.
4. Open Project → Export → Android. The checked-in preset is ARM64 portrait, package com.example.gardenempire, internet permission disabled, haptics permission enabled. Change the provisional package identifier before distribution. Godot generates a debug keystore outside the repository.
5. From the project directory:
   ```sh
   mkdir -p build
   godot --headless --path . --export-debug Android build/garden-empire-debug.apk
   adb install -r build/garden-empire-debug.apk
   ```
6. Launch Garden Empire on the attached device. Keep release signing keys outside the repo. Release signing and store publication require a separate reviewed release process.

## Device acceptance checklist (pending)
- Fresh install at 320–600 logical px: seed affordances visible, controls legible, plot hit regions usable at least 44dp; test actual Android touch, not mouse emulation alone.
- Safe-area insets around notches, gesture bar and cutouts; portrait relaunch and background/foreground.
- Plant → three stages → harvest → sell; repeat rapid taps; no duplicate debit/credit.
- Restart mid-growth and after harvesting; background several times; offline eight-hour cap and zero duplicate payout.
- Corrupt primary with a valid backup in a development install; visible recovery. Preserve both corrupt files if recovery fails.
- Switch audio mute, reduced motion, large text, high contrast and local telemetry; restart and verify.
- Stand sells stock only. Helper harvests but never plants. Full wallet preserves unsold goods.
- Profile at least 10 minutes on a representative midrange Android: >=30fps, stable memory, no crash, reasonable battery/thermal behavior. Capture model, OS, engine, frame-time and memory evidence.
- No required network access, account, ad or payment. Check Android manifest before distribution.
- Verify release export omits docs/tests and cannot activate developer tools even with --debug-garden.

## Unverified
No signed APK, emulator run, physical-device performance, Play Store readiness or user research is claimed.
