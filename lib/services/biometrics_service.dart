import "package:flutter/cupertino.dart";
import "package:local_auth/local_auth.dart";
import "package:local_auth_android/local_auth_android.dart";
import "package:local_auth_darwin/local_auth_darwin.dart";

class BiometricsService {
  static final BiometricsService _instance = ._internal();
  factory BiometricsService() => _instance;
  BiometricsService._internal();

  final _auth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    final List availableBiometrics = await _auth.getAvailableBiometrics();
    final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    return availableBiometrics.isNotEmpty && canAuthenticate;
  }

  Future<bool> authenticate() async {
    try {
      if (!await canAuthenticate()) return false;
      return await _auth.authenticate(
        localizedReason: "Veuillez vous authentifier per accéder à cette section",
        authMessages: const [
          AndroidAuthMessages(signInTitle: "Vérifiez votre identité", signInHint: " ", cancelButton: "Annuler"),
          IOSAuthMessages(cancelButton: "Annuler", localizedFallbackTitle: "Utiliser le code"),
        ],
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint("[Biometrics] Auth failed: $e");
      return false;
    }
  }
}
