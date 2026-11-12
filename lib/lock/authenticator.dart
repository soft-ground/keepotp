import 'package:local_auth/local_auth.dart';

/// Abstraction over the OS device-credential prompt (biometrics, PIN, pattern,
/// passcode) so the lock logic can be tested without a device.
abstract class Authenticator {
  /// True if the device has a secure screen lock or biometrics enrolled.
  Future<bool> isSupported();

  /// Shows the OS prompt. Returns false if the user cancels or fails.
  Future<bool> authenticate(String reason);
}

class LocalAuthAuthenticator implements Authenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // biometricOnly: false lets the user fall back to the device PIN/pattern.
      return await _auth.authenticate(localizedReason: reason);
    } on LocalAuthException {
      return false; // cancelled, locked out, no credentials, etc.
    } catch (_) {
      return false;
    }
  }
}
