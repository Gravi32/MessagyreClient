import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class RegistrationPage extends StatefulWidget {
  final String? registrationTokenOverride;
  final bool isInPasswordResetMode;
  final bool isResumingRegistration;

  const RegistrationPage({super.key, this.isInPasswordResetMode = false, this.isResumingRegistration = false, this.registrationTokenOverride});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final secureStorage = SecureStorageService();

  final pageController = PageController();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int currentPage = 0;
  String? registrationToken;

  bool isEmailValid = false;
  bool isCodeValid = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;

  String? emailError, codeError, passwordError, confirmPasswordError;

  int resendSecondsLeft = 60;
  bool canResendCode = false;
  Timer? resendTimer;

  bool isWaitingForResponse = false;

  void goToPage(int index) {
    setState(() => currentPage = index);
    pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void clearRegistrationCache() {
    globals.persistent
      ..remove("RegistrationToken")
      ..remove("EmailAddress")
      ..remove("Page");
  }

  void sendEmail() async {
    startResendTimer();

    setState(() => isWaitingForResponse = true);

    final response = await network.post("/auth/registration", {"EmailAddress": "${emailController.text.trim()}@eduvaud.ch"});

    setState(() => isWaitingForResponse = false);

    final responseData = jsonDecode(response.body);
    final solutions = {
      "WrongFormat": "L'adresse e-mail doit respecter le format suivant : '*prénom*.*nom*' !",
      "WrongDomain": "L'adresse doit terminer en '@*eduvaud.ch*' !",
      "WrongAddress": "Utilisez votre adresse '*prénom*.*nom*@eduvaud.ch'",
      "AlreadyExists": "Cette adresse a déjà été utilisée !",
      "AlreadySent": "Veuillez patienter, le code a déjà été envoyé récemment !",
    };

    if (response.statusCode != 200) {
      emailError = solutions[responseData] ?? "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      registrationToken = jsonDecode(response.body)["RegistrationToken"];

      globals.persistent
        ..setString("RegistrationToken", registrationToken ?? "")
        ..setString("EmailAddress", emailController.text.trim())
        ..setInt("Page", 1);

      goToPage(1);
    }
  }

  void sendCode() async {
    setState(() => isWaitingForResponse = true);

    final response = await network.post("/auth/registration", {"RegistrationToken": registrationToken, "VerificationCode": codeController.text.trim()});
    await Future.delayed(.new(seconds: 2));

    setState(() => isWaitingForResponse = false);

    var responseData = "";
    final solutions = {"WrongLength": "Le code doit contenir 6 chiffres.", "WrongCode": "Le code est incorrect !"};

    try {
      responseData = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 401) {
      goToPage(0);
    } else if (response.statusCode != 200) {
      codeError = solutions[responseData] ?? "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      globals.persistent.setInt("Page", 2);
      goToPage(2);
    }
  }

  void sendPassword() async {
    setState(() => isWaitingForResponse = true);

    final response = await network.post("/auth/registration", {"RegistrationToken": registrationToken, "Password": passwordController.text.trim()});

    setState(() => isWaitingForResponse = false);

    final responseData = jsonDecode(response.body);
    final solutions = {"TooShort": "Le mot de passe doit contenir au moins 8 caractères."};

    if (response.statusCode == 401) {
      goToPage(0);
    } else if (response.statusCode != 200) {
      codeError = solutions[responseData] ?? "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      final accessToken = responseData["AccessToken"];
      final refreshToken = responseData["RefreshToken"];
      final username = responseData["Username"];

      globals.token = accessToken;
      globals.username = username;
      isWaitingForResponse = true;

      await secureStorage.write(key: "AccessToken", value: accessToken);
      await secureStorage.write(key: "RefreshToken", value: refreshToken);

      await globals.persistent.setString("Username", username);
      clearRegistrationCache();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      isWaitingForResponse = false;

      network.isLoginPageOpen = false;
      network.connect();
    }
  }

  void startResendTimer() {
    setState(() {
      canResendCode = false;
      resendSecondsLeft = 120;
    });

    resendTimer?.cancel();
    resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        resendSecondsLeft--;
        if (resendSecondsLeft <= 0) {
          canResendCode = true;
          timer.cancel();
        }
      });
    });
  }

  Widget emailPage() {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      children: [
        Spacer(flex: 3),
        Text(
          "Adresse e-mail",
          style: AppStyles.header(context).copyWith(color: AppColors.accent),
          textAlign: .center,
        ),
        SizedBox(height: 12),
        CustomText("Veuillez entrer *votre adresse e-mail officiel*.", textAlign: .center, padding: .symmetric(horizontal: 20)),
        Spacer(),

        Field(
          placeholder: "prénom.nom",
          suffix: "@eduvaud.ch",
          error: emailError,
          controller: emailController,
          keyboardType: .emailAddress,
          enabled: !isWaitingForResponse,
          onChanged: (input) {
            final selection = emailController.selection;
            final newText = input.trim().toLowerCase();

            final isValid = RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%-]*[a-zA-Z0-9])?$').hasMatch(newText);

            setState(() {
              isEmailValid = isValid;
              emailError = null;

              if (newText != emailController.text) {
                emailController.value = TextEditingValue(text: newText, selection: selection);
              }
            });
          },
        ),
        Spacer(),

        CustomText(
          "Messagyre *vous envoyera un code de vérification* par e-mail pour confirmer votre identité.",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
          style: AppStyles.tertiaryText(context),
        ),

        Spacer(flex: 4),

        Button(
          enabled: isEmailValid && !isWaitingForResponse,
          onTap: () => sendEmail(),
          isLoading: isWaitingForResponse,
          text: "Envoyer le code de vérification",
        ),
      ],
    );
  }

  Widget codePage() {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      children: [
        Spacer(flex: 3),
        Text(
          "Code de vérification",
          style: AppStyles.header(context).copyWith(color: AppColors.accent),
          textAlign: .center,
        ),
        SizedBox(height: 12),

        CustomText(
          "Veuillez entrer le *code envoyé* à l'adresse '*${emailController.text}@eduvaud.ch*'",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
        ),

        Spacer(),

        Field(
          placeholder: "------",
          controller: codeController,
          error: codeError,
          keyboardType: .number,
          enabled: !isWaitingForResponse,
          textStyle: .new(letterSpacing: 4, fontSize: 24),
          onChanged: (input) {
            final selection = codeController.selection;
            final newText = input.trim();

            setState(() {
              isCodeValid = newText.length == 6;
              codeError = null;

              if (newText != codeController.text) {
                codeController.value = TextEditingValue(text: newText, selection: selection);
              }
            });
          },
        ),

        Spacer(flex: 5),

        Column(
          spacing: 10,
          children: [
            Button(enabled: isCodeValid && !isWaitingForResponse, onTap: () => sendCode(), isLoading: isWaitingForResponse, text: "Vérifier"),

            Button(
              enabled: canResendCode && !isWaitingForResponse,
              onTap: () => sendEmail(),
              transparent: true,
              text: canResendCode ? "Renvoyer le code" : "Renvoyer le code ${resendSecondsLeft}s",
            ),

            if (!widget.isInPasswordResetMode)
              Button(
                enabled: !isWaitingForResponse,
                onTap: () => goToPage(0),
                transparent: true,
                color: AppColors.secondaryButton.adaptTo(context),
                text: "Changer d'adresse e-mail",
              ),
          ],
        ),
      ],
    );
  }

  Widget passwordPage() {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      children: [
        Spacer(),
        Text(
          "Mot de passe",
          style: AppStyles.header(context).copyWith(color: AppColors.accent),
          textAlign: .center,
        ),
        SizedBox(height: 12),
        CustomText(
          "*Vérification réussie!*\n${widget.isInPasswordResetMode ? "Entrez votre *nouveau mot de passe*. *Ne l'oubliez pas cette fois* !" : "*Créez un nouveau mot de passe* pour accéder à votre compte. Ne l'oubliez pas !"}",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
        ),

        Spacer(),

        Field.password(
          error: passwordError,
          controller: passwordController,
          alwaysHidePassword: true,
          enabled: !isWaitingForResponse,
          onChanged: (input) {
            final selection = passwordController.selection;
            final newText = input.trim();

            setState(() {
              isPasswordValid = newText.length >= 8;
              passwordError = null;

              if (newText != passwordController.text) {
                passwordController.value = TextEditingValue(text: newText, selection: selection);
              }
            });
          },
        ),

        SizedBox(height: 20),

        Field.password(
          error: confirmPasswordError,
          controller: confirmPasswordController,
          enabled: !isWaitingForResponse,
          isConfirmPassword: true,
          onChanged: (input) {
            final selection = confirmPasswordController.selection;
            final newText = input.trim();

            setState(() {
              isConfirmPasswordValid = passwordController.text == newText;
              confirmPasswordError = null;

              if (newText != confirmPasswordController.text) {
                confirmPasswordController.value = TextEditingValue(text: newText, selection: selection);
              }
            });
          },
        ),

        Spacer(flex: 4),

        Button(
          enabled: !isWaitingForResponse,
          onTap: () => sendPassword(),
          isLoading: isWaitingForResponse,
          text: widget.isInPasswordResetMode ? "Accéder au compte" : "Créer le compte",
        ),
      ],
    );
  }

  void askClosingConfirmation() {
    if (currentPage == 0 || widget.isInPasswordResetMode) {
      // No need to ask if at page 1
      Navigator.pop(context);
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Dialog.confirm(
          content: "Voulez-vous vraiment *annuler la création de votre compte*? Cette action est irréversible.",
          isDestructive: true,
          onConfirm: () {
            clearRegistrationCache();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  void initState() {
    emailController.value = TextEditingValue(text: globals.persistent.getString("EmailAddress") ?? "");

    if (widget.isInPasswordResetMode || widget.isResumingRegistration) {
      setState(() => currentPage = globals.persistent.getInt("Page") ?? 1);

      startResendTimer();
      registrationToken = widget.registrationTokenOverride;

      if (widget.isResumingRegistration) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToPage(currentPage);
        });
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      navigationBar: TopBar.form(
        context,
        title: widget.isInPasswordResetMode ? "Changer de mot de passe" : "Création d'un compte",
        onPop: () => Navigator.pop(context),
        onCloseConfirmed: currentPage != 0
            ? () {
                clearRegistrationCache();
                Navigator.pop(context);
              }
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: 20,
            children: [
              if (!widget.isInPasswordResetMode)
                currentPage == 0
                    ? CustomIcon(icon: HugeIcons.strokeRoundedMailAdd01)
                    : CustomIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
              currentPage == 1 ? CustomIcon(icon: HugeIcons.strokeRoundedSmsCode) : CustomIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
              currentPage == 2
                  ? CustomIcon(icon: HugeIcons.strokeRoundedPasswordValidation)
                  : CustomIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
            ],
          ),
          Expanded(
            child: PageView(
              clipBehavior: .none,
              controller: pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [if (!widget.isInPasswordResetMode) emailPage(), codePage(), passwordPage()],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
