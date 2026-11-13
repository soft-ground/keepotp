import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/data/account_store.dart';
import 'package:keep_otp/lock/lock_controller.dart';
import 'package:keep_otp/main.dart';
import 'package:keep_otp/otp/otp_account.dart';
import 'package:keep_otp/state/accounts_controller.dart';

import 'fakes.dart';

const _secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

OtpAccount _acct(String issuer, String name) =>
    OtpAccount.fromUri('otpauth://totp/$issuer:$name?secret=$_secret&issuer=$issuer');

List<String> _issuers(AccountsController c) => [for (final a in c.accounts) a.issuer];

Future<AccountsController> _controller(List<OtpAccount> accounts, {AccountStore? store}) async {
  final s = store ?? MemoryAccountStore();
  await s.save(accounts);
  final c = AccountsController(s);
  await c.load();
  return c;
}

Future<void> _pump(WidgetTester tester, AccountsController c) async {
  final lock = LockController(
      MemoryLockSettingsStore(const LockSettings(enabled: false)), FakeAuthenticator());
  await lock.load();
  await tester.pumpWidget(KeepOtpApp(controller: c, lock: lock, clock: () => 59));
  await tester.pump();
}

void main() {
  group('AccountsController', () {
    test('rename changes the labels only, and persists', () async {
      final store = MemoryAccountStore();
      final c = await _controller([_acct('A', 'x'), _acct('B', 'y')], store: store);
      final before = c.accounts.last;
      await c.rename(before, issuer: '  Bee ', accountName: ' why  ');

      expect(_issuers(c), ['A', 'Bee']);
      final renamed = c.accounts.last;
      expect(renamed.accountName, 'why');
      expect(renamed.secret, before.secret);
      expect(renamed.code(59), before.code(59));
      final saved = await store.load();
      expect([for (final a in saved) a.issuer], ['A', 'Bee']);
    });

    test('rename ignores an account that is not in the list', () async {
      final c = await _controller([_acct('A', 'x')]);
      await c.rename(_acct('Z', 'z'), issuer: 'Q', accountName: 'q');
      expect(_issuers(c), ['A']);
    });

    test('move puts the account at its final position and persists', () async {
      final store = MemoryAccountStore();
      final c = await _controller(
          [_acct('A', 'a'), _acct('B', 'b'), _acct('C', 'c'), _acct('D', 'd')],
          store: store);
      await c.move(0, 2);
      expect(_issuers(c), ['B', 'C', 'A', 'D']);
      await c.move(3, 0);
      expect(_issuers(c), ['D', 'B', 'C', 'A']);
      expect([for (final a in await store.load()) a.issuer], ['D', 'B', 'C', 'A']);
    });

    test('move ignores invalid or unchanged positions', () async {
      final c = await _controller([_acct('A', 'a'), _acct('B', 'b')]);
      await c.move(0, 0);
      await c.move(-1, 1);
      await c.move(0, 2);
      await c.move(5, 0);
      expect(_issuers(c), ['A', 'B']);
    });
  });

  group('search', () {
    final names = ['Amazon', 'Bitbucket', 'Cloudflare', 'Dropbox', 'GitHub', 'Google'];
    Future<AccountsController> six() => _controller([for (final n in names) _acct(n, '$n-user')]);

    testWidgets('is not offered for a short list', (tester) async {
      await _pump(tester, await _controller([_acct('A', 'a'), _acct('B', 'b')]));
      expect(find.byIcon(Icons.search), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('filters by service or account, ignoring case', (tester) async {
      await _pump(tester, await six());
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'GO');
      await tester.pump();
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Amazon'), findsNothing);

      await tester.enterText(find.byType(TextField), 'dropbox-user'); // account name
      await tester.pump();
      expect(find.text('Dropbox'), findsOneWidget);
      expect(find.text('Google'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No matching accounts'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('Amazon'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('edit', () {
    testWidgets('renames an account from its menu', (tester) async {
      final c = await _controller([_acct('Old', 'me@example.com')]);
      await _pump(tester, c);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit account'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Service (e.g. GitHub)'), 'New');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Old'), findsNothing);
      expect(c.accounts.single.accountName, 'me@example.com');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does not save an empty account name', (tester) async {
      final c = await _controller([_acct('Old', 'me')]);
      await _pump(tester, c);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Account (e.g. you@example.com)'), ' ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Edit account'), findsOneWidget); // dialog is still open
      expect(c.accounts.single.accountName, 'me');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('reorder', () {
    testWidgets('long-press and drag moves an account', (tester) async {
      final c = await _controller([_acct('A', 'a'), _acct('B', 'b'), _acct('C', 'c')]);
      await _pump(tester, c);

      final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
      await tester.pump(const Duration(milliseconds: 600)); // past the long-press delay
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 160)); // far enough to pass the last row
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_issuers(c), ['B', 'C', 'A']);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
