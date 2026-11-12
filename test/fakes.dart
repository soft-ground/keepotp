import 'package:keep_otp/lock/authenticator.dart';

class FakeAuthenticator implements Authenticator {
  FakeAuthenticator({this.supported = true, this.succeeds = true});

  bool supported;
  bool succeeds;
  int prompts = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeeds;
  }
}
