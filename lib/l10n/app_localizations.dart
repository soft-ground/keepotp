import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App name shown in the app bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'Keep OTP'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @noAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsTitle;

  /// No description provided for @noAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'Add an account by scanning the QR code a service shows when you turn on two-step verification. Everything stays on this device.'**
  String get noAccountsBody;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @nextCode.
  ///
  /// In en, this message translates to:
  /// **'Next code'**
  String get nextCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied. Clipboard clears in {seconds} s.'**
  String codeCopied(int seconds);

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @editAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccountTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search accounts'**
  String get searchHint;

  /// No description provided for @closeSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearchTooltip;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching accounts'**
  String get noSearchResults;

  /// No description provided for @removeAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account?'**
  String get removeAccountTitle;

  /// {name} is the service and account, e.g. "GitHub (alice)".
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?\n\nYou will not be able to sign in with this app until you set it up again on the service. Disable two-step verification there first if unsure.'**
  String removeAccountBody(String name);

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuExportEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Export encrypted backup'**
  String get menuExportEncrypted;

  /// No description provided for @menuImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get menuImportBackup;

  /// No description provided for @menuExportPlain.
  ///
  /// In en, this message translates to:
  /// **'Export as otpauth links (unencrypted)'**
  String get menuExportPlain;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @scanInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid OTP code.'**
  String get scanInvalidQr;

  /// No description provided for @pasteLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste an otpauth:// link'**
  String get pasteLinkTitle;

  /// No description provided for @addFromLink.
  ///
  /// In en, this message translates to:
  /// **'Add from link'**
  String get addFromLink;

  /// No description provided for @invalidLink.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid otpauth:// link.'**
  String get invalidLink;

  /// Shown while importing a multi-part Google Authenticator export.
  ///
  /// In en, this message translates to:
  /// **'Scanned {scanned} of {total} QR codes. Show the next one.'**
  String scanMigrationProgress(int scanned, int total);

  /// No description provided for @migrationNeedsScan.
  ///
  /// In en, this message translates to:
  /// **'This export is split over several QR codes. Use Scan QR code so all of them can be read.'**
  String get migrationNeedsScan;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service (e.g. GitHub)'**
  String get serviceLabel;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account (e.g. you@example.com)'**
  String get accountLabel;

  /// No description provided for @secretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret key (Base32)'**
  String get secretLabel;

  /// No description provided for @invalidBase32.
  ///
  /// In en, this message translates to:
  /// **'Not a valid Base32 key'**
  String get invalidBase32;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @noScreenLockTitle.
  ///
  /// In en, this message translates to:
  /// **'No screen lock on this device'**
  String get noScreenLockTitle;

  /// No description provided for @noScreenLockBody.
  ///
  /// In en, this message translates to:
  /// **'Your codes are not protected. Set a PIN, pattern, password or biometrics in your device settings, then come back here.'**
  String get noScreenLockBody;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or your device PIN to open the app'**
  String get appLockSubtitle;

  /// No description provided for @lockAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the app'**
  String get lockAfterTitle;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'After {count} seconds'**
  String lockAfterSeconds(int count);

  /// No description provided for @lockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{After 1 minute} other{After {count} minutes}}'**
  String lockAfterMinutes(int count);

  /// No description provided for @lockNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock or biometrics in your device settings first.'**
  String get lockNeedsScreenLock;

  /// No description provided for @lockNotTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'App lock was not turned off.'**
  String get lockNotTurnedOff;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep OTP is locked'**
  String get lockedTitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get working;

  /// No description provided for @nothingToBackUp.
  ///
  /// In en, this message translates to:
  /// **'Nothing to back up yet.'**
  String get nothingToBackUp;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed.'**
  String get backupFailed;

  /// No description provided for @saveBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save encrypted backup'**
  String get saveBackupDialogTitle;

  /// No description provided for @backupCancelled.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled.'**
  String get backupCancelled;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup saved.'**
  String get backupSaved;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid backup file.'**
  String get invalidBackupFile;

  /// No description provided for @importedAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new accounts were imported.} =1{Imported 1 new account.} other{Imported {count} new accounts.}}'**
  String importedAccounts(int count);

  /// No description provided for @wrongPasswordOrModified.
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or the file was modified.'**
  String get wrongPasswordOrModified;

  /// No description provided for @nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get nothingToExport;

  /// No description provided for @exportPlainTitle.
  ///
  /// In en, this message translates to:
  /// **'Export without encryption?'**
  String get exportPlainTitle;

  /// No description provided for @exportPlainBody.
  ///
  /// In en, this message translates to:
  /// **'The file will contain your secret keys in plain text. Anyone who gets it can generate your codes. Delete it as soon as you have imported it elsewhere.'**
  String get exportPlainBody;

  /// No description provided for @exportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Export anyway'**
  String get exportAnyway;

  /// No description provided for @savePlainDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save plain-text export'**
  String get savePlainDialogTitle;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get exportCancelled;

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported.'**
  String get exported;

  /// No description provided for @setBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Set backup password'**
  String get setBackupPassword;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// No description provided for @forgetPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'If you forget this password, the backup cannot be recovered.'**
  String get forgetPasswordWarning;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String passwordTooShort(int min);

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the password.'**
  String get enterPassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
