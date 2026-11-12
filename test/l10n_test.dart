import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/l10n/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  test('plural messages', () {
    expect(l.importedAccounts(0), 'No new accounts were imported.');
    expect(l.importedAccounts(1), 'Imported 1 new account.');
    expect(l.importedAccounts(3), 'Imported 3 new accounts.');
    expect(l.lockAfterMinutes(1), 'After 1 minute');
    expect(l.lockAfterMinutes(5), 'After 5 minutes');
  });

  test('placeholders', () {
    expect(l.passwordTooShort(8), 'Use at least 8 characters.');
    expect(l.codeCopied(30), 'Code copied. Clipboard clears in 30 s.');
    expect(l.removeAccountBody('GitHub (alice)'), startsWith('Remove GitHub (alice)?'));
  });
}
