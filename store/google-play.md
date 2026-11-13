# Google Play listing

Copy these into Play Console. Limits are noted next to each field. Check every
claim against the current build before each release.

## Store listing

| Field | Value |
|---|---|
| App name (30) | `Keep OTP: 2FA Authenticator` |
| Short description (80) | `Free, open-source authenticator. Encrypted backup, no tracking, works offline.` |
| Category | Tools |
| Tags | Authenticator, Security, Productivity |
| Contact email | admin@soft-ground.com |
| Website | https://soft-ground.com |
| Privacy policy URL | https://github.com/soft-ground/keep-otp/blob/main/PRIVACY.md (valid once the repository is public) |

### Full description (4000)

```text
Keep OTP creates the six-digit codes that protect your accounts when you turn on two-step verification. It is free, open source, and works without an internet connection, because the app has no network access at all.

YOUR CODES STAY ON YOUR DEVICE
• No account, no sign-up, no server.
• No ads, no analytics, no tracking, no crash reporting.
• The app does not request the INTERNET permission, so Android blocks every network connection.
• Secret keys are kept in the system's secure storage.

A BACKUP YOU CONTROL
• Export all accounts to one password-protected file (Argon2id key derivation, AES-256-GCM encryption).
• Save it wherever you like and import it on a new phone.
• No cloud copy exists, so only you can restore it. If you forget the backup password, it cannot be recovered.

MOVE IN, MOVE OUT
• Scan the "Transfer accounts" QR codes from Google Authenticator. Exports split over several QR codes are collected for you.
• Add accounts by scanning a QR code, pasting an otpauth:// link, or typing the key.
• Export standard otpauth:// links at any time (with a warning, because they are not encrypted). You are never locked in.

BUILT FOR EVERYDAY USE
• Time-based (TOTP) and counter-based (HOTP) codes, with SHA-1, SHA-256 and SHA-512 and 6 to 8 digits.
• Tap a code to copy it. The clipboard is cleared after 30 seconds.
• Rename accounts, drag them into your preferred order, and search when the list grows.
• Lock the app with your fingerprint, face, or device PIN. Choose how soon it locks again.
• Screenshots and the recent-apps preview are blocked.

OPEN AND HONEST
The source code is public, so anyone can check what the app does. The documentation states the limits as well as the strengths. The app has not been independently audited yet, so keep a backup and do not rely on it as the only way into an important account.

Source code and security policy: https://github.com/soft-ground/keep-otp
```

## Graphics

| Asset | Requirement | File |
|---|---|---|
| App icon | 512 x 512 PNG | `store/assets/play-icon-512.png` |
| Feature graphic | 1024 x 500 PNG or JPEG, no transparency | `store/assets/feature-graphic.png` |
| Phone screenshots | 2 to 8, PNG or JPEG, long side at most 2x the short side | `store/assets/screenshots/` |

### Screenshot set

All captured at 1080 x 2160 (2:1) from a debug build, because release builds
block screenshots. They show fictional services only.

| File | Caption |
|---|---|
| `01-codes.png` | Your codes, always at hand |
| `02-search.png` | Find any account fast |
| `03-add-account.png` | Scan, paste, or type. Import from Google Authenticator |
| `04-encrypted-backup.png` | Encrypted backup that only you can open |

See [README.md](README.md) for how to recreate them.

## App content declarations

| Question | Answer |
|---|---|
| Contains ads | No |
| App access | All functionality is available without a login or special access |
| Target audience | 18 and over (not designed for children) |
| News app / government app / health app / financial features | No |
| Content rating questionnaire | No violence, sexual content, language, controlled substances, gambling, or user-generated content: expect "Everyone" |

### Data safety

| Question | Answer |
|---|---|
| Does the app collect or share any of the required user data types? | **No** |
| Is data encrypted in transit? | Not asked once nothing is collected. The app sends no data anywhere. |
| Can users request data deletion? | Not asked once nothing is collected. All data is local and removed by uninstalling. |

Why "No" is accurate: OTP secrets, account names and settings never leave the
device (no network permission, auto-backup disabled), and the camera image is
processed on the device by the QR scanner and never stored or sent. Re-check
this answer if a dependency or feature ever adds network access.

### Permissions to be ready to explain

| Permission | Purpose |
|---|---|
| `CAMERA` | Scan the QR code a service shows when two-step verification is enabled. Images stay on the device. |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Unlock the app with biometrics or the device credential. The OS performs the check. |

## First release notes

```text
First public release.
• TOTP and HOTP codes
• QR scan, otpauth:// link, or manual entry
• Import from Google Authenticator
• Encrypted backup file
• App lock with biometrics or device PIN
• No network access, no ads, no tracking
```

## Before submitting

- Build the signed `.aab` as described in [RELEASING.md](../RELEASING.md).
- Verify the release manifest has no `INTERNET` permission.
- Enroll in Play App Signing and keep the upload key backed up.
- Run the internal testing track on a real device first.
