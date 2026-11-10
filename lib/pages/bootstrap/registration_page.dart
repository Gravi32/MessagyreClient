import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';

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

    final responseData = tryJsonDecode(response.body);
    final solutions = {
      "WrongFormat": "L'adresse e-mail doit avoir la forme « *prénom*.*nom* » !",
      "WrongDomain": "L'adresse doit se terminer par « @*eduvaud.ch* » !",
      "WrongAddress": "Utilisez votre adresse « *prénom*.*nom*@eduvaud.ch »",
      "AlreadyExists": "Cette adresse a déjà été utilisée !",
      "AlreadySent": "Veuillez patienter, le code a déjà été envoyé récemment !",
    };

    if (response.statusCode != 200) {
      emailError = solutions[responseData] ?? AppStrings.errorFor(response);
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
      codeError = solutions[responseData] ?? AppStrings.errorFor(response);
    } else {
      globals.persistent.setInt("Page", 2);
      goToPage(2);
    }
  }

  void sendPassword() async {
    setState(() => isWaitingForResponse = true);

    final response = await network.post("/auth/registration", {"RegistrationToken": registrationToken, "Password": passwordController.text.trim()});

    setState(() => isWaitingForResponse = false);

    final responseData = tryJsonDecode(response.body);
    final solutions = {"TooShort": "Le mot de passe doit contenir au moins 8 caractères."};

    if (response.statusCode == 401) {
      goToPage(0);
    } else if (response.statusCode != 200) {
      codeError = solutions[responseData] ?? AppStrings.errorFor(response);
    } else {
      final accessToken = responseData["AccessToken"];
      final refreshToken = responseData["RefreshToken"];
      final username = responseData["Username"];

      setState(() => isWaitingForResponse = true);
      clearRegistrationCache();

      // The app starts again with the new account (the login and registration pages close with it)
      await network.signIn(accessToken: accessToken, refreshToken: refreshToken, username: username);
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

  /// The top of a step: its icon in a grey circle and its title
  Widget stepTitle(List<List<dynamic>> icon, String title) => Column(
    spacing: AppSpacing.l,
    children: [
      Container(
        width: 64,
        height: 64,
        alignment: .center,
        decoration: BoxDecoration(shape: .circle, color: AppColors.tertiaryBackground.adaptTo(context)),
        child: AppIcon(icon: icon, size: 28, color: AppColors.text.adaptTo(context)),
      ),
      Padding(
        padding: const .only(bottom: AppSpacing.s),
        child: Text(title, style: AppStyles.header(context), textAlign: .center),
      ),
    ],
  );

  Widget emailPage() {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      children: [
        Spacer(flex: 3),
        stepTitle(HugeIcons.strokeRoundedMail01, "Adresse e-mail"),
        CustomText("Entrez *votre adresse e-mail du gymnase*.", textAlign: .center, padding: .symmetric(horizontal: 20), style: AppStyles.subheadline(context)),
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
          "Messagyre *vous enverra un code* par e-mail pour confirmer que c'est bien vous.",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
          style: AppStyles.footnote(context),
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
        stepTitle(HugeIcons.strokeRoundedSmsCode, "Code de vérification"),

        CustomText(
          "Entrez le *code envoyé* à *${emailController.text}@eduvaud.ch*.",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
          style: AppStyles.subheadline(context),
        ),

        Spacer(),

        Field(
          placeholder: "------",
          controller: codeController,
          error: codeError,
          keyboardType: .number,
          enabled: !isWaitingForResponse,
          textStyle: .new(letterSpacing: 8, fontSize: AppStyles.sizeTitle, fontWeight: .w600),
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
          spacing: AppSpacing.s,
          children: [
            Button(enabled: isCodeValid && !isWaitingForResponse, onTap: () => sendCode(), isLoading: isWaitingForResponse, text: "Vérifier"),

            Button(
              enabled: canResendCode && !isWaitingForResponse,
              onTap: () => sendEmail(),
              transparent: true,
              color: AppColors.secondaryButton.adaptTo(context),
              text: canResendCode ? "Renvoyer le code" : "Renvoyer le code ${resendSecondsLeft}s",
            ),

            if (!widget.isInPasswordResetMode)
              Button(
                enabled: !isWaitingForResponse,
                onTap: () => goToPage(0),
                transparent: true,
                color: AppColors.transparent,
                textColor: AppColors.secondaryText.adaptTo(context),
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
        stepTitle(HugeIcons.strokeRoundedSquareLock02, "Mot de passe"),
        CustomText(
          "*Vérification réussie !*\n${widget.isInPasswordResetMode ? "Entrez votre *nouveau mot de passe*. *Ne l'oubliez pas cette fois* !" : "*Créez un nouveau mot de passe* pour accéder à votre compte. Ne l'oubliez pas !"}",
          textAlign: .center,
          padding: .symmetric(horizontal: 20),
          style: AppStyles.subheadline(context),
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

        SizedBox(height: AppSpacing.m),

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
          content: "Voulez-vous vraiment *annuler la création de votre compte* ? Cette action est irréversible.",
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
      topBar: TopBar.form(
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
          // The steps, as bars filling up
          Padding(
            padding: const .symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.s),
            child: Row(
              spacing: AppSpacing.s - 2,
              children: [
                for (var step = widget.isInPasswordResetMode ? 1 : 0; step < 3; step++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: .circular(2),
                        color: step <= currentPage ? AppColors.text.adaptTo(context) : AppColors.tertiaryBackground.adaptTo(context),
                      ),
                    ),
                  ),
              ],
            ),
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
