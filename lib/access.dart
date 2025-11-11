import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/overlays/registration.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class AccessOverlay extends StatefulWidget {
  const AccessOverlay({super.key});

  @override
  State<StatefulWidget> createState() => _AccessOverlayState();
}

class _AccessOverlayState extends State<AccessOverlay> with WidgetsBindingObserver {
  final router = ConnectionController();
  final data = Data();
  final secureStorage = FlutterSecureStorage();

  bool isPasswordHidden = true;
  bool isWaitingForResponse = false;
  bool wasPasswordWrong = false;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? usernameError, passwordError;

  void tryToLogin() async {
    // Checking data validity locally
    final username = usernameController.text;
    final password = passwordController.text;

    setState(() {
      if (!username.contains('.')) {
        usernameError = "Le nom d'utilisateur doit contenir un point '.'";
        return;
      }

      if (password.length < 8) {
        passwordError = "Le mot de passe doit contenir au moins 8 caractères.";
        return;
      }

      usernameError = passwordError = null;
      wasPasswordWrong = false;
    });

    // Sending the request to the server
    debugPrint("[Access] Logging in as $username...");
    setState(() => isWaitingForResponse = true);

    var response = await router.post("/Auth/Login", {"Username": username, "Password": password});

    setState(() => isWaitingForResponse = false);

    try {
      final responseData = jsonDecode(response.body);
      // Handling failure
      if (response.statusCode != 200) {
        debugPrint("[Login failed] Error ${response.statusCode}: $responseData");

        setState(() {
          switch (responseData) {
            case "NotFound":
              usernameError = "Ce compte n'existe pas !";
              break;
            case "WrongPassword":
              passwordError = "Mot de passe incorrect !";
              wasPasswordWrong = true;
              break;
            default:
              usernameError = "Une erreur s'est produite, veuillez reéssayer.";
              break;
          }
        });

        return;
      }

      // Saving the received AccessToken
      final accessToken = responseData["AccessToken"];
      final refreshToken = responseData["RefreshToken"];
      data.token = accessToken;
      data.username = username;
      await secureStorage.write(key: "AccessToken", value: accessToken);
      await secureStorage.write(key: "RefreshToken", value: refreshToken);
      await Hive.box("Misc").put("Username", username);
    } catch (e, s) {
      debugPrint("[Access] Error decoding response: '$e'. Stack trace: $s");
    }

    // Connecting to the WebSocket
    router.connect();

    // Closing the page
    debugPrint("[Login successful] Token received and stored.");
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAreEmpty = usernameController.text.isEmpty || passwordController.text.isEmpty;

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context)),
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset("assets/icons/purple.png", height: 100),
                    const SizedBox(height: 10),
                    Text(
                      "Bienvenue sur Messagyre",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: CupertinoColors.label.resolveFrom(context)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "connectez-vous pour continuer",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: CupertinoColors.label.resolveFrom(context).withOpacity(.7)),
                    ),
                    const SizedBox(height: 40),
                    CustomTextField(
                      title: "Nom d'utilisateur",
                      placeholder: "prénom.nom",
                      error: usernameError,
                      controller: usernameController,
                      disabled: isWaitingForResponse,
                      onChanged: (_) {
                        final selection = usernameController.selection;
                        final newText = usernameController.text.toLowerCase().replaceAll(' ', '');

                        if (newText != usernameController.text) {
                          usernameController.value = TextEditingValue(text: newText, selection: selection);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      title: "Mot de passe",
                      placeholder: "••••••••••••••••",
                      error: passwordError,
                      controller: passwordController,
                      disabled: isWaitingForResponse,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 36),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: Size.zero,
                      onPressed: (!fieldsAreEmpty && !isWaitingForResponse) ? tryToLogin : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isWaitingForResponse
                              ? LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14)
                              : const Text("Connexion"),
                        ],
                      ),
                    ),
                    if (wasPasswordWrong) ...[
                      const SizedBox(height: 10),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: Size.zero,
                        onPressed: (!isWaitingForResponse) ? tryToLogin : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isWaitingForResponse
                                ? LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14)
                                : const Text("J'ai oublié mon mot de passe"),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(child: Divider(color: CupertinoColors.systemGrey.withOpacity(.25), indent: 30, endIndent: 10)),
                        const Text("ou", style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
                        Expanded(child: Divider(color: CupertinoColors.systemGrey.withOpacity(.25), indent: 10, endIndent: 30)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed:
                          isWaitingForResponse
                              ? null
                              : () {
                                Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const RegistrationPage()));
                              },
                      child: const Text("Créer un compte", style: TextStyle(color: CupertinoColors.white)),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
