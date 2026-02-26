import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/pages/bootstrap/registration_page.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final network = NetworkService();
  final globals = GlobalsService();
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
    if (usernameError != null || passwordError != null) return;

    // Sending the request to the server
    debugPrint("[Access] Logging in as $username...");
    setState(() => isWaitingForResponse = true);

    var response = await network.post("/auth/login", {"Username": username, "Password": password});

    setState(() => isWaitingForResponse = false);

    try {
      final responseData = jsonDecode(response.body);
      // Handling failure
      if (response.statusCode != 200) {
        debugPrint("[Login failed] Error ${response.statusCode}: $responseData");

        setState(() {
          switch (responseData) {
            case "NotFound":
              usernameError = "Ce compte n'existe pas ! Créez-le en appuyant sur \"Créer un compte\".";
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
      globals.token = accessToken;
      globals.username = username;

      await secureStorage.write(key: "AccessToken", value: accessToken);
      await secureStorage.write(key: "RefreshToken", value: refreshToken);

      await globals.persistent.setString("Username", username);
    } catch (e, s) {
      debugPrint("[Access] Error decoding response: '$e'. Stack trace: $s");
    }

    // Connecting to the WebSocket
    network.isLoginPageOpen = false;
    network.connect();

    // Closing the page
    debugPrint("[Login successful] Token received and stored.");

    if (mounted) Navigator.of(context).pop();
  }

  void tryToResetPassword() async {
    isWaitingForResponse = true;

    final response = await network.post("/auth/registration", {"PasswordResetUsername": usernameController.value.text});

    isWaitingForResponse = false;

    if (response.statusCode != 200) {
      debugPrint("[Access] Password reset failed (${response.statusCode}): ${response.body}");
      return;
    }

    String? registrationToken;
    try {
      registrationToken = jsonDecode(response.body)["RegistrationToken"];
    } catch (_) {}

    final mountedContext = context;
    if (!context.mounted) return;
    Navigator.of(
      mountedContext,
    ).push(CupertinoPageRoute(builder: (context) => RegistrationPage(passwordResetMode: true, registrationTokenOverride: registrationToken)));
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
        decoration: BoxDecoration(color: AppColors.background.adaptTo(context)),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "connectez-vous pour continuer",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.secondaryText.adaptTo(context)),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Attention: Les comptes de Messagyre ne sont pas liés au gymnase ! Vous devez créer un compte à part si vous ne l'avez pas déjà fait !",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.tertiaryText.adaptTo(context)),
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
                              ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                              : const Text("Connexion"),
                        ],
                      ),
                    ),
                    if (wasPasswordWrong) ...[
                      const SizedBox(height: 10),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: Size.zero,
                        onPressed: (!isWaitingForResponse) ? tryToResetPassword : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isWaitingForResponse
                                ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                                : const Text("J'ai oublié mon mot de passe..."),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.separator.adaptTo(context), indent: 30, endIndent: 10)),
                        Text("ou", style: TextStyle(color: AppColors.separator.adaptTo(context).withAlpha(100), fontSize: 12)),
                        Expanded(child: Divider(color: AppColors.separator.adaptTo(context), indent: 10, endIndent: 30)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed:
                          isWaitingForResponse
                              ? null
                              : () async {
                                Navigator.of(context).push(CupertinoPageRoute(builder: (context) => RegistrationPage()));
                              },
                      child: const Text("Créer un compte", style: TextStyle(color: AppColors.white)),
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

  void resumeIfNeeded() async {
    final storedRegistrationToken = globals.persistent.getString("RegistrationToken");
    final isResumingRegistration = storedRegistrationToken != null;
    final mountedContext = context;

    if (!context.mounted || !isResumingRegistration) return;

    Navigator.of(mountedContext).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => RegistrationPage(isResumingRegistration: isResumingRegistration, registrationTokenOverride: storedRegistrationToken),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    resumeIfNeeded();
  }
}
