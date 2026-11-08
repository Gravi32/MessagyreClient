import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/pages/bootstrap/registration_page.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/made_by_gravi.dart';
import 'package:messagyre_client/utility/utility.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final network = NetworkService();
  final globals = GlobalsService();
  final secureStorage = SecureStorageService();

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
      usernameError = !username.contains('.') ? "Le nom d'utilisateur doit contenir un point '.'" : null;
      passwordError = password.length < 8 ? "Le mot de passe doit contenir au moins 8 caractères." : null;
      wasPasswordWrong = false;
    });
    if (usernameError != null || passwordError != null) return;

    // Sending the request to the server
    debugPrint("[Access] Logging in as $username...");
    setState(() => isWaitingForResponse = true);

    var response = await network.post("/auth/login", {"Username": username, "Password": password});

    setState(() => isWaitingForResponse = false);

    try {
      // A refusal is sometimes plain text ("Internal error" without connection): it is shown, not decoded
      final responseData = tryJsonDecode(response.body);
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
              usernameError = AppStrings.errorFor(response);
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
      setState(() => usernameError = "La réponse du serveur est illisible ($e). Réessayez dans un instant.");
      return;
    }

    debugPrint("[Login successful] Token received and stored.");

    // The app starts again with the new account (this page closes with it)
    network.didSignIn();
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
    ).push(CupertinoPageRoute(builder: (context) => RegistrationPage(isInPasswordResetMode: true, registrationTokenOverride: registrationToken)));
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

    return Page.scrollable(
      context,
      canPop: false,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const Center(child: AppIconTile(size: 76)),
        const SizedBox(height: AppSpacing.xl),
        Text("Bienvenue sur Messagyre", textAlign: .center, style: AppStyles.header(context)),
        const SizedBox(height: AppSpacing.s),
        Text("Connectez-vous pour continuer", textAlign: .center, style: AppStyles.subheadline(context)),

        const SizedBox(height: AppSpacing.xxl),
        Field(
          placeholder: "Nom d'utilisateur",
          error: usernameError,
          controller: usernameController,
          enabled: !isWaitingForResponse,
          onSubmitted: (newText) {
            usernameController.value = TextEditingValue(text: newText.toLowerCase().replaceAll(' ', '').split('@')[0], selection: usernameController.selection);
          },
        ),
        const SizedBox(height: AppSpacing.m),
        Field.password(error: passwordError, controller: passwordController, enabled: !isWaitingForResponse, onChanged: (_) => setState(() {})),

        const SizedBox(height: AppSpacing.xl),
        Button(text: "Connexion", enabled: !fieldsAreEmpty && !isWaitingForResponse, isLoading: isWaitingForResponse, onTap: tryToLogin),

        if (wasPasswordWrong && usernameController.text.isNotEmpty)
          CupertinoButton(
            padding: const .only(top: AppSpacing.l),
            minimumSize: .zero,
            onPressed: !isWaitingForResponse ? tryToResetPassword : null,
            child: Text(
              "Mot de passe oublié ?",
              style: AppStyles.subheadline(context).copyWith(color: AppColors.tint.adaptTo(context), fontWeight: .w500),
            ),
          ),

        const SizedBox(height: AppSpacing.xxl),
        // An account of the app, not of the school
        Container(
          padding: const .all(AppSpacing.l),
          decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(AppRadius.m)),
          child: Row(
            crossAxisAlignment: .start,
            spacing: AppSpacing.m,
            children: [
              AppIcon(icon: AppIcons.info, size: 20, color: AppColors.secondaryText.adaptTo(context)),
              Expanded(
                child: Text(
                  "Votre compte Messagyre n'est pas celui du gymnase : créez-en un si ce n'est pas déjà fait.",
                  style: AppStyles.footnote(context).copyWith(color: AppColors.secondaryText.adaptTo(context), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Button(
          text: "Créer un compte",
          transparent: true,
          color: AppColors.secondaryButton.adaptTo(context),
          enabled: !isWaitingForResponse,
          onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => RegistrationPage())),
        ),

        const SizedBox(height: AppSpacing.xxl),
        const MadeByGravi(),
      ],
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
