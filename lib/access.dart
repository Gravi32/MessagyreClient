import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/overlays/registration.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
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
  bool isLoggingIn = false;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? usernameError, passwordError;

  late StreamSubscription onSignalConnection;

  void tryToLogin() {
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
      isLoggingIn = true;

      router.login(username, password);
    });
  }

  @override
  void initState() {
    super.initState();

    onSignalConnection = router.onSignalReceived.listen((signal) {
      if (signal.type != SignalType.Login) return;

      isLoggingIn = false;

      var response = signal.data["Response"];
      var field = signal.data["Field"];

      if (response == "success") {
        // (the Account is handled by the ConnectionController)

        if (mounted) {
          Navigator.pop(context);
        }
        onSignalConnection.cancel();
        return;
      }

      String? error;

      switch (response) {
        case "account_not_found":
          error = "Ce compte n'existe pas !";
          break;
        case "wrong_password":
          error = "Mot de passe incorrect !";
          break;
        default:
          error = "Une erreur s'est produite, veuillez reéssayer.";
      }

      setState(() {
        if (field == "username") {
          usernameError = error;
        }
        if (field == "password") {
          passwordError = error;
        }
      });
    });
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset("assets/icons/logo_purple.png", height: 100),

                      const SizedBox(height: 40),

                      CustomTextField(
                        title: "Nom d'utilisateur",
                        placeholder: "prénom.nom",
                        error: usernameError,
                        controller: usernameController,
                        disabled: isLoggingIn,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        title: "Mot de passe",
                        placeholder: "••••••••••••••••",
                        error: passwordError,
                        controller: passwordController,
                        disabled: isLoggingIn,
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 36),

                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minSize: 0,
                        onPressed: (!fieldsAreEmpty && !isLoggingIn)
                            ? tryToLogin
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isLoggingIn
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
                              color: CupertinoColors.systemGrey.withOpacity(.25),
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
                              color: CupertinoColors.systemGrey.withOpacity(.25),
                              indent: 10,
                              endIndent: 30,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: isLoggingIn
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => const RegistrationPage(),
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

    onSignalConnection.cancel();

    super.dispose();
  }
}
