import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/otp/otp.dart';

Uint8List _b(String s) => Uint8List.fromList(ascii.encode(s));

void main() {
  final k1 = _b('12345678901234567890');
  final k256 = _b('12345678901234567890123456789012');
  final k512 = _b('1234567890123456789012345678901234567890123456789012345678901234');

  test('HOTP RFC 4226 Appendix D', () {
    const expected = [
      '755224', '287082', '359152', '969429', '338314',
      '254676', '287922', '162583', '399871', '520489',
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(hotp(k1, i), expected[i]);
    }
  });

  test('TOTP RFC 6238 Appendix B', () {
    // time, sha1, sha256, sha512
    const rows = [
      [59, '94287082', '46119246', '90693936'],
      [1111111109, '07081804', '68084774', '25091201'],
      [1111111111, '14050471', '67062674', '99943326'],
      [1234567890, '89005924', '91819424', '93441116'],
      [2000000000, '69279037', '90698825', '38618901'],
      [20000000000, '65353130', '77737706', '47863826'],
    ];
    for (final r in rows) {
      final t = r[0] as int;
      expect(totp(k1, t, digits: 8), r[1], reason: 'sha1 t=$t');
      expect(totp(k256, t, digits: 8, algorithm: OtpAlgorithm.sha256), r[2], reason: 'sha256 t=$t');
      expect(totp(k512, t, digits: 8, algorithm: OtpAlgorithm.sha512), r[3], reason: 'sha512 t=$t');
    }
  });
}
