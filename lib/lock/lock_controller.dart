import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'authenticator.dart';

class LockSettings {
  const LockSettings({this.enabled = true, this.timeoutSeconds = 0});
  final bool enabled;

  /// How long the app may stay in the background before it re-locks.
  final int timeoutSeconds;
}

abstract class LockSettingsStore {
  Future<LockSettings> load();
  Future<void> save(LockSettings settings);
}

class SecureLockSettingsStore implements LockSettingsStore {
  SecureLockSettingsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'lock.enabled';
  static const _timeoutKey = 'lock.timeout';
  final FlutterSecureStorage _storage;

  @override
  Future<LockSettings> load() async {
    final enabled = await _storage.read(key: _enabledKey);
    final timeout = await _storage.read(key: _timeoutKey);
    return LockSettings(
      enabled: enabled != 'false', // locked by default
      timeoutSeconds: int.tryParse(timeout ?? '') ?? 0,
    );
  }

  @override
  Future<void> save(LockSettings s) async {
    await _storage.write(key: _enabledKey, value: '${s.enabled}');
    await _storage.write(key: _timeoutKey, value: '${s.timeoutSeconds}');
  }
}

class MemoryLockSettingsStore implements LockSettingsStore {
  MemoryLockSettingsStore([this._settings = const LockSettings()]);
  LockSettings _settings;

  @override
  Future<LockSettings> load() async => _settings;

  @override
  Future<void> save(LockSettings s) async => _settings = s;
}

/// Decides when the app is locked and drives the unlock prompt.
///
/// The app starts locked, and re-locks after being in the background for at
/// least [timeoutSeconds]. If the device has no screen lock, the app cannot be
/// protected, so it stays open and [supported] is false (the settings page
/// warns about it).
class LockController extends ChangeNotifier {
  LockController(this._store, this._auth, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final LockSettingsStore _store;
  final Authenticator _auth;
  final DateTime Function() _now;

  LockSettings _settings = const LockSettings();
  bool loaded = false;
  bool supported = true;
  bool _locked = true;
  bool _authenticating = false;
  bool _external = false;
  DateTime? _backgroundedAt;

  bool get enabled => _settings.enabled;
  int get timeoutSeconds => _settings.timeoutSeconds;

  /// True while content must be hidden. Before [load] finishes this is true so
  /// codes are never flashed on startup.
  bool get locked => _locked;

  Future<void> load() async {
    _settings = await _store.load();
    supported = await _auth.isSupported();
    _locked = _settings.enabled && supported;
    loaded = true;
    notifyListeners();
  }

  /// Prompts the OS credential dialog and unlocks on success.
  Future<bool> unlock() async {
    if (!_locked) return true;
    if (_authenticating) return false;
    _authenticating = true;
    try {
      final ok = await _auth.authenticate('Unlock to view your one-time codes');
      if (ok) {
        _locked = false;
        notifyListeners();
      }
      return ok;
    } finally {
      _authenticating = false;
    }
  }

  void onBackgrounded() {
    if (_external) return;
    _backgroundedAt ??= _now();
  }

  void onForegrounded() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || !_settings.enabled || !supported || _locked) return;
    if (_now().difference(since).inSeconds >= _settings.timeoutSeconds) {
      _locked = true;
      notifyListeners();
    }
  }

  /// Wraps a flow that sends the app to the background on purpose (file picker,
  /// camera permission dialog) so returning from it does not re-lock the app.
  Future<T> external<T>(Future<T> Function() flow) async {
    _external = true;
    _backgroundedAt = null;
    try {
      return await flow();
    } finally {
      // Late lifecycle events can arrive just after the flow completes.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _backgroundedAt = null;
      _external = false;
    }
  }

  /// Turning the lock off requires authenticating first. Returns false if the
  /// change was refused.
  Future<bool> setEnabled(bool value) async {
    if (value && !supported) return false;
    if (value == _settings.enabled) return true;
    if (!value && supported && !await _auth.authenticate('Confirm to turn off the app lock')) {
      return false;
    }
    await _update(LockSettings(enabled: value, timeoutSeconds: _settings.timeoutSeconds));
    return true;
  }

  Future<void> setTimeoutSeconds(int seconds) =>
      _update(LockSettings(enabled: _settings.enabled, timeoutSeconds: seconds));

  Future<void> _update(LockSettings s) async {
    _settings = s;
    await _store.save(s);
    notifyListeners();
  }
}
