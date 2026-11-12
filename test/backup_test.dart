import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/backup/backup.dart';
import 'package:keep_otp/otp/otp_account.dart';

// Low-cost parameters keep tests fast; production defaults are in KdfParams.
final _codec = BackupCodec(params: const KdfParams(memoryKiB: 64, iterations: 1));

final _accounts = [
  OtpAccount.fromUri('otpauth://totp/GitHub:alice?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=GitHub'),
  OtpAccount.fromUri('otpauth://hotp/x?secret=MZXW6YTBOI&counter=5&digits=8'),
];

void main() {
  test('round trip', () async {
    final file = await _codec.encrypt(_accounts, 'correct horse');
    final back = await _codec.decrypt(file, 'correct horse');
    expect(back.map((a) => a.toUri()), _accounts.map((a) => a.toUri()));
  });

  test('file does not contain plaintext secrets', () async {
    final file = await _codec.encrypt(_accounts, 'pw');
    expect(file.contains('GEZDGNBV'), isFalse);
    expect(file.contains('otpauth'), isFalse);
  });

  test('same input yields different files (random salt/nonce)', () async {
    expect(await _codec.encrypt(_accounts, 'pw'), isNot(await _codec.encrypt(_accounts, 'pw')));
  });

  test('wrong password is rejected', () async {
    final file = await _codec.encrypt(_accounts, 'right');
    expect(_codec.decrypt(file, 'wrong'), throwsA(isA<BackupAuthenticationException>()));
  });

  test('tampered ciphertext is rejected', () async {
    final j = jsonDecode(await _codec.encrypt(_accounts, 'pw')) as Map<String, dynamic>;
    final ct = base64.decode(j['ciphertext'] as String)..[0] ^= 1;
    j['ciphertext'] = base64.encode(ct);
    expect(_codec.decrypt(jsonEncode(j), 'pw'), throwsA(isA<BackupAuthenticationException>()));
  });

  test('tampered header (KDF params) is rejected', () async {
    final j = jsonDecode(await _codec.encrypt(_accounts, 'pw')) as Map<String, dynamic>;
    (j['kdf'] as Map<String, dynamic>)['t'] = 2;
    expect(_codec.decrypt(jsonEncode(j), 'pw'), throwsA(isA<BackupAuthenticationException>()));
  });

  test('malformed and hostile files', () async {
    expect(_codec.decrypt('not json', 'pw'), throwsA(isA<BackupFormatException>()));
    expect(_codec.decrypt('{"format":"other"}', 'pw'), throwsA(isA<BackupFormatException>()));
    final j = jsonDecode(await _codec.encrypt(_accounts, 'pw')) as Map<String, dynamic>;
    (j['kdf'] as Map<String, dynamic>)['m'] = 1 << 30; // memory bomb
    expect(_codec.decrypt(jsonEncode(j), 'pw'), throwsA(isA<BackupFormatException>()));
  });

  test('empty password refused', () {
    expect(_codec.encrypt(_accounts, ''), throwsArgumentError);
  });
}
