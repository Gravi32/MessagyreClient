import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/overlays/registration.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class AccessOverlay extends StatefulWidget {
  const AccessOverlay({super.key});

  @override
  State<StatefulWidget> createState() => _AccessOverlayState();
}

class _AccessOverlayState extends State<AccessOverlay> {
  final router = ConnectionController();
  final data = Data();

  bool isPasswordHidden = true;
  ValueNotifier<bool> isWaitingForResponse = ValueNotifier(false);

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
    });

    // Sending the request to the server
    debugPrint("[Access] Logging in as $username...");
    isWaitingForResponse.value = true;

    var response = await router.post("/Auth/Login", {
      "Username": username,
      "Password": password,
    }, handleUnauthorized: false);

    isWaitingForResponse.value = false;
    final responseData = jsonDecode(response.body);

    // Handling failure
    if (response.statusCode != 200) {
      debugPrint("[Login failed] Error ${response.statusCode}: $responseData");

      setState(() {
        switch (responseData) {
          case "NotFound":
            usernameError = "Ce compte n'existe pas !";
          case "WrongPassword":
            passwordError = "Mot de passe incorrect !";
          default:
            usernameError = "Une erreur s'est produite, veuillez reéssayer.";
        }
      });

      return;
    }

    // Saving the received AccessToken
    final token = responseData["AccessToken"];
    data.token = token;
    data.username = username;
    await FlutterSecureStorage().write(key: "AccessToken", value: token);
    await Hive.box("Misc").put("Username", username);

    // Closing the page
    if (mounted) Navigator.of(context).pop();
    debugPrint(
      "[Login successful] Token received and stored. (${token.toString()}...)",
    );

    // Connecting to the WebSocket
    router.connect();
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAreEmpty =
        usernameController.text.isEmpty || passwordController.text.isEmpty;

    return CupertinoPageScaffold(
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: ValueListenableBuilder(
                    valueListenable: isWaitingForResponse,
                    builder:
                        (context, isDisabled, _) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.asset(
                              "assets/icons/logo_purple.png",
                              height: 100,
                            ),

                            const SizedBox(height: 40),

                            CustomTextField(
                              title: "Nom d'utilisateur",
                              placeholder: "prénom.nom",
                              error: usernameError,
                              controller: usernameController,
                              disabled: isDisabled,
                              onChanged:
                                  (_) => setState(() {
                                    usernameController.text = usernameController
                                        .text
                                        .toLowerCase()
                                        .replaceAll(' ', '');
                                  }),
                            ),

                            const SizedBox(height: 20),

                            CustomTextField(
                              title: "Mot de passe",
                              placeholder: "••••••••••••••••",
                              error: passwordError,
                              controller: passwordController,
                              disabled: isDisabled,
                              keyboardType: TextInputType.visiblePassword,
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 36),

                            CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minSize: 0,
                              onPressed:
                                  (!fieldsAreEmpty && !isDisabled)
                                      ? tryToLogin
                                      : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isDisabled
                                      ? const CupertinoActivityIndicator()
                                      : const Text("Accéder"),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(.25),
                                    indent: 30,
                                    endIndent: 10,
                                  ),
                                ),
                                const Text(
                                  "ou",
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(.25),
                                    indent: 10,
                                    endIndent: 30,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onPressed:
                                  isDisabled
                                      ? null
                                      : () {
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder:
                                                (context) =>
                                                    const RegistrationPage(),
                                          ),
                                        );
                                      },
                              child: const Text(
                                "Créer un compte",
                                style: TextStyle(color: CupertinoColors.white),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}
