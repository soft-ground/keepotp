# Releasing Keep OTP

## Android signing

A release published to the Play Store must be signed with a key only the
maintainer holds. Without `android/key.properties`, the release build falls
back to the debug key. That build is fine for local testing and must never be
published.

### One-time setup

1. Create an upload keystore. Keep it outside the repository and choose
   strong passwords:

   ```bash
   keytool -genkeypair -v -keystore keep-otp-upload.jks -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Create `android/key.properties` (it is git-ignored):

   ```properties
   storeFile=/absolute/path/to/keep-otp-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

3. Back up the keystore and both passwords in at least two private places.
   Enroll in Play App Signing when creating the app so that a lost upload key
   can be reset by Google Play support.

Never commit the keystore or `key.properties`, and never paste them into an
issue or a pull request.

## Release checklist

1. Update `version:` in `pubspec.yaml` (`name+build`, the build number must
   increase for every upload) and add a section to `CHANGELOG.md`.
2. Run the checks:

   ```bash
   flutter analyze lib test tool
   flutter test
   ```

3. Build:

   ```bash
   flutter build appbundle --release   # Play Store upload
   flutter build apk --release         # sideloading / GitHub release
   ```

4. Verify the privacy claims on the APK that will be published (adjust the
   build-tools version):

   ```bash
   aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
   aapt2 dump xmltree --file AndroidManifest.xml build/app/outputs/flutter-apk/app-release.apk
   ```

   There must be no `INTERNET` or `ACCESS_NETWORK_STATE` permission,
   `allowBackup` must be `false`, and the app must not be debuggable.

5. Confirm the signer is the release key, not the debug key:

   ```bash
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
   ```

6. Install the release build on a real device and check: the app starts,
   an account can be added by QR scan, the code matches another authenticator,
   a backup can be exported and imported, and the lock works.
7. Tag the release (`vX.Y.Z`) and attach the signed APK to the GitHub release.

## Application ID

The application ID is `com.softground.keepotp`. It cannot be changed after the
first store release.
