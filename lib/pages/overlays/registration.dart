import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final router = ConnectionController();
  final data = Data();

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
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void sendEmail() async {
    startResendTimer();
    isWaitingForResponse = true;

    final response = await router.post("/Auth/Registration", {
      "EmailAddress": "${emailController.text.trim()}@eduvaud.ch",
    });

    isWaitingForResponse = false;

    final responseData = jsonDecode(response.body);
    final solutions = {
      "WrongFormat":
          "L'adresse e-mail doit respecter le format suivant : 'prénom.nom' !",
      "WrongDomain": "L'adresse doit terminer en '@eduvaud.ch' !",
      "AlreadyExists": "Cet adresse a déjà été utilisé !",
      "AlreadySent":
          "Veuillez patienter, le code a déjà été envoyé récemment !",
    };

    if (response.statusCode != 200) {
      emailError =
          solutions[responseData] ??
          "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      registrationToken = jsonDecode(response.body)["RegistrationToken"];
      goToPage(1);
    }
  }

  void sendCode() async {
    isWaitingForResponse = true;

    final response = await router.post("/Auth/Registration", {
      "RegistrationToken": registrationToken,
      "VerificationCode": codeController.text.trim(),
    });

    isWaitingForResponse = false;

    var responseData = "";
    final solutions = {
      "WrongLength": "Le code doit contenir 6 chiffres.",
      "WrongCode": "Le code est incorrect !",
    };

    try {
      responseData = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 401) {
      goToPage(0);
    } else if (response.statusCode != 200) {
      codeError =
          solutions[responseData] ??
          "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      goToPage(2);
    }
  }

  void sendPassword() async {
    isWaitingForResponse = true;

    final response = await router.post("/Auth/Registration", {
      "RegistrationToken": registrationToken,
      "Password": passwordController.text.trim(),
    });

    isWaitingForResponse = false;

    final responseData = jsonDecode(response.body);
    final solutions = {
      "TooShort": "Le mot de passe doit contenir au moins 8 caractères.",
    };

    if (response.statusCode == 401) {
      goToPage(0);
    } else if (response.statusCode != 200) {
      codeError =
          solutions[responseData] ??
          "Une erreur s'est produite, veuillez reéssayer.";
    } else {
      final accessToken = responseData["AccessToken"];
      final refreshToken = responseData["RefreshToken"];
      final username = responseData["Username"];

      data.token = accessToken;
      data.username = username;
      isWaitingForResponse = true;

      await FlutterSecureStorage().write(
        key: "AccessToken",
        value: accessToken,
      );
      await FlutterSecureStorage().write(
        key: "RefreshToken",
        value: refreshToken,
      );
      await Hive.box("Misc").put("Username", username);

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      isWaitingForResponse = false;
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
        Text(
          "Adresse e-mail",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CupertinoTheme.of(context).primaryColor.withBrightness(.075),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "veuillez entrer votre adresse e-mail officiel du gymnase.",
          textAlign: TextAlign.center,
        ),
        Spacer(),

        CustomTextField(
          title: "Adresse e-mail",
          placeholder: "prénom.nom",
          error: emailError,
          controller: emailController,
          suffix: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text("@eduvaud.ch"),
          ),
          keyboardType: TextInputType.emailAddress,
          disabled: isWaitingForResponse,
          onChanged: (input) {
            setState(() {
              isEmailValid = RegExp(
                r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%-]*[a-zA-Z0-9])?$',
              ).hasMatch(input);
              emailError = null;
              emailController.text = input.trim();
            });
          },
        ),

        SizedBox(height: 6),

        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size.zero,
          onPressed:
              isEmailValid && !isWaitingForResponse ? () => sendEmail() : null,
          child:
              isWaitingForResponse
                  ? CupertinoActivityIndicator()
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
        Text(
          "Code de vérification",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CupertinoTheme.of(context).primaryColor.withBrightness(.075),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "veuillez entrer le code envoyé à l'adresse '${emailController.text}@eduvaud.ch'",
          textAlign: TextAlign.center,
        ),

        Spacer(),

        CustomTextField(
          title: "Code de vérification",
          placeholder: "- - - - - -",
          controller: codeController,
          error: codeError,
          keyboardType: TextInputType.number,
          disabled: isWaitingForResponse,
          onChanged: (input) {
            setState(() {
              isCodeValid = input.length == 6;
              codeError = null;
              codeController.text = input.trim();
            });
          },
        ),

        SizedBox(height: 6),

        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          onPressed:
              isCodeValid && !isWaitingForResponse ? () => sendCode() : null,
          child:
              isWaitingForResponse
                  ? CupertinoActivityIndicator()
                  : Text("Vérifier"),
        ),
        SizedBox(height: 10),
        CupertinoButton(
          onPressed:
              canResendCode && !isWaitingForResponse ? () => sendEmail() : null,
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
              Text(
                canResendCode
                    ? "Renvoyer le code"
                    : "Renvoyer le code ${resendSecondsLeft}s",
              ),
            ],
          ),
        ),
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
        Text(
          "Mot de passe",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CupertinoTheme.of(context).primaryColor.withBrightness(.075),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "vérification réussite!\ncréez maintenant un mot de passe pour accéder à votre compte.",
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
            setState(() {
              isPasswordValid = input.length >= 8;
              passwordError = null;
              passwordController.text = input.trim();
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
            setState(() {
              isConfirmPasswordValid = passwordController.text == input;
              confirmPasswordError = null;
              confirmPasswordController.text = input.trim();
            });
          },
        ),

        SizedBox(height: 36),
        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size.zero,
          onPressed:
              (isPasswordValid &&
                      isConfirmPasswordValid &&
                      !isWaitingForResponse)
                  ? () => sendPassword()
                  : null,
          child:
              isWaitingForResponse
                  ? CupertinoActivityIndicator()
                  : Text("Créer le compte"),
        ),

        Spacer(flex: 3),
      ],
    );
  }

  void askClosingConfirmation() {
    if (currentPage == 0) {
      // No need to ask if at page 1
      Navigator.pop(context);
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Annuler la création du compte"),
          content: Text(
            "Voulez-vous vraiment annuler la création de votre compte? Cette action est irréversible.",
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text("Oui"),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Non"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: GestureDetector(
          child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
          onTap: () => askClosingConfirmation(),
        ),
        middle: Text("Création de compte"),
      ),
      child: SafeArea(
        minimum: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                currentPage == 0
                    ? HugeIcon(icon: HugeIcons.strokeRoundedMailAdd01)
                    : HugeIcon(icon: HugeIcons.strokeRoundedCircle, size: 8),
                currentPage == 1
                    ? HugeIcon(icon: HugeIcons.strokeRoundedSmsCode)
                    : HugeIcon(icon: HugeIcons.strokeRoundedCircle, size: 8),
                currentPage == 2
                    ? HugeIcon(icon: HugeIcons.strokeRoundedPasswordValidation)
                    : HugeIcon(icon: HugeIcons.strokeRoundedCircle, size: 8),
              ],
            ),
            Expanded(
              child: PageView(
                clipBehavior: Clip.none,
                controller: pageController,
                physics:
                    NeverScrollableScrollPhysics(), // disattiva swipe manuale
                children: [emailPage(), codePage(), passwordPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
