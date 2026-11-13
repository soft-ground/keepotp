import 'dart:convert';
import 'dart:typed_data';

import 'otp.dart';
import 'otp_account.dart';

/// One QR code of a Google Authenticator "Transfer accounts" export.
///
/// The export is an `otpauth-migration://offline?data=...` link whose `data`
/// is a Base64 encoded protocol buffer (`MigrationPayload`). Large exports are
/// split over several QR codes: [batchSize] codes that share a [batchId], each
/// with its own [batchIndex].
class MigrationBatch {
  const MigrationBatch({
    required this.accounts,
    required this.batchSize,
    required this.batchIndex,
    required this.batchId,
  });

  final List<OtpAccount> accounts;
  final int batchSize;
  final int batchIndex;
  final int batchId;
}

/// Whether [raw] looks like a Google Authenticator export link.
bool isMigrationUri(String raw) => raw.trim().toLowerCase().startsWith('otpauth-migration:');

const _maxPayloadBytes = 64 * 1024;
const _maxAccountsPerBatch = 500;

/// Parses an `otpauth-migration://` link. Throws [FormatException] if invalid.
MigrationBatch parseMigrationUri(String raw) {
  final text = raw.trim();
  if (!isMigrationUri(text)) {
    throw FormatException('Scheme must be otpauth-migration', raw);
  }
  final query = text.contains('?') ? text.substring(text.indexOf('?') + 1) : '';
  String? data;
  for (final pair in query.split('&')) {
    final eq = pair.indexOf('=');
    if (eq > 0 && pair.substring(0, eq) == 'data') {
      // Percent-decode only: a raw '+' is part of Base64, not a space.
      data = Uri.decodeComponent(pair.substring(eq + 1));
    }
  }
  if (data == null || data.isEmpty) throw FormatException('Missing data', raw);

  final Uint8List bytes;
  try {
    bytes = _decodeBase64(data);
  } on FormatException {
    throw FormatException('Data is not valid Base64', raw);
  }
  if (bytes.length > _maxPayloadBytes) throw FormatException('Payload too large', raw);
  return _parsePayload(bytes);
}

Uint8List _decodeBase64(String data) {
  var s = data.replaceAll(RegExp(r'\s'), '').replaceAll('-', '+').replaceAll('_', '/');
  s = s.replaceAll('=', '');
  s += '=' * ((4 - s.length % 4) % 4);
  return base64.decode(s);
}

/// Minimal protocol buffer reader: just enough for the migration format.
class _Reader {
  _Reader(this._b);

  final Uint8List _b;
  int _pos = 0;

  bool get hasMore => _pos < _b.length;

  int varint() {
    var result = 0;
    for (var shift = 0; shift < 70; shift += 7) {
      if (_pos >= _b.length) throw const FormatException('Truncated varint');
      final byte = _b[_pos++];
      if (shift < 64) result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return result;
    }
    throw const FormatException('Varint too long');
  }

  Uint8List bytes() {
    final length = varint();
    if (length < 0 || length > _b.length - _pos) {
      throw const FormatException('Truncated field');
    }
    final out = Uint8List.sublistView(_b, _pos, _pos + length);
    _pos += length;
    return out;
  }

  void skip(int wireType) {
    switch (wireType) {
      case 0:
        varint();
      case 1:
        _advance(8);
      case 2:
        bytes();
      case 5:
        _advance(4);
      default:
        throw FormatException('Unsupported wire type $wireType');
    }
  }

  void _advance(int n) {
    if (n > _b.length - _pos) throw const FormatException('Truncated field');
    _pos += n;
  }
}

