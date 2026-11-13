# Store materials

Listing text and declarations for the app stores, plus the graphics they need.

| File | Purpose |
|---|---|
| [google-play.md](google-play.md) | Play Console listing, content declarations, data safety answers |
| [app-store.md](app-store.md) | App Store Connect listing and privacy label (draft until verified on iOS) |
| `assets/play-icon-512.png` | Play Store icon |
| `assets/feature-graphic.png` | Play Store feature graphic (1024 x 500) |
| `assets/screenshots/` | Phone screenshots (1080 x 2160) |

## Regenerating the graphics

The icon and the feature graphic are drawn by `tool/render_icons_test.dart`:

```bash
flutter test tool/render_icons_test.dart
```

## Recreating the screenshots

Release builds block screenshots on purpose, so use a debug build and
fictional accounts only (never real service names or real secrets).

1. Start an emulator and set a 2:1 screen so Play accepts the images:
   `adb shell wm size 1080x2160` (undo with `adb shell wm size reset`).
2. Install a debug build (`flutter build apk --debug`) and add a few accounts
   with fictional services, for example by pasting an
   `otpauth-migration://` link built from sample data.
3. Capture with `adb exec-out screencap -p > file.png`. Take the code screens
   right after a new 30-second period starts so the countdown rings are full.
4. Do not capture the settings screen on an emulator without a screen lock: it
   shows a warning that does not belong in marketing images.
