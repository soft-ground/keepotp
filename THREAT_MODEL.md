# Threat model

This document says what Keep OTP protects, against whom, and — just as
important — what it does **not** protect. It describes the code in this
repository; if the code and this file disagree, that is a bug in one of them.

Status: pre-1.0. Not independently audited.

## What the app does

Keep OTP generates time-based (TOTP, RFC 6238) and counter-based (HOTP,
RFC 4226) one-time codes on your device. It has no server, no account, and no
network access (see [Network](#network)). Secrets never leave the device unless
you export them.

## Assets

| Asset | Why it matters |
|---|---|
| OTP secret keys | Anyone holding a secret can generate valid codes for that account, forever, until it is re-provisioned. |
| Backup files | Contain all secrets (encrypted, unless you choose the plain-text export). |
| Backup password | Only protection of an encrypted backup. |

## Trust assumptions

- The OS (Android / iOS), its secure storage, and its lock-screen credential
  prompt behave correctly.
- Cryptographic primitives come from audited libraries (`crypto`,
  `cryptography`); this project implements no cipher or hash of its own. The
  HOTP/TOTP construction is ~50 lines on top of HMAC and is checked against the
  official RFC 4226 / RFC 6238 test vectors in CI.
- The device clock is roughly correct (TOTP depends on it).

## Protections and their limits

### Secrets at rest

- Stored in the OS secure storage (`flutter_secure_storage`: Android
  Keystore-protected encryption, iOS Keychain).
- Android: `allowBackup="false"`, so secrets are not copied into Google
  auto-backup or device-to-device transfer.

**Limit:** the storage key is **not bound to your biometrics/PIN**. The app
lock (below) is enforced by the app, not by the keystore. A rooted/jailbroken
device, malware with root, or someone who can extract and attack the device's
storage offline is **out of scope**.

### App lock

- Locked on launch and after the app has been in the background for the
  configured time (default: immediately).
- Uses the OS prompt (biometrics, or device PIN/pattern/passcode as fallback).
- While locked, the account screen is not built at all; while the app is not in
  the foreground it is covered by a blank screen (hides the iOS app-switcher
  snapshot).
- Turning the lock off requires authenticating first.

**Limits:**
- If the device has **no screen lock**, the app cannot lock and opens freely.
  Settings shows a warning. This is deliberate: refusing to open would lock
  users out of their own codes.
- The lock is a UI gate. It does not encrypt anything with your credential.
- No app-level retry limit; lockout after failed attempts is left to the OS.
- If you leave the app during a file-picker or camera-permission flow, it does
  not re-lock until that flow finishes.

### Screen capture and clipboard

- Android release builds set `FLAG_SECURE`: no screenshots, no screen
  recording, blank recent-apps thumbnail. Debug builds do not (so the UI can be
  inspected during development).
- **iOS cannot block screenshots.** Only the app-switcher cover applies.
- Tapping a code copies it and clears the clipboard after 30 s, only if the
  clipboard still holds that code.

**Limit:** during those 30 s, any app that can read the clipboard can read the
code. Android 10+ restricts background clipboard reads; older versions do not.

### Encrypted backup

Format (`keep-otp-backup`, version 1), JSON:

```
kdf:        Argon2id, 19 MiB memory, 2 iterations, 1 lane, 16-byte random salt
cipher:     AES-256-GCM, 12-byte random nonce, 16-byte tag
plaintext:  {"accounts": ["otpauth://...", ...]}
AAD:        format | version | KDF name and parameters | salt | cipher | nonce
```

- Header fields are authenticated as GCM associated data: changing the KDF
  parameters, salt or nonce makes decryption fail (no parameter downgrade).
- On import, KDF parameters are range-checked (memory ≤ 256 MiB, ≤ 10
  iterations, ≤ 8 lanes) so a crafted file cannot exhaust memory.
- A wrong password and a tampered file are indistinguishable by design.
- Minimum password length is 8 characters.

**Limits:**
- An attacker who obtains the file can guess passwords **offline, without
  rate limiting**. Argon2id makes each guess costly, but a short or common
  password will fall. Use a long passphrase.
- There is no recovery. Forget the password and the backup is gone.
- The defaults are the OWASP minimum. They have not been tuned on low-end
  devices.

### Plain-text export

The menu offers an unencrypted `otpauth://` export, so you are never locked in.
The file contains every secret in clear text. The app warns before exporting;
after that it is your responsibility to protect and delete the file.

### Network

The app makes no network requests and the **release build declares no
`INTERNET` permission** (stripped in `android/app/src/main/AndroidManifest.xml`,
verified in the merged release manifest). The QR scanner pulls in Google ML Kit,
whose telemetry transport would otherwise request network access; without the
permission the OS blocks it. There are no analytics, ads, crash reporters, or
remote config.

**Limit:** the QR scanner depends on Google's ML Kit barcode library, which is
closed-source. Android only.

## Threats we do not address

| Threat | Why |
|---|---|
| Real-time phishing relay (attacker proxies your login and your typed code) | Inherent to TOTP: a code is not bound to the site it is typed into. Use passkeys / WebAuthn where available. |
| Compromised service server leaking shared secrets | Server-side; TOTP is a shared-secret scheme. |
| Malware on an unlocked, rooted, or jailbroken device | Out of scope; secrets can be read from memory or storage. |
| Shoulder surfing of a displayed code | Codes are shown in clear by design. |
| Device clock manipulation | Codes will be wrong; the app does not check time against a trusted source (it cannot, it is offline). |
| SIM-swap / account-recovery abuse at the service | Server-side. |
| Supply-chain compromise of dependencies | Mitigated only by a small dependency list and pinned `pubspec.lock`; no formal review. |

## Open items

- iOS has not been built or tested (requires macOS); iOS statements above are
  design intent, not verified behaviour.
- Camera QR scanning and the file-based backup flows have been unit-tested at
  the codec level but not yet exercised end to end on a device.
- No external security review yet.
- Passkey/WebAuthn support is not implemented.
