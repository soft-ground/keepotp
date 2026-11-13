import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/data/account_store.dart';
import 'package:keep_otp/l10n/app_localizations.dart';
import 'package:keep_otp/lock/lock_controller.dart';
import 'package:keep_otp/lock/lock_gate.dart';
import 'package:keep_otp/main.dart';
import 'package:keep_otp/otp/otp_account.dart';
import 'package:keep_otp/state/accounts_controller.dart';
import 'package:keep_otp/ui/add_account_page.dart';
import 'package:keep_otp/ui/backup_actions.dart';
import 'package:keep_otp/ui/settings_page.dart';

import 'fakes.dart';

// A phone held sideways: about 740 x 340 logical pixels, optionally with an
// on-screen keyboard covering part of it. Any RenderFlex overflow fails a test.
const _phoneLandscape = Size(740, 340);
const _keyboardHeight = 170.0;

const _secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

void _setScreen(WidgetTester tester, {Size size = _phoneLandscape, double keyboard = 0, double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (keyboard > 0) tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
}

Future<AccountsController> _accounts(int n) async {
  final store = MemoryAccountStore();
  await store.save([
    for (var i = 0; i < n; i++)
      OtpAccount.fromUri('otpauth://totp/Service$i:person$i@example.com?secret=$_secret&issuer=Service$i'),
  ]);
  final c = AccountsController(store);
  await c.load();
  return c;
}

Future<LockController> _lock({bool enabled = false, bool supported = true}) async {
  final l = LockController(
      MemoryLockSettingsStore(LockSettings(enabled: enabled)), FakeAuthenticator(supported: supported));
  await l.load();
  return l;
}

Future<void> _app(WidgetTester tester, AccountsController c, {LockController? lock}) async {
  await tester.pumpWidget(KeepOtpApp(controller: c, lock: lock ?? await _lock(), clock: () => 59));
  await tester.pump();
}

/// Scrolls [target] into view (inside a dialog if it scrolls) and checks that it
/// ends up on the visible part of the screen, above any on-screen keyboard.
Future<void> _reach(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final r = tester.getRect(target);
  final visibleBottom = tester.view.physicalSize.height - tester.view.viewInsets.bottom;
  expect(r.top >= 0 && r.bottom <= visibleBottom, isTrue,
      reason: '$target at $r is outside the visible area (bottom $visibleBottom)');
}

/// Hosts [open] behind a button so a dialog can be shown from a real context.
Future<void> _showFrom(WidgetTester tester, Future<void> Function(BuildContext) open) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(child: TextButton(onPressed: () => open(context), child: const Text('open'))),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('landscape phone', () {
    testWidgets('account list is usable and its last row is reachable', (tester) async {
      _setScreen(tester);
      await _app(tester, await _accounts(8));
      expect(find.text('Service0'), findsOneWidget);

      // Scroll to the end: the last row must clear the floating button.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      final lastRow = tester.getRect(find.byType(ListTile).last);
      final fab = tester.getRect(find.byType(FloatingActionButton));
      expect(lastRow.bottom <= fab.top || lastRow.right <= fab.left, isTrue,
          reason: 'last row $lastRow is covered by the button $fab');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('empty state fits', (tester) async {
      _setScreen(tester);
      await _app(tester, await _accounts(0));
      expect(find.text('No accounts yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('search mode with the keyboard open', (tester) async {
      _setScreen(tester, keyboard: _keyboardHeight);
      await _app(tester, await _accounts(8));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'service1');
      await tester.pump();
      expect(find.text('Service1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('add account page scrolls with the keyboard open', (tester) async {
      _setScreen(tester, keyboard: _keyboardHeight);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AddAccountPage(),
      ));
      await tester.pump();
      await tester.dragUntilVisible(
          find.text('Add'), find.byType(ListView), const Offset(0, -100));
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('settings page', (tester) async {
      _setScreen(tester);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(lock: await _lock()),
      ));
      expect(find.text('App lock'), findsOneWidget);
    });

    testWidgets('lock screen with its unlock button visible', (tester) async {
      _setScreen(tester);
      final lock = await _lock(enabled: true);
      lock.locked; // starts locked
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LockScreen(controller: lock),
      ));
      await tester.pump();
      final button = tester.getRect(find.text('Unlock'));
      expect(button.bottom <= _phoneLandscape.height, isTrue);
    });

    testWidgets('backup password dialog with the keyboard open', (tester) async {
      _setScreen(tester, keyboard: _keyboardHeight);
      final c = await _accounts(2);
      await _showFrom(tester, (context) => exportEncryptedBackup(context, c));
      expect(find.text('Set backup password'), findsOneWidget);
      // Both fields and the buttons can still be reached.
      await _reach(tester, find.text('Confirm password'));
      await _reach(tester, find.text('OK'));
    });

    testWidgets('plain export warning', (tester) async {
      _setScreen(tester);
      final c = await _accounts(2);
      await _showFrom(tester, (context) => exportPlainText(context, c));
      expect(find.text('Export without encryption?'), findsOneWidget);
      await _reach(tester, find.text('Export anyway'));
      await _reach(tester, find.text('Cancel'));
    });

    testWidgets('edit and remove dialogs', (tester) async {
      _setScreen(tester, keyboard: _keyboardHeight);
      await _app(tester, await _accounts(2));
      await tester.tap(find.byType(PopupMenuButton<void>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit account'), findsOneWidget);
      await _reach(tester, find.text('Account (e.g. you@example.com)'));
      await _reach(tester, find.text('Save'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('large text', () {
    testWidgets('list, dialogs and settings survive 200% text in landscape', (tester) async {
      _setScreen(tester, textScale: 2);
      await _app(tester, await _accounts(3));
      expect(find.byType(ListTile), findsWidgets);
      await tester.tap(find.byType(PopupMenuButton<void>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove account?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('tablet landscape', () {
    testWidgets('content keeps a readable width on a wide screen', (tester) async {
      _setScreen(tester, size: const Size(1280, 800));
      await _app(tester, await _accounts(3));
      final tile = tester.getRect(find.byType(ListTile).first);
      expect(tile.width <= 700, isTrue, reason: 'tile is ${tile.width} wide');
      await tester.pumpWidget(const SizedBox());
    });
  });
}
