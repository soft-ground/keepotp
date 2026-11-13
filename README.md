# Keep OTP

A free, open-source, serverless authenticator app for time-based (TOTP) and
counter-based (HOTP) one-time codes. Built with Flutter for Android and iOS.

> **Status: pre-1.0, not independently audited.** Keep a backup and do not rely
> on it as the only way into an important account yet. See
> [THREAT_MODEL.md](THREAT_MODEL.md) for what it does and does not protect.

## Why another authenticator?

Good open-source authenticators exist. This one is built around a single
promise: **your codes are yours, and you can always take them with you.**

- **Encrypted backup, no server.** Export one password-protected file
  (Argon2id + AES-256-GCM) and import it on a new phone.
- **No lock-in.** Import and export standard `otpauth://` links, including a
  plain-text export (with a warning) so you can leave any time.
- **No tracking.** No account, no analytics, no ads, no crash reporter. The
  release build declares **no network permission**, so the OS blocks all
  network access. See [PRIVACY.md](PRIVACY.md).
- **Honest security.** The threat model lists the limits, not just the
  strengths.

## Features

- TOTP and HOTP (RFC 6238 / RFC 4226), SHA-1 / SHA-256 / SHA-512, 6–8 digits
- Add accounts by QR scan, pasted `otpauth://` link, or manual entry
- App lock with biometrics or the device PIN
- Android: screenshots and the recent-apps preview are blocked (release builds)
- Copied codes are cleared from the clipboard after 30 seconds
- English UI, with strings in ARB files ready for translation

Planned: importing from other authenticator apps, showing the service's
domain to help spot phishing, more languages. Passkeys are a long-term goal.

## Build and run

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel) and the Android SDK. iOS builds need macOS and Xcode.

```bash
flutter pub get
flutter test
flutter run            # on a connected device or emulator
flutter build apk --release
```

The generated localization code is committed under `lib/l10n/`. After editing
an `.arb` file, regenerate it:

```bash
flutter gen-l10n
```

## Project layout

| Path | What it holds |
|---|---|
| `lib/otp/` | HOTP/TOTP, Base32, `otpauth://` parser and serializer |
| `lib/backup/` | Encrypted backup format (Argon2id + AES-256-GCM) |
| `lib/data/`, `lib/state/` | Secure storage and the accounts controller |
| `lib/lock/` | App lock: controller, OS authenticator, lock screen |
| `lib/ui/` | Screens and dialogs |
| `lib/l10n/` | ARB files and generated localizations |
| `test/` | Unit and widget tests, including the official RFC test vectors |

## Security

- Design and limits: [THREAT_MODEL.md](THREAT_MODEL.md)
- Reporting a vulnerability: [SECURITY.md](SECURITY.md)
- Data handling: [PRIVACY.md](PRIVACY.md)

This project implements no cryptographic primitive of its own: HMAC, Argon2id
and AES-GCM come from the `crypto` and `cryptography` packages.

## Translating

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb` (for example
   `app_ko.arb`) and translate the values. Keep the `{placeholders}` and ICU
   plural syntax intact.
2. Run `flutter gen-l10n`, then `flutter test`.

English is the source language; every user-visible string must go through
`AppLocalizations`. Code, comments, documentation and commit messages are
written in English.

## Contributing

Issues and pull requests are welcome. For anything touching cryptography,
storage, or the lock, please describe the security impact in the PR. Report
vulnerabilities privately as described in [SECURITY.md](SECURITY.md), not in
public issues.

Maintainers: see [RELEASING.md](RELEASING.md) for signing and the release
checklist, and [CHANGELOG.md](CHANGELOG.md) for what changed.

## License

Licensed under the [Apache License 2.0](LICENSE). Copyright 2026 soft-ground.

The license covers the source code only. It does not grant rights to use the
"Keep OTP" name or logo for a modified version of the app.
