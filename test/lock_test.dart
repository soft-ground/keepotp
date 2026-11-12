import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/data/account_store.dart';
import 'package:keep_otp/lock/lock_controller.dart';
import 'package:keep_otp/lock/lock_gate.dart';
import 'package:keep_otp/main.dart';
import 'package:keep_otp/otp/otp_account.dart';
import 'package:keep_otp/state/accounts_controller.dart';

import 'fakes.dart';

DateTime _t = DateTime(2026, 1, 1, 12);

Future<(LockController, FakeAuthenticator)> _make({
  LockSettings settings = const LockSettings(),
  bool supported = true,
  bool succeeds = true,
}) async {
  _t = DateTime(2026, 1, 1, 12);
  final auth = FakeAuthenticator(supported: supported, succeeds: succeeds);
  final c = LockController(MemoryLockSettingsStore(settings), auth, now: () => _t);
  await c.load();
  return (c, auth);
}

/// Test screen that records how often its State is created and exposes its context.
class _Probe extends StatefulWidget {
  const _Probe({required this.onCreate});

  final VoidCallback onCreate;
  static BuildContext? lastContext;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) {
    _Probe.lastContext = context;
    return const Scaffold(body: Text('probe'));
  }
}

void main() {
  group('LockController', () {
    test('starts locked and unlocks on success', () async {
      final (c, auth) = await _make();
      expect(c.locked, isTrue);
      expect(await c.unlock(), isTrue);
      expect(c.locked, isFalse);
      expect(auth.prompts, 1);
    });

    test('stays locked when authentication fails', () async {
      final (c, _) = await _make(succeeds: false);
      expect(await c.unlock(), isFalse);
      expect(c.locked, isTrue);
    });

    test('not locked when disabled', () async {
      final (c, _) = await _make(settings: const LockSettings(enabled: false));
      expect(c.locked, isFalse);
    });

    test('not locked when the device has no screen lock', () async {
      final (c, _) = await _make(supported: false);
      expect(c.locked, isFalse);
      expect(c.supported, isFalse);
      expect(await c.setEnabled(true), isFalse);
    });

    test('re-locks immediately when timeout is 0', () async {
      final (c, _) = await _make();
      await c.unlock();
      c.onBackgrounded();
      c.onForegrounded();
      expect(c.locked, isTrue);
    });

    test('respects the timeout grace period', () async {
      final (c, _) = await _make(settings: const LockSettings(timeoutSeconds: 30));
      await c.unlock();

      c.onBackgrounded();
      _t = _t.add(const Duration(seconds: 10));
      c.onForegrounded();
      expect(c.locked, isFalse);

      c.onBackgrounded();
      _t = _t.add(const Duration(seconds: 31));
      c.onForegrounded();
      expect(c.locked, isTrue);
    });

    test('does not re-lock after an external flow', () async {
      final (c, _) = await _make();
      await c.unlock();
      await c.external(() async {
        c.onBackgrounded();
        c.onForegrounded();
      });
      expect(c.locked, isFalse);
    });

    test('turning the lock off requires authentication', () async {
      final (c, auth) = await _make();
      await c.unlock();
      auth.succeeds = false;
      expect(await c.setEnabled(false), isFalse);
      expect(c.enabled, isTrue);
      auth.succeeds = true;
      expect(await c.setEnabled(false), isTrue);
      expect(c.enabled, isFalse);
    });

    test('settings persist', () async {
      final store = MemoryLockSettingsStore();
      final c = LockController(store, FakeAuthenticator());
      await c.load();
      await c.setTimeoutSeconds(60);
      expect((await store.load()).timeoutSeconds, 60);
    });
  });

  group('LockGate', () {
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    Future<AccountsController> accounts() async {
      final store = MemoryAccountStore();
      await store.save([OtpAccount.fromUri('otpauth://totp/GitHub:alice?secret=$secret&issuer=GitHub')]);
      final c = AccountsController(store);
      await c.load();
      return c;
    }

    testWidgets('hides codes until unlocked', (tester) async {
      final (lock, auth) = await _make(succeeds: false);
      await tester.pumpWidget(KeepOtpApp(controller: await accounts(), lock: lock, clock: () => 59));
      await tester.pump();

      expect(find.text('Keep OTP is locked'), findsOneWidget);
      expect(find.text('GitHub'), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);

      auth.succeeds = true;
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Keep OTP is locked'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('open screens and pending flows survive a background trip', (tester) async {
      final (lock, _) = await _make(settings: const LockSettings(enabled: false));
      final created = <int>[];
      var counter = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => LockGate(controller: lock, child: child!),
        home: _Probe(onCreate: () => created.add(++counter)),
      ));
      await tester.pump();
      expect(created, [1]);

      // E.g. the file picker or camera permission dialog sends the app away.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Same State object: the screen was hidden, not rebuilt from scratch, so a
      // BuildContext captured before the trip is still mounted afterwards.
      expect(created, [1]);
      expect(_Probe.lastContext!.mounted, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('covers content while the app is in the background', (tester) async {
      final (lock, _) = await _make(settings: const LockSettings(enabled: false));
      await tester.pumpWidget(KeepOtpApp(controller: await accounts(), lock: lock, clock: () => 59));
      await tester.pump();
      expect(find.text('GitHub'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('GitHub'), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('GitHub'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
