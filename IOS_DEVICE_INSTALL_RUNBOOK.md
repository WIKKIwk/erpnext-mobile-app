# iPhone Fresh Install Runbook

This file documents the exact working path for installing the app onto a
physical iPhone from this Mac.

Use this instead of guessing.

## Goal

Fresh-install the app to a connected iPhone so it opens like a normal app from
the home screen.

Important:

- do not use an unsigned build
- do not rely on a debug build if you want home-screen launch
- use a signed `profile` build for this flow

## Current Project Facts

- iPhone bundle id: `com.example.erpnextStockMobile`
- development team: `CJHQMW57FJ`
- working signing identity:
  - `Apple Development: qurbonovabdulfattox@icloud.com (337B9K86L2)`

## Why debug install is not enough

On iOS 14+, Flutter debug apps do not behave like normal home-screen apps.

If you install a debug build, tapping the icon can show the standard Flutter
message that debug apps must be launched from Flutter tooling, Xcode, or an
IDE.

If you want a normal app-style install, use `profile` or `release`.

## Fresh Install Steps

### 1. Check connected devices

```bash
cd /Volumes/Samsung990P/local.git/erpnext_stock_telegram/mobile_app
flutter devices
```

Look for the physical iPhone UDID.

Example working device:

- `00008030-000E09812150802E`

## 2. Remove the existing app from the phone

```bash
xcrun devicectl device uninstall app \
  --device 00008030-000E09812150802E \
  com.example.erpnextStockMobile
```

Expected success:

- `App uninstalled.`

## 3. Build a signed profile iPhone app

```bash
flutter build ios --profile
```

Expected artifact:

- `build/ios/iphoneos/Runner.app`

## 4. Verify the native asset framework is correctly signed

This app includes `objective_c.framework`. That framework previously caused
install failures if it stayed ad-hoc signed.

Check it:

```bash
codesign -dv --verbose=4 \
  build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework
```

Expected good sign:

- `Authority=Apple Development: qurbonovabdulfattox@icloud.com (337B9K86L2)`

Bad sign:

- `Signature=adhoc`

If it is ad-hoc signed, the build is not ready for device install.

## 5. Install the built app to the iPhone

```bash
xcrun devicectl device install app \
  --device 00008030-000E09812150802E \
  build/ios/iphoneos/Runner.app
```

Expected success:

```text
App installed:
• bundleID: com.example.erpnextStockMobile
```

## 6. Launch the app from tooling if needed

```bash
xcrun devicectl device process launch \
  --device 00008030-000E09812150802E \
  com.example.erpnextStockMobile \
  --terminate-existing \
  --activate
```

Or just tap the app icon on the iPhone if the profile build is trusted and
installed correctly.

## Trust / Security Notes

If iPhone launch is blocked, check:

1. `Settings`
2. `General`
3. `VPN & Device Management`
4. trust the Apple Development profile if iOS asks for it

Typical launch error:

- `invalid code signature, inadequate entitlements or its profile has not been explicitly trusted`

This is not the same as an install failure.

## Important Install Failure We Already Hit

### Symptom

Install failed with:

- `objective_c.framework/objective_c contains an invalid signature`

### Cause

The native asset framework `objective_c.framework` was not device-signed
correctly in the built app bundle.

### Fix already added to the project

The iOS project now has a build phase that re-signs native asset frameworks
during device builds.

Relevant commit:

- `52939ce` `Re-sign native assets during iOS device builds`

Because of that, the normal `flutter build ios --profile` path should now
produce an installable app bundle.

## Known-Good Repeatable Sequence

If asked to fresh-install again, use this exact sequence:

```bash
cd /Volumes/Samsung990P/local.git/erpnext_stock_telegram/mobile_app

xcrun devicectl device uninstall app \
  --device 00008030-000E09812150802E \
  com.example.erpnextStockMobile

flutter build ios --profile

xcrun devicectl device install app \
  --device 00008030-000E09812150802E \
  build/ios/iphoneos/Runner.app
```

Optional launch:

```bash
xcrun devicectl device process launch \
  --device 00008030-000E09812150802E \
  com.example.erpnextStockMobile \
  --terminate-existing \
  --activate
```

## Do Not Repeat These Mistakes

- Do not try to install unsigned builds to a physical iPhone.
- Do not expect a Flutter debug build to behave like a normal home-screen app.
- Do not ignore the signature on `objective_c.framework`.
- Do not skip uninstall when the request is explicitly for a fresh install.
