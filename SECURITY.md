# Security policy

Keep OTP holds people's second-factor secrets, so security reports are taken
seriously. Thank you for taking the time to report one.

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Report it privately:

- Use GitHub's **"Report a vulnerability"** (Security → Advisories) on this
  repository, or
- Email **admin@soft-ground.com**.

Please include what you found, how to reproduce it, the app version, and the
platform. If you can, tell us whether you plan to publish and when.

### What to expect

- Acknowledgement within **5 business days**.
- An initial assessment within **14 days**.
- A fix or mitigation plan for confirmed issues, and credit in the release
  notes if you want it. We ask for **90 days** (or until a fix ships, whichever
  is first) before public disclosure, and will coordinate a date with you.

There is no bounty program. This is a free, open-source project.

## Scope

In scope: the code in this repository — OTP generation, secret storage, app
lock, backup/restore format and cryptography, import/export parsing, and
build/manifest configuration.

Out of scope: issues that require a rooted/jailbroken or already-compromised
device; weaknesses inherent to TOTP (e.g. real-time phishing); vulnerabilities
in third-party services you use codes with; vulnerabilities in Flutter, the OS,
or dependencies that are not exploitable through this app (report those
upstream). See [THREAT_MODEL.md](THREAT_MODEL.md) for what is and is not
protected.

## Supported versions

Only the latest release receives security fixes while the project is pre-1.0.

## Verifying our claims

Security claims are written down in [THREAT_MODEL.md](THREAT_MODEL.md) so they
can be checked and challenged. Useful things to verify yourself:

```bash
flutter test            # includes RFC 4226 / RFC 6238 test vectors and backup tamper tests
flutter build apk --release
# then inspect the merged manifest: it must contain no INTERNET permission
```

## TODO before the first public release

- [ ] Make sure admin@soft-ground.com is monitored.
- [ ] Enable GitHub private vulnerability reporting on the repository.
- [ ] Replace the placeholder application ID `dev.example.keep_otp`.
