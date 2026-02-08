import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class RegistrationPage extends StatefulWidget {
  final String? registrationTokenOverride;
  final bool passwordResetMode;
  final bool isResumingRegistration;

  const RegistrationPage({super.key, this.passwordResetMode = false, this.isResumingRegistration = false, this.registrationTokenOverride});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final secureStorage = FlutterSecureStorage();
  final registrationDataBox = Hive.box("RegistrationData");

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

  void sendEmail() async {
    startResendTimer();
    isWaitingForResponse = true;

    final response = await network.post("/auth/registration", {"EmailAddress": "${emailController.text.trim()}@eduvaud.ch"});

    isWaitingForResponse = false;

    final responseData = jsonDecode(response.body);
    final solutions = {
      "WrongFormat": "L'adresse e-mail doit respecter le format suivant : 'prénom.nom' !",
      "WrongDomain": "L'adresse doit terminer en '@eduvaud.ch' !",
      "WrongAddress": "Utilisez votre adresse nom.prénom@eduvaud.ch, pas pXNNXXX@eduvaud.ch",
      "AlreadyExists": "Cet adresse a déjà été utilisé !",
      "AlreadySent": "Veuillez patienter, le code a déjà été envoyé récemment !",
    };

    if (response.statusCode != 200) {
      emailError = solutions[responseData] ?? "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      registrationToken = jsonDecode(response.body)["RegistrationToken"];
      registrationDataBox.put("RegistrationToken", registrationToken);
      registrationDataBox.put("EmailAddress", emailController.text.trim());
      registrationDataBox.put("Page", 1);

      goToPage(1);
    }
  }

  void sendCode() async {
    isWaitingForResponse = true;

    final response = await network.post("/auth/registration", {"RegistrationToken": registrationToken, "VerificationCode": codeController.text.trim()});

    isWaitingForResponse = false;

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
      registrationDataBox.put("Page", 2);
      goToPage(2);
    }
  }

  void sendPassword() async {
    isWaitingForResponse = true;

    final response = await network.post("/auth/registration", {"RegistrationToken": registrationToken, "Password": passwordController.text.trim()});

    isWaitingForResponse = false;

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

      await Hive.box("Misc").put("Username", username);
      await registrationDataBox.clear();

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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacer(),
        Text("Adresse e-mail", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent), textAlign: TextAlign.center),
        SizedBox(height: 12),
        Text("Veuillez entrer votre adresse e-mail officiel du gymnase.", textAlign: TextAlign.center),
        Spacer(),

        CustomTextField(
          title: "Adresse e-mail",
          placeholder: "prénom.nom",
          error: emailError,
          controller: emailController,
          suffix: Padding(padding: EdgeInsets.only(right: 16), child: Text("@eduvaud.ch")),
          keyboardType: TextInputType.emailAddress,
          disabled: isWaitingForResponse,
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

        SizedBox(height: 6),

        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size.zero,
          onPressed: isEmailValid && !isWaitingForResponse ? () => sendEmail() : null,
          child:
              isWaitingForResponse
                  ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                  : Text("Envoyer le code de vérification"),
        ),

        Spacer(flex: 3),
      ],
    );
  }

  Widget codePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacer(),
        Text("Code de vérification", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent), textAlign: TextAlign.center),
        SizedBox(height: 12),
        Text("Veuillez entrer le code envoyé à l'adresse '${emailController.text}@eduvaud.ch'", textAlign: TextAlign.center),

        Spacer(),

        CustomTextField(
          title: "Code de vérification",
          placeholder: "- - - - - -",
          controller: codeController,
          error: codeError,
          keyboardType: TextInputType.number,
          disabled: isWaitingForResponse,
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

        SizedBox(height: 6),

        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          onPressed: isCodeValid && !isWaitingForResponse ? () => sendCode() : null,
          child: isWaitingForResponse ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14) : Text("Vérifier"),
        ),
        SizedBox(height: 10),
        CupertinoButton(
          onPressed: canResendCode && !isWaitingForResponse ? () => sendEmail() : null,
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Opacity(opacity: canResendCode ? 1 : .25, child: HugeIcon(icon: HugeIcons.strokeRoundedRefresh)),
              Text(canResendCode ? "Renvoyer le code" : "Renvoyer le code ${resendSecondsLeft}s"),
            ],
          ),
        ),
        if (!widget.passwordResetMode)
          CupertinoButton(
            onPressed: isWaitingForResponse ? null : () => goToPage(0),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Changer d'adresse e-mail"),
          ),

        Spacer(flex: 3),
      ],
    );
  }

  Widget passwordPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacer(),
        Text("Mot de passe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent), textAlign: TextAlign.center),
        SizedBox(height: 12),
        CustomText(
          "*Vérification réussite!*\n${widget.passwordResetMode ? "Entrez maintenant votre nouveau mot de passe. Ne l'oubliez pas cette fois !" : "Créez maintenant un mot de passe pour accéder à votre compte."}",
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),

        Spacer(),

        CustomTextField(
          title: "Mot de passe",
          placeholder: "••••••••••••••••",
          error: passwordError,
          controller: passwordController,
          keyboardType: TextInputType.visiblePassword,
          alwaysHidePassword: true,
          disabled: isWaitingForResponse,
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

        CustomTextField(
          title: "Confirmer le mot de passe",
          placeholder: "••••••••••••••••",
          error: confirmPasswordError,
          controller: confirmPasswordController,
          keyboardType: TextInputType.visiblePassword,
          disabled: isWaitingForResponse,
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

        SizedBox(height: 36),
        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size.zero,
          onPressed: (isPasswordValid && isConfirmPasswordValid && !isWaitingForResponse) ? () => sendPassword() : null,
          child: isWaitingForResponse ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14) : Text("Créer le compte"),
        ),

        Spacer(flex: 3),
      ],
    );
  }

  void askClosingConfirmation() {
    if (currentPage == 0 || widget.passwordResetMode) {
      // No need to ask if at page 1
      Navigator.pop(context);
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Annuler la création du compte"),
          content: Text("Voulez-vous vraiment annuler la création de votre compte? Cette action est irréversible."),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                registrationDataBox.clear();
              },
              child: Text("Oui"),
            ),
            CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text("Non")),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    emailController.value = TextEditingValue(text: registrationDataBox.get("EmailAddress", defaultValue: ""));

    if (widget.passwordResetMode || widget.isResumingRegistration) {
      setState(() => currentPage = registrationDataBox.get("Page", defaultValue: 1));

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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: GestureDetector(child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01), onTap: () => askClosingConfirmation()),
        middle: Text(widget.passwordResetMode ? "Changer de mot de passe" : "Création de compte"),
      ),
      child: SafeArea(
        minimum: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                if (!widget.passwordResetMode)
                  currentPage == 0 ? HugeIcon(icon: HugeIcons.strokeRoundedMailAdd01) : HugeIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
                currentPage == 1 ? HugeIcon(icon: HugeIcons.strokeRoundedSmsCode) : HugeIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
                currentPage == 2
                    ? HugeIcon(icon: HugeIcons.strokeRoundedPasswordValidation)
                    : HugeIcon(icon: HugeIcons.strokeRoundedCircle, strokeWidth: 4, size: 8),
              ],
            ),
            Expanded(
              child: PageView(
                clipBehavior: Clip.none,
                controller: pageController,
                physics: NeverScrollableScrollPhysics(),

                children: [if (!widget.passwordResetMode) emailPage(), codePage(), passwordPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
