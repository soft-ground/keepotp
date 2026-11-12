import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/data/account_store.dart';
import 'fakes.dart';
import 'package:keep_otp/lock/lock_controller.dart';
import 'package:keep_otp/main.dart';
import 'package:keep_otp/otp/otp_account.dart';
import 'package:keep_otp/state/accounts_controller.dart';

const _secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

Future<LockController> _openLock() async {
  final l = LockController(MemoryLockSettingsStore(const LockSettings(enabled: false)), FakeAuthenticator());
  await l.load();
  return l;
}

void main() {
  testWidgets('empty state is shown', (tester) async {
    final c = AccountsController(MemoryAccountStore());
    await c.load();
    await tester.pumpWidget(KeepOtpApp(controller: c, lock: await _openLock(), clock: () => 59));
    expect(find.text('No accounts yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the ticker
  });

  testWidgets('shows RFC 6238 code and countdown for a known time', (tester) async {
    final store = MemoryAccountStore();
    await store.save([
      OtpAccount.fromUri('otpauth://totp/GitHub:alice?secret=$_secret&issuer=GitHub&digits=8'),
    ]);
    final c = AccountsController(store);
    await c.load();
    await tester.pumpWidget(KeepOtpApp(controller: c, lock: await _openLock(), clock: () => 59));

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('9428 7082'), findsOneWidget); // RFC 6238, t=59, 8 digits
    expect(find.text('1'), findsOneWidget); // 30 - (59 % 30) = 1 s left
    await tester.pumpWidget(const SizedBox());
  });

  test('addAll skips duplicates', () async {
    final c = AccountsController(MemoryAccountStore());
    final a = OtpAccount.fromUri('otpauth://totp/A:x?secret=$_secret&issuer=A');
    expect(await c.addAll([a]), 1);
    expect(await c.addAll([OtpAccount.fromUri(a.toUri())]), 0);
    expect(c.accounts.length, 1);
  });

  test('HOTP counter advances and persists', () async {
    final store = MemoryAccountStore();
    final c = AccountsController(store);
    await c.add(OtpAccount.fromUri('otpauth://hotp/x?secret=$_secret&counter=0'));
    await c.advanceHotp(c.accounts.first);
    expect((await store.load()).first.counter, 1);
  });
}
