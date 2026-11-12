import 'dart:typed_data';

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// RFC 4648 Base32 decoder. Case-insensitive; ignores spaces, hyphens and
/// trailing '=' padding. Throws [FormatException] on invalid characters.
Uint8List base32Decode(String input) {
  final s = input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '').replaceAll(RegExp(r'=+$'), '');
  if (s.isEmpty) throw const FormatException('Empty Base32 string');
  final out = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final c in s.codeUnits) {
    final v = _alphabet.indexOf(String.fromCharCode(c));
    if (v < 0) throw FormatException('Invalid Base32 character', input);
    buffer = (buffer << 5) | v;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((buffer >> bits) & 0xff);
      buffer &= (1 << bits) - 1;
    }
  }
  return Uint8List.fromList(out);
}

/// RFC 4648 Base32 encoder without padding.
String base32Encode(Uint8List data) {
  final sb = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final b in data) {
    buffer = (buffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      sb.write(_alphabet[(buffer >> bits) & 31]);
      buffer &= (1 << bits) - 1;
    }
  }
  if (bits > 0) sb.write(_alphabet[(buffer << (5 - bits)) & 31]);
  return sb.toString();
}
