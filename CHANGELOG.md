# Changelog

All notable changes are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

First public development version.

- TOTP and HOTP codes (SHA-1, SHA-256, SHA-512; 6 to 8 digits).
- Add accounts by QR scan, `otpauth://` link, or manual entry.
- Encrypted backup file (Argon2id and AES-256-GCM) and `otpauth://` export.
- App lock with biometrics or the device PIN.
- Android: no network permission, screenshots blocked in release builds.
- Landscape and tablet layouts: content keeps a readable width, dialogs scroll
  when the keyboard is open, and the last account is never hidden behind the
  add button.
- Rename accounts, reorder them by long-press and drag, and search the list
  (shown from six accounts on).
- Import from Google Authenticator by scanning its "Transfer accounts" QR codes
  or pasting the export link; exports split over several QR codes are collected.
