import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

// A phone with no screen lock has nothing to verify against, so it must not be locked out.
Future<bool> authenticateDevice() async {
  try {
    if (!await _auth.isDeviceSupported()) return true;
    return await _auth.authenticate(
      localizedReason: 'Unlock to continue',
      persistAcrossBackgrounding: true,
    );
  } on LocalAuthException catch (e) {
    return e.code == LocalAuthExceptionCode.noCredentialsSet;
  } on PlatformException {
    return false;
  }
}