MigrationBatch _parsePayload(Uint8List bytes) {
  final r = _Reader(bytes);
  final accounts = <OtpAccount>[];
  var batchSize = 1, batchIndex = 0, batchId = 0;
  while (r.hasMore) {
    final tag = r.varint();
    final field = tag >> 3, wire = tag & 7;
    if (field == 1 && wire == 2) {
      if (accounts.length >= _maxAccountsPerBatch) {
        throw const FormatException('Too many accounts');
      }
      accounts.add(_parseAccount(r.bytes()));
    } else if (field == 3 && wire == 0) {
      batchSize = r.varint();
    } else if (field == 4 && wire == 0) {
      batchIndex = r.varint();
    } else if (field == 5 && wire == 0) {
      batchId = r.varint();
    } else {
      r.skip(wire);
    }
  }
  if (accounts.isEmpty) throw const FormatException('No accounts in export');
  if (batchSize < 1 || batchSize > 1000 || batchIndex < 0 || batchIndex >= batchSize) {
    throw const FormatException('Invalid batch information');
  }
  return MigrationBatch(
    accounts: accounts,
    batchSize: batchSize,
    batchIndex: batchIndex,
    batchId: batchId,
  );
}

OtpAccount _parseAccount(Uint8List bytes) {
  final r = _Reader(bytes);
  var secret = Uint8List(0);
  var name = '', issuer = '';
  var algorithm = 0, digits = 0, type = 0, counter = 0;
  while (r.hasMore) {
    final tag = r.varint();
    final field = tag >> 3, wire = tag & 7;
    if (field == 1 && wire == 2) {
      secret = Uint8List.fromList(r.bytes());
    } else if (field == 2 && wire == 2) {
      name = utf8.decode(r.bytes(), allowMalformed: true);
    } else if (field == 3 && wire == 2) {
      issuer = utf8.decode(r.bytes(), allowMalformed: true);
    } else if (field == 4 && wire == 0) {
      algorithm = r.varint();
    } else if (field == 5 && wire == 0) {
      digits = r.varint();
    } else if (field == 6 && wire == 0) {
      type = r.varint();
    } else if (field == 7 && wire == 0) {
      counter = r.varint();
    } else {
      r.skip(wire);
    }
  }
  if (secret.isEmpty) throw const FormatException('Account without a secret');

  final alg = switch (algorithm) {
    0 || 1 => OtpAlgorithm.sha1,
    2 => OtpAlgorithm.sha256,
    3 => OtpAlgorithm.sha512,
    _ => throw FormatException('Unsupported algorithm: $algorithm'),
  };
  final digitCount = switch (digits) {
    0 || 1 => 6,
    2 => 8,
    _ => throw FormatException('Unsupported digit count: $digits'),
  };
  final otpType = switch (type) {
    1 => OtpType.hotp,
    0 || 2 => OtpType.totp,
    _ => throw FormatException('Unsupported OTP type: $type'),
  };

  // Google stores "Issuer:account" in the name and repeats the issuer.
  name = name.trim();
  issuer = issuer.trim();
  if (issuer.isNotEmpty && name.startsWith('$issuer:')) {
    name = name.substring(issuer.length + 1).trim();
  } else if (issuer.isEmpty && name.contains(':')) {
    final colon = name.indexOf(':');
    issuer = name.substring(0, colon).trim();
    name = name.substring(colon + 1).trim();
  }

  return OtpAccount(
    type: otpType,
    secret: secret,
    accountName: name,
    issuer: issuer,
    algorithm: alg,
    digits: digitCount,
    counter: otpType == OtpType.hotp && counter >= 0 ? counter : 0,
  );
}

/// Gathers the QR codes of one multi-part export, in any order. Scanning a code
/// that belongs to a different export starts over.
class MigrationCollector {
  int? _batchId;
  int _total = 1;
  final _parts = <int, List<OtpAccount>>{};

  int get scanned => _parts.length;
  int get total => _total;
  bool get isComplete => _batchId != null && _parts.length == _total;

  /// Adds one scanned code. Returns [isComplete].
  bool add(MigrationBatch batch) {
    if (_batchId != batch.batchId || _total != batch.batchSize) {
      _batchId = batch.batchId;
      _total = batch.batchSize;
      _parts.clear();
    }
    _parts[batch.batchIndex] = batch.accounts;
    return isComplete;
  }

  /// All accounts of a complete export, in export order.
  List<OtpAccount> get accounts => [
        for (var i = 0; i < _total; i++) ...?_parts[i],
      ];
}
