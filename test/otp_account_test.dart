import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/otp/base32.dart';
import 'package:keep_otp/otp/otp.dart';
import 'package:keep_otp/otp/otp_account.dart';

void main() {
  group('base32', () {
    // RFC 4648 section 10 test vectors.
    const vectors = {
      'f': 'MY',
      'fo': 'MZXQ',
      'foo': 'MZXW6',
      'foob': 'MZXW6YQ',
      'fooba': 'MZXW6YTB',
      'foobar': 'MZXW6YTBOI',
    };
    test('encode/decode RFC 4648', () {
      vectors.forEach((plain, enc) {
        final bytes = Uint8List.fromList(ascii.encode(plain));
        expect(base32Encode(bytes), enc);
        expect(base32Decode(enc), bytes);
      });
    });
    test('tolerates case, spaces, padding', () {
      expect(base32Decode('mzxw 6ytb-oi======'), ascii.encode('foobar'));
    });
    test('rejects invalid characters', () {
      expect(() => base32Decode('MZXW1'), throwsFormatException);
      expect(() => base32Decode(''), throwsFormatException);
    });
  });

  group('OtpAccount.fromUri', () {
    // "12345678901234567890" in Base32.
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('full TOTP URI', () {
      final a = OtpAccount.fromUri(
          'otpauth://totp/GitHub:alice%40example.com?secret=$secret&issuer=GitHub&algorithm=SHA256&digits=8&period=60');
      expect(a.type, OtpType.totp);
      expect(a.issuer, 'GitHub');
      expect(a.accountName, 'alice@example.com');
      expect(a.algorithm, OtpAlgorithm.sha256);
      expect(a.digits, 8);
      expect(a.period, 60);
    });

    test('defaults and label-only issuer', () {
      final a = OtpAccount.fromUri('otpauth://totp/Acme:bob?secret=$secret');
      expect(a.issuer, 'Acme');
      expect(a.algorithm, OtpAlgorithm.sha1);
      expect(a.digits, 6);
      expect(a.period, 30);
    });

    test('issuer param wins over label prefix', () {
      final a = OtpAccount.fromUri('otpauth://totp/Old:bob?secret=$secret&issuer=New');
      expect(a.issuer, 'New');
    });

    test('generates the RFC 6238 code', () {
      final a = OtpAccount.fromUri('otpauth://totp/x?secret=$secret&digits=8');
      expect(a.code(59), '94287082');
    });

    test('HOTP requires counter and uses it', () {
      expect(() => OtpAccount.fromUri('otpauth://hotp/x?secret=$secret'), throwsFormatException);
      final a = OtpAccount.fromUri('otpauth://hotp/x?secret=$secret&counter=1');
      expect(a.code(0), '287082');
    });

    test('rejects bad input', () {
      for (final bad in [
        'https://totp/x?secret=$secret',
        'otpauth://foo/x?secret=$secret',
        'otpauth://totp/x',
        'otpauth://totp/x?secret=!!!',
        'otpauth://totp/x?secret=$secret&digits=9',
        'otpauth://totp/x?secret=$secret&period=0',
        'otpauth://totp/x?secret=$secret&algorithm=MD5',
      ]) {
        expect(() => OtpAccount.fromUri(bad), throwsFormatException, reason: bad);
      }
    });

    test('toUri round-trips', () {
      final a = OtpAccount.fromUri(
          'otpauth://totp/My%20Co:a%2Bb%40x.com?secret=$secret&issuer=My%20Co&digits=8&period=45&algorithm=SHA512');
      final b = OtpAccount.fromUri(a.toUri());
      expect(b.issuer, 'My Co');
      expect(b.accountName, 'a+b@x.com');
      expect(b.secret, a.secret);
      expect(b.algorithm, OtpAlgorithm.sha512);
      expect(b.digits, 8);
      expect(b.period, 45);
    });
  });
}
