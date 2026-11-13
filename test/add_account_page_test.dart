import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/l10n/app_localizations.dart';
import 'package:keep_otp/otp/otp_account.dart';
import 'package:keep_otp/ui/add_account_page.dart';

// Google Authenticator exports with two accounts, in one QR code and as part 1 of 2.
const _singlePart = 'otpauth-migration://offline?data='
    'CjkKFDEyMzQ1Njc4OTAxMjM0NTY3ODkwEhVBY21lOmRhbmFAZXhhbXBsZS5jb20aBEFjbWUgASgBMAIKIQoKYWJjZGVmZ2hpahIIWmVkOmVyaW4aA1plZCACKAIwAhABGAEgACgH';
const _multiPart = 'otpauth-migration://offline?data='
    'CjkKFDEyMzQ1Njc4OTAxMjM0NTY3ODkwEhVBY21lOmRhbmFAZXhhbXBsZS5jb20aBEFjbWUgASgBMAIKIQoKYWJjZGVmZ2hpahIIWmVkOmVyaW4aA1plZCACKAIwAhABGAIgACgH';

Future<List<OtpAccount>?> _paste(WidgetTester tester, String text) async {
  List<OtpAccount>? result;
  var popped = false;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<List<OtpAccount>>(
                MaterialPageRoute(builder: (_) => const AddAccountPage()),
              );
              popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, text);
  await tester.tap(find.text('Add from link'));
  await tester.pumpAndSettle();
  return popped ? result : null;
}

void main() {
  testWidgets('a pasted otpauth link returns one account', (tester) async {
    final result = await _paste(
        tester, 'otpauth://totp/GitHub:alice?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=GitHub');
    expect(result, hasLength(1));
    expect(result!.single.issuer, 'GitHub');
  });

  testWidgets('a pasted Google Authenticator export returns all its accounts', (tester) async {
    final result = await _paste(tester, _singlePart);
    expect([for (final a in result!) a.accountName], ['dana@example.com', 'erin']);
  });

  testWidgets('a multi-part export asks the user to scan instead', (tester) async {
    final result = await _paste(tester, _multiPart);
    expect(result, isNull); // the page stays open
    expect(find.textContaining('split over several QR codes'), findsOneWidget);
  });

  testWidgets('an invalid link shows the error', (tester) async {
    final result = await _paste(tester, 'not a link');
    expect(result, isNull);
    expect(find.text('This is not a valid otpauth:// link.'), findsOneWidget);
  });
}
