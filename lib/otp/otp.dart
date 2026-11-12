import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum OtpAlgorithm { sha1, sha256, sha512 }

Hash _hashFor(OtpAlgorithm a) => switch (a) {
      OtpAlgorithm.sha1 => sha1,
      OtpAlgorithm.sha256 => sha256,
      OtpAlgorithm.sha512 => sha512,
    };

/// HOTP, RFC 4226 (with dynamic truncation).
String hotp(
  Uint8List secret,
  int counter, {
  int digits = 6,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) {
  final msg = ByteData(8)..setUint64(0, counter, Endian.big);
  final mac = Hmac(_hashFor(algorithm), secret).convert(msg.buffer.asUint8List()).bytes;
  final offset = mac.last & 0x0f;
  final bin = ((mac[offset] & 0x7f) << 24) |
      (mac[offset + 1] << 16) |
      (mac[offset + 2] << 8) |
      mac[offset + 3];
  var mod = 1;
  for (var i = 0; i < digits; i++) {
    mod *= 10;
  }
  return (bin % mod).toString().padLeft(digits, '0');
}

/// TOTP, RFC 6238. [unixSeconds] is the current Unix time.
String totp(
  Uint8List secret,
  int unixSeconds, {
  int period = 30,
  int digits = 6,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) =>
    hotp(secret, unixSeconds ~/ period, digits: digits, algorithm: algorithm);
