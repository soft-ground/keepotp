import 'dart:typed_data';

import 'base32.dart';
import 'otp.dart';

enum OtpType { totp, hotp }

/// A single OTP account, convertible to/from the de-facto standard
/// `otpauth://` URI (Google Authenticator Key URI Format).
class OtpAccount {
  const OtpAccount({
    required this.type,
    required this.secret,
    required this.accountName,
    this.issuer = '',
    this.algorithm = OtpAlgorithm.sha1,
    this.digits = 6,
    this.period = 30,
    this.counter = 0,
  });

  final OtpType type;
  final Uint8List secret;
  final String accountName;
  final String issuer;
  final OtpAlgorithm algorithm;
  final int digits;
  final int period;
  final int counter;

  OtpAccount copyWith({int? counter}) => OtpAccount(
        type: type,
        secret: secret,
        accountName: accountName,
        issuer: issuer,
        algorithm: algorithm,
        digits: digits,
        period: period,
        counter: counter ?? this.counter,
      );

  /// Parses an `otpauth://` URI. Throws [FormatException] if invalid.
  factory OtpAccount.fromUri(String uri) {
    final Uri u;
    try {
      u = Uri.parse(uri.trim());
    } on FormatException {
      throw FormatException('Malformed URI', uri);
    }
    if (u.scheme.toLowerCase() != 'otpauth') {
      throw FormatException('Scheme must be otpauth', uri);
    }
    final type = switch (u.host.toLowerCase()) {
      'totp' => OtpType.totp,
      'hotp' => OtpType.hotp,
      _ => throw FormatException('Unsupported OTP type: ${u.host}', uri),
    };

    final q = {for (final e in u.queryParameters.entries) e.key.toLowerCase(): e.value};
    final secretStr = q['secret'];
    if (secretStr == null || secretStr.isEmpty) {
      throw FormatException('Missing secret', uri);
    }

    // Path is "/Label" where Label is "Issuer:Account" or "Account".
    var label = Uri.decodeComponent(u.path.startsWith('/') ? u.path.substring(1) : u.path);
    var labelIssuer = '';
    final colon = label.indexOf(':');
    if (colon >= 0) {
      labelIssuer = label.substring(0, colon).trim();
      label = label.substring(colon + 1).trim();
    }
    // The issuer parameter takes precedence over the label prefix.
    final issuer = (q['issuer']?.isNotEmpty ?? false) ? q['issuer']! : labelIssuer;

    final algorithm = switch ((q['algorithm'] ?? 'SHA1').toUpperCase()) {
      'SHA1' => OtpAlgorithm.sha1,
      'SHA256' => OtpAlgorithm.sha256,
      'SHA512' => OtpAlgorithm.sha512,
      final a => throw FormatException('Unsupported algorithm: $a', uri),
    };

    int intParam(String name, int def, {required int min, required int max}) {
      final raw = q[name];
      if (raw == null) return def;
      final v = int.tryParse(raw);
      if (v == null || v < min || v > max) {
        throw FormatException('Invalid $name: $raw', uri);
      }
      return v;
    }

    final counter = type == OtpType.hotp
        ? (q.containsKey('counter')
            ? intParam('counter', 0, min: 0, max: 0x7fffffffffffffff)
            : throw FormatException('HOTP requires counter', uri))
        : 0;

    return OtpAccount(
      type: type,
      secret: base32Decode(secretStr),
      accountName: label,
      issuer: issuer,
      algorithm: algorithm,
      digits: intParam('digits', 6, min: 6, max: 8),
      period: intParam('period', 30, min: 1, max: 3600),
      counter: counter,
    );
  }

  /// Serializes to a standard `otpauth://` URI.
  String toUri() {
    final label = issuer.isEmpty
        ? Uri.encodeComponent(accountName)
        : '${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(accountName)}';
    final params = <String, String>{
      'secret': base32Encode(secret),
      if (issuer.isNotEmpty) 'issuer': issuer,
      'algorithm': algorithm.name.toUpperCase(),
      'digits': '$digits',
      if (type == OtpType.totp) 'period': '$period' else 'counter': '$counter',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value).replaceAll('+', '%20')}')
        .join('&');
    return 'otpauth://${type.name}/$label?$query';
  }

  /// Current code. [unixSeconds] is used for TOTP; HOTP uses [counter].
  String code(int unixSeconds) => type == OtpType.totp
      ? totp(secret, unixSeconds, period: period, digits: digits, algorithm: algorithm)
      : hotp(secret, counter, digits: digits, algorithm: algorithm);
}
