// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Keep OTP';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get fieldRequired => 'Required';

  @override
  String get noAccountsTitle => 'No accounts yet';

  @override
  String get noAccountsBody =>
      'Add an account by scanning the QR code a service shows when you turn on two-step verification. Everything stays on this device.';

  @override
  String get addAccount => 'Add account';

  @override
  String get nextCode => 'Next code';

  @override
  String codeCopied(int seconds) {
    return 'Code copied. Clipboard clears in $seconds s.';
  }

  @override
  String get removeAccountTitle => 'Remove account?';

  @override
  String removeAccountBody(String name) {
    return 'Remove $name?\n\nYou will not be able to sign in with this app until you set it up again on the service. Disable two-step verification there first if unsure.';
  }

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuExportEncrypted => 'Export encrypted backup';

  @override
  String get menuImportBackup => 'Import backup';

  @override
  String get menuExportPlain => 'Export as otpauth links (unencrypted)';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get scanInvalidQr => 'This QR code is not a valid OTP code.';

  @override
  String get pasteLinkTitle => 'Paste an otpauth:// link';

  @override
  String get addFromLink => 'Add from link';

  @override
  String get invalidLink => 'This is not a valid otpauth:// link.';

  @override
  String scanMigrationProgress(int scanned, int total) {
    return 'Scanned $scanned of $total QR codes. Show the next one.';
  }

  @override
  String get migrationNeedsScan =>
      'This export is split over several QR codes. Use Scan QR code so all of them can be read.';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get serviceLabel => 'Service (e.g. GitHub)';

  @override
  String get accountLabel => 'Account (e.g. you@example.com)';

  @override
  String get secretLabel => 'Secret key (Base32)';

  @override
  String get invalidBase32 => 'Not a valid Base32 key';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get noScreenLockTitle => 'No screen lock on this device';

  @override
  String get noScreenLockBody =>
      'Your codes are not protected. Set a PIN, pattern, password or biometrics in your device settings, then come back here.';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockSubtitle =>
      'Require biometrics or your device PIN to open the app';

  @override
  String get lockAfterTitle => 'Lock the app';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockAfterSeconds(int count) {
    return 'After $count seconds';
  }

  @override
  String lockAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count minutes',
      one: 'After 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get lockNeedsScreenLock =>
      'Set up a screen lock or biometrics in your device settings first.';

  @override
  String get lockNotTurnedOff => 'App lock was not turned off.';

  @override
  String get lockedTitle => 'Keep OTP is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get working => 'Working…';

  @override
  String get nothingToBackUp => 'Nothing to back up yet.';

  @override
  String get backupFailed => 'Backup failed.';

  @override
  String get saveBackupDialogTitle => 'Save encrypted backup';

  @override
  String get backupCancelled => 'Backup cancelled.';

  @override
  String get backupSaved => 'Encrypted backup saved.';

  @override
  String get invalidBackupFile => 'This is not a valid backup file.';

  @override
  String importedAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count new accounts.',
      one: 'Imported 1 new account.',
      zero: 'No new accounts were imported.',
    );
    return '$_temp0';
  }

  @override
  String get wrongPasswordOrModified =>
      'Wrong password, or the file was modified.';

  @override
  String get nothingToExport => 'Nothing to export yet.';

  @override
  String get exportPlainTitle => 'Export without encryption?';

  @override
  String get exportPlainBody =>
      'The file will contain your secret keys in plain text. Anyone who gets it can generate your codes. Delete it as soon as you have imported it elsewhere.';

  @override
  String get exportAnyway => 'Export anyway';

  @override
  String get savePlainDialogTitle => 'Save plain-text export';

  @override
  String get exportCancelled => 'Export cancelled.';

  @override
  String get exported => 'Exported.';

  @override
  String get setBackupPassword => 'Set backup password';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get forgetPasswordWarning =>
      'If you forget this password, the backup cannot be recovered.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String passwordTooShort(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get enterPassword => 'Enter the password.';
}
