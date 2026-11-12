import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../otp/otp_account.dart';

/// Persistence for accounts. Implementations must keep secrets protected.
abstract class AccountStore {
  Future<List<OtpAccount>> load();
  Future<void> save(List<OtpAccount> accounts);
}

/// Stores all accounts as one JSON blob in the OS secure storage
/// (Android Keystore-backed / iOS Keychain).
class SecureAccountStore implements AccountStore {
  SecureAccountStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'accounts.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<OtpAccount>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    return [for (final u in (jsonDecode(raw) as List)) OtpAccount.fromUri(u as String)];
  }

  @override
  Future<void> save(List<OtpAccount> accounts) =>
      _storage.write(key: _key, value: jsonEncode([for (final a in accounts) a.toUri()]));
}

/// In-memory store for tests.
class MemoryAccountStore implements AccountStore {
  List<OtpAccount> _data = [];

  @override
  Future<List<OtpAccount>> load() async => List.of(_data);

  @override
  Future<void> save(List<OtpAccount> accounts) async => _data = List.of(accounts);
}
