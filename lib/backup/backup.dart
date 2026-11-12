import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../otp/otp_account.dart';

/// Thrown when a backup cannot be decrypted: wrong password or tampered file.
class BackupAuthenticationException implements Exception {
  const BackupAuthenticationException();
  @override
  String toString() => 'Wrong password or corrupted backup file';
}

/// Thrown when the file is not a valid or supported backup.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'Invalid backup file: $message';
}

/// Argon2id parameters. Defaults follow the OWASP minimum recommendation
/// (19 MiB, 2 iterations, 1 lane).
class KdfParams {
  const KdfParams({this.memoryKiB = 19456, this.iterations = 2, this.parallelism = 1});
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  // Upper bounds protect against a malicious file forcing huge allocations.
  static const _maxMemoryKiB = 256 * 1024;
  static const _maxIterations = 10;
  static const _maxParallelism = 8;

  void validate() {
    if (memoryKiB < 8 || memoryKiB > _maxMemoryKiB ||
        iterations < 1 || iterations > _maxIterations ||
        parallelism < 1 || parallelism > _maxParallelism) {
      throw const BackupFormatException('KDF parameters out of range');
    }
  }
}

/// Password-encrypted backup file (Argon2id + AES-256-GCM), no server needed.
///
/// File layout (JSON):
/// ```
/// { "format": "keep-otp-backup", "version": 1,
///   "kdf": {"name": "argon2id", "m": KiB, "t": n, "p": n, "salt": b64},
///   "cipher": {"name": "aes-256-gcm", "nonce": b64},
///   "ciphertext": b64 (includes 16-byte GCM tag) }
/// ```
/// The header fields are bound to the ciphertext as AES-GCM associated data,
/// so altering any of them makes decryption fail.
class BackupCodec {
  BackupCodec({this.params = const KdfParams()});

  final KdfParams params;

  static const formatId = 'keep-otp-backup';
  static const version = 1;
  static const _tagLength = 16;

  static final _aes = AesGcm.with256bits();

  Future<SecretKey> _deriveKey(String password, KdfParams p, List<int> salt) {
    final kdf = Argon2id(
      memory: p.memoryKiB,
      iterations: p.iterations,
      parallelism: p.parallelism,
      hashLength: 32,
    );
    return kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  static List<int> _aad(KdfParams p, List<int> salt, List<int> nonce) => utf8.encode(
      '$formatId|v$version|argon2id|${p.memoryKiB}|${p.iterations}|${p.parallelism}|'
      '${base64.encode(salt)}|aes-256-gcm|${base64.encode(nonce)}');

  /// Encrypts [accounts] with [password] and returns the backup file contents.
  Future<String> encrypt(List<OtpAccount> accounts, String password) async {
    if (password.isEmpty) throw ArgumentError('Password must not be empty');
    params.validate();
    final rng = Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final nonce = _aes.newNonce();
    final key = await _deriveKey(password, params, salt);

    final plain = utf8.encode(jsonEncode({'accounts': [for (final a in accounts) a.toUri()]}));
    final box = await _aes.encrypt(plain, secretKey: key, nonce: nonce, aad: _aad(params, salt, nonce));

    return jsonEncode({
      'format': formatId,
      'version': version,
      'kdf': {
        'name': 'argon2id',
        'm': params.memoryKiB,
        't': params.iterations,
        'p': params.parallelism,
        'salt': base64.encode(salt),
      },
      'cipher': {'name': 'aes-256-gcm', 'nonce': base64.encode(nonce)},
      'ciphertext': base64.encode([...box.cipherText, ...box.mac.bytes]),
    });
  }

  /// Decrypts a backup file. Throws [BackupFormatException] for a malformed
  /// file and [BackupAuthenticationException] for a wrong password/tampering.
  Future<List<OtpAccount>> decrypt(String file, String password) async {
    final Uint8List salt, nonce, data;
    final KdfParams p;
    try {
      final j = jsonDecode(file) as Map<String, dynamic>;
      if (j['format'] != formatId) throw const BackupFormatException('not a keep-otp backup');
      if (j['version'] != version) {
        throw BackupFormatException('unsupported version ${j['version']}');
      }
      final kdf = j['kdf'] as Map<String, dynamic>;
      final cipher = j['cipher'] as Map<String, dynamic>;
      if (kdf['name'] != 'argon2id' || cipher['name'] != 'aes-256-gcm') {
        throw const BackupFormatException('unsupported algorithms');
      }
      p = KdfParams(
        memoryKiB: kdf['m'] as int,
        iterations: kdf['t'] as int,
        parallelism: kdf['p'] as int,
      );
      salt = base64.decode(kdf['salt'] as String);
      nonce = base64.decode(cipher['nonce'] as String);
      data = base64.decode(j['ciphertext'] as String);
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('malformed structure');
    }
    p.validate();
    if (salt.length < 16 || nonce.length != 12 || data.length < _tagLength) {
      throw const BackupFormatException('bad field lengths');
    }

    final key = await _deriveKey(password, p, salt);
    final List<int> plain;
    try {
      plain = await _aes.decrypt(
        SecretBox(
          data.sublist(0, data.length - _tagLength),
          nonce: nonce,
          mac: Mac(data.sublist(data.length - _tagLength)),
        ),
        secretKey: key,
        aad: _aad(p, salt, nonce),
      );
    } on SecretBoxAuthenticationError {
      throw const BackupAuthenticationException();
    }

    try {
      final list = (jsonDecode(utf8.decode(plain)) as Map<String, dynamic>)['accounts'] as List;
      return [for (final u in list) OtpAccount.fromUri(u as String)];
    } on FormatException {
      throw const BackupFormatException('corrupted payload');
    }
  }
}
