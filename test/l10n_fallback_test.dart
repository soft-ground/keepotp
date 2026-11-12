import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/l10n/app_localizations.dart';

Widget _app(Locale? locale, {required void Function(AppLocalizations) onL10n}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context);
        onL10n(l10n);
        return Text(l10n.noAccountsTitle);
      }),
    );

void main() {
  testWidgets('strings are available on the very first frame (no async load)', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), onL10n: (_) {}));
    // No extra pump: a delegate that loaded asynchronously would not be ready yet.
    expect(find.text('No accounts yet'), findsOneWidget);
  });

  testWidgets('an unsupported locale falls back to English', (tester) async {
    for (final locale in const [Locale('fr'), Locale('ko'), Locale('zh', 'TW'), Locale('xx')]) {
      await tester.pumpWidget(_app(locale, onL10n: (_) {}));
      expect(find.text('No accounts yet'), findsOneWidget, reason: '$locale');
    }
  });

  testWidgets('a regional variant of a supported language resolves to it', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(_app(const Locale('en', 'GB'), onL10n: (l) => l10n = l));
    expect(l10n.localeName, 'en');
    expect(find.text('No accounts yet'), findsOneWidget);
  });
}
