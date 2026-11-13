# App Store listing

Copy these into App Store Connect. iOS builds need macOS and Xcode; this
project has not been built or run on iOS yet, so treat everything below as a
draft until it has been verified on a device.

## App information

| Field | Value |
|---|---|
| Name (30) | `Keep OTP` |
| Subtitle (30) | `Private 2FA authenticator` |
| Category | Utilities (secondary: Productivity) |
| Keywords (100) | `otp,2fa,authenticator,totp,hotp,two factor,mfa,security,backup,offline,open source,privacy` |
| Support URL | https://github.com/soft-ground/keep-otp/issues |
| Marketing URL | https://soft-ground.com |
| Privacy policy URL | https://github.com/soft-ground/keep-otp/blob/main/PRIVACY.md |
| Copyright | 2026 soft-ground |
| Age rating | 4+ |

### Promotional text (170)

```text
Free and open source. No account, no ads, no tracking. Your codes stay on your device, with an encrypted backup file you control.
```

### Description (4000)

Use the Play Store full description from [google-play.md](google-play.md) and
replace the sentence about the INTERNET permission with:

```text
The app contains no code that connects to a server and collects nothing about you.
```

(iOS has no per-app network permission to point at, so do not repeat the
Android claim.) Replace "Android blocks every network connection" accordingly,
and replace "Screenshots and the recent-apps preview are blocked" with
"The app switcher preview is hidden", which is what the iOS lock cover does.

## App privacy ("nutrition label")

Select **Data Not Collected**. The app collects no data linked to you, used to
track you, or otherwise. Camera access is used only on the device to read QR
codes. Face ID is used only through the system prompt; the app never receives
biometric data.

## Review information

- Sign-in: none required.
- Notes for the reviewer:

```text
Keep OTP is an authenticator app. It needs no account. To try it, tap
"Add account" and paste this test link under "Paste an otpauth:// link":

otpauth://totp/Demo:reviewer@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Demo

A six-digit code appears and refreshes every 30 seconds. The camera is only
used to scan QR codes. The app has no network access and collects no data.
```

## Export compliance

The app uses standard encryption (AES-256-GCM, Argon2id) to protect the backup
file the user creates, which is more than the operating system's own
encryption. Apple asks whether the app uses encryption and whether it is
exempt. Answer the questionnaire yourself after reading Apple's and the US
Bureau of Industry and Security's current guidance, or ask a professional. Do
not set `ITSAppUsesNonExemptEncryption` in `Info.plist` until you have decided.

## Screenshots

Apple requires screenshots for at least one iPhone size (currently 6.9-inch or
6.5-inch, 1290 x 2796 or 1284 x 2778 pixels). Capture them from an iOS
simulator on a Mac with the same fictional accounts as the Android set, after
the app has been verified on iOS.

## Before submitting

- Verify the app on a real iPhone: camera scan, Face ID lock, backup export and
  import, the app switcher cover.
- Set the bundle identifier `com.softground.keepotp` in your Apple Developer
  account and create the signing certificates.
- Provide the app icon: `assets/icon/icon.png` (1024 x 1024, no transparency).
