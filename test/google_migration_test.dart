import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keep_otp/otp/base32.dart';
import 'package:keep_otp/otp/google_migration.dart';
import 'package:keep_otp/otp/otp.dart';
import 'package:keep_otp/otp/otp_account.dart';

// Hand-written protocol buffer encoding, independent of the parser under test.
List<int> _varint(int v) {
  final out = <int>[];
  while (v >= 0x80) {
    out.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  return out..add(v);
}

List<int> _lenField(int number, List<int> payload) =>
    [..._varint(number << 3 | 2), ..._varint(payload.length), ...payload];

List<int> _intField(int number, int value) => [..._varint(number << 3), ..._varint(value)];

/// One `OtpParameters` message.
List<int> _otp({
  required List<int> secret,
  String name = '',
  String issuer = '',
  int algorithm = 1,
  int digits = 1,
  int type = 2,
  int? counter,
}) =>
    [
      ..._lenField(1, secret),
      if (name.isNotEmpty) ..._lenField(2, utf8.encode(name)),
      if (issuer.isNotEmpty) ..._lenField(3, utf8.encode(issuer)),
      ..._intField(4, algorithm),
      ..._intField(5, digits),
      ..._intField(6, type),
      if (counter != null) ..._intField(7, counter),
    ];

/// A `MigrationPayload` message.
List<int> _payload(List<List<int>> accounts, {int size = 1, int index = 0, int id = 42}) => [
      for (final a in accounts) ..._lenField(1, a),
      ..._intField(2, 1),
      ..._intField(3, size),
      ..._intField(4, index),
      ..._intField(5, id),
    ];

String _uri(List<int> payload) =>
    'otpauth-migration://offline?data=${Uri.encodeQueryComponent(base64.encode(payload))}';

// "Hello!" followed by 0xDE 0xAD 0xBE 0xEF, the secret used in many examples.
final _secret = [0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x21, 0xde, 0xad, 0xbe, 0xef];

void main() {
  group('parseMigrationUri', () {
    test('parses an export link published in the dim13/otpauth README', () {
      // A link in the format real authenticator apps produce, with its documented
      // result: otpauth://totp/Example:alice@google.com?issuer=Example&secret=JBSWY3DPEHPK3PXP
      const link = 'otpauth-migration://offline?data='
          'CjEKCkhlbGxvId6tvu8SGEV4YW1wbGU6YWxpY2VAZ29vZ2xlLmNvbRoHRXhhbXBsZTAC';
      final a = parseMigrationUri(link).accounts.single;
      expect(base32Encode(a.secret), 'JBSWY3DPEHPK3PXP');
      expect(a.issuer, 'Example');
      expect(a.accountName, 'alice@google.com');
      expect(a.type, OtpType.totp);
      expect(a.algorithm, OtpAlgorithm.sha1);
      expect(a.digits, 6);
    });

    test('parses a single TOTP account', () {
      final batch = parseMigrationUri(_uri(_payload([
        _otp(secret: _secret, name: 'Example:alice@example.com', issuer: 'Example'),
      ])));
      expect(batch.accounts, hasLength(1));
      final a = batch.accounts.single;
      expect(a.type, OtpType.totp);
      expect(a.secret, Uint8List.fromList(_secret));
      expect(base32Encode(a.secret), 'JBSWY3DPEHPK3PXP');
      expect(a.issuer, 'Example');
      expect(a.accountName, 'alice@example.com');
      expect(a.algorithm, OtpAlgorithm.sha1);
      expect(a.digits, 6);
      expect(a.period, 30);
      expect(batch.batchSize, 1);
      expect(batch.batchIndex, 0);
    });

    test('maps algorithm, digits, type and counter', () {
      final batch = parseMigrationUri(_uri(_payload([
        _otp(secret: _secret, name: 'bob', algorithm: 3, digits: 2, type: 1, counter: 300),
        _otp(secret: _secret, name: 'carol', algorithm: 2, digits: 1, type: 2),
      ])));
      final hotp = batch.accounts[0];
      expect(hotp.type, OtpType.hotp);
      expect(hotp.algorithm, OtpAlgorithm.sha512);
      expect(hotp.digits, 8);
      expect(hotp.counter, 300); // needs a two-byte varint
      expect(batch.accounts[1].algorithm, OtpAlgorithm.sha256);
    });

    test('treats unspecified algorithm, digits and type as SHA-1, 6 and TOTP', () {
      final a = parseMigrationUri(_uri(_payload([
        _otp(secret: _secret, name: 'x', algorithm: 0, digits: 0, type: 0),
      ]))).accounts.single;
      expect(a.algorithm, OtpAlgorithm.sha1);
      expect(a.digits, 6);
      expect(a.type, OtpType.totp);
    });

    test('splits an issuer that is only present in the name', () {
      final a = parseMigrationUri(_uri(_payload([_otp(secret: _secret, name: 'GitHub:alice')])))
          .accounts
          .single;
      expect(a.issuer, 'GitHub');
      expect(a.accountName, 'alice');
    });

    test('keeps a name that does not start with the issuer', () {
      final a = parseMigrationUri(
              _uri(_payload([_otp(secret: _secret, name: 'alice', issuer: 'GitHub')])))
          .accounts
          .single;
      expect(a.issuer, 'GitHub');
      expect(a.accountName, 'alice');
    });

    test('generates the same code as the equivalent otpauth link', () {
      final fromMigration = parseMigrationUri(_uri(_payload([
        _otp(secret: _secret, name: 'Example:alice', issuer: 'Example'),
      ]))).accounts.single;
      final fromLink =
          OtpAccount.fromUri('otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&issuer=Example');
      for (final t in [59, 1111111109, 1234567890]) {
        expect(fromMigration.code(t), fromLink.code(t));
      }
    });

    test('accepts a raw plus sign, URL-safe Base64 and missing padding', () {
      // Choose a secret so that the encoded payload contains '+' and '/'.
      final payload = _payload([
        _otp(secret: [0xfb, 0xef, 0xbe, 0xff, 0xfe, 0xfb, 0xff], name: 'a'),
      ]);
      final standard = base64.encode(payload);
      expect(standard, anyOf(contains('+'), contains('/')));
      final unpadded = standard.replaceAll('=', '');
      final urlSafe = standard.replaceAll('+', '-').replaceAll('/', '_');
      for (final data in [standard, unpadded, urlSafe]) {
        final batch = parseMigrationUri('otpauth-migration://offline?data=$data');
        expect(batch.accounts.single.secret.first, 0xfb, reason: data);
      }
    });

    test('skips unknown fields', () {
      final account = [..._otp(secret: _secret, name: 'x'), ..._intField(15, 7)];
      final payload = [..._payload([account]), ..._lenField(14, [1, 2, 3])];
      expect(parseMigrationUri(_uri(payload)).accounts, hasLength(1));
    });

    test('reads batch information', () {
      final batch = parseMigrationUri(
          _uri(_payload([_otp(secret: _secret, name: 'x')], size: 3, index: 2, id: 123456789)));
      expect(batch.batchSize, 3);
      expect(batch.batchIndex, 2);
      expect(batch.batchId, 123456789);
    });

    test('rejects malformed input', () {
      final good = _payload([_otp(secret: _secret, name: 'x')]);
      final cases = <String, String>{
        'wrong scheme': 'otpauth://totp/x?secret=JBSWY3DPEHPK3PXP',
        'no data': 'otpauth-migration://offline',
        'empty data': 'otpauth-migration://offline?data=',
        'not base64': 'otpauth-migration://offline?data=!!!!',
        // Cut inside the last field (a tag without its value).
        'truncated': _uri(good.sublist(0, good.length - 1)),
        'truncated inside an account': _uri(good.sublist(0, 10)),
        'no accounts': _uri(_intField(3, 1)),
        'empty secret': _uri(_payload([_otp(secret: [], name: 'x')])),
        'MD5': _uri(_payload([_otp(secret: _secret, name: 'x', algorithm: 4)])),
        'bad digits': _uri(_payload([_otp(secret: _secret, name: 'x', digits: 9)])),
        'bad type': _uri(_payload([_otp(secret: _secret, name: 'x', type: 7)])),
        'index out of range':
            _uri(_payload([_otp(secret: _secret, name: 'x')], size: 2, index: 2)),
        'zero batch size': _uri(_payload([_otp(secret: _secret, name: 'x')], size: 0)),
        'field length beyond data': _uri([..._varint(1 << 3 | 2), ..._varint(500), 1, 2]),
        'endless varint': _uri(List.filled(12, 0xff)),
      };
      cases.forEach((name, uri) {
        expect(() => parseMigrationUri(uri), throwsFormatException, reason: name);
      });
    });

    test('rejects an oversized payload', () {
      final huge = List.filled(70 * 1024, 0);
      expect(() => parseMigrationUri(_uri(huge)), throwsFormatException);
    });
  });

  test('isMigrationUri', () {
    expect(isMigrationUri('otpauth-migration://offline?data=AA'), isTrue);
    expect(isMigrationUri('  OTPAUTH-MIGRATION://offline?data=AA'), isTrue);
    expect(isMigrationUri('otpauth://totp/x?secret=AA'), isFalse);
  });

  group('MigrationCollector', () {
    MigrationBatch part(int index, int size, int id, String name) => parseMigrationUri(_uri(
        _payload([_otp(secret: _secret, name: name)], size: size, index: index, id: id)));

    test('completes once every part is seen, in any order', () {
      final c = MigrationCollector();
      expect(c.add(part(2, 3, 9, 'c')), isFalse);
      expect(c.add(part(0, 3, 9, 'a')), isFalse);
      expect(c.add(part(0, 3, 9, 'a')), isFalse); // the same code seen again
      expect(c.scanned, 2);
      expect(c.total, 3);
      expect(c.add(part(1, 3, 9, 'b')), isTrue);
      expect([for (final a in c.accounts) a.accountName], ['a', 'b', 'c']);
    });

    test('a single-part export is complete immediately', () {
      final c = MigrationCollector();
      expect(c.add(part(0, 1, 5, 'only')), isTrue);
      expect(c.accounts, hasLength(1));
    });

    test('scanning a different export starts over', () {
      final c = MigrationCollector();
      c.add(part(0, 2, 1, 'old'));
      expect(c.add(part(0, 2, 2, 'new')), isFalse);
      expect(c.scanned, 1);
      expect(c.add(part(1, 2, 2, 'new2')), isTrue);
      expect([for (final a in c.accounts) a.accountName], ['new', 'new2']);
    });
  });
}
