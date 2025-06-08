import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/widgets/custom_text_field.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final router = ConnectionController();

  final pageController = PageController();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int currentPage = 0;

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

  void sendEmail() {
    router.send(
      Signal(
        type: SignalType.Registration,
        data: {"email_address": "${emailController.text.trim()}@eduvaud.ch"},
      ).pack(),
    );
    startResendTimer();
  }

  void sendCode() {
    router.send(
      Signal(
        type: SignalType.Registration,
        data: {"verification_code": codeController.text.trim()},
      ).pack(),
    );
  }

  void sendPassword() {
    router.send(
      Signal(
        type: SignalType.Registration,
        data: {"password": passwordController.text.trim()},
      ).pack(),
    );
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
        Text(
          "Pour commencer, veuillez entrer votre adresse email officiel du gymnase.",
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 36),

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

        SizedBox(height: 36),

        CupertinoButton.filled(
          padding: EdgeInsets.symmetric(vertical: 12),
          minSize: 0,
          onPressed:
              isEmailValid && !isWaitingForResponse ? () => sendEmail() : null,
          child:
              isWaitingForResponse
                  ? CupertinoActivityIndicator()
                  : Text("Envoyer le code de vérification"),
        ),
      ],
    );
  }

  Widget codePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Veuillez entrer le code envoyé à l'adresse '${emailController.text}@eduvaud.ch'",
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 36),

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

        SizedBox(height: 36),

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
          child: Text(
            canResendCode
                ? "Renvoyer le code"
                : "Renvoyer le code ${resendSecondsLeft}s",
          ),
        ),
        CupertinoButton(
          onPressed: isWaitingForResponse ? null : () => goToPage(0),
          child: Text("Changer d'adresse e-mail"),
        ),
      ],
    );
  }

  Widget passwordPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Vérification réussite!\nChoississez maintenant un mot de passe pour accéder à votre compte.",
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 36),

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
          minSize: 0,
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
      ],
    );
  }

  void askClosingConfirmation() {
    void confirm() {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }

    void cancel() {
      Navigator.of(context).pop();
    }

    if (currentPage == 0) confirm(); // No need for confirmation 

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
              onPressed: confirm,
              child: Text("Oui"),
            ),
            CupertinoDialogAction(onPressed: cancel, child: Text("Non")),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    router.onSignalReceived.listen((signal) {
      if (signal.type != SignalType.Registration) return;

      final field = signal.data["Field"];
      final response = signal.data["Response"];

      setState(() {
        switch (field) {
          case "email_address":
            switch (response) {
              case "success":
                goToPage(1);
              case "wrong_format":
                emailError =
                    "L'adresse e-mail doit respecter le format suivant : 'prénom.nom' !";
                return;
              case "wrong_domain":
                emailError = "L'adresse doit terminer en '@eduvaud.ch' !";
                return;
              case "already_exists":
                emailError = "Cet adresse a déjà été utilisé !";
                return;
              case "wait":
                emailError =
                    "Veuillez patienter, le code a déjà été envoyé récemment !";
                return;
              default:
                emailError = "Une erreur s'est produite, veuillez reéssayer.";
                return;
            }
          case "verification_code":
            switch (response) {
              case "success":
                goToPage(2);
              case "wrong_length":
                codeError = "Le code doit contenir 6 chiffres.";
                return;
              case "wrong":
                codeError = "Le code est incorrect !";
                return;
              default:
                codeError = "Une erreur s'est produite, veuillez reéssayer.";
                return;
            }
          case "password":
            switch (response) {
              case "success":
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              case "too_short":
                passwordError =
                    "Le mot de passe doit contenir au moins 8 caractères.";
                return;
              default:
                passwordError =
                    "Une erreur s'est produite, veuillez reéssayer.";
                return;
            }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: GestureDetector(
          child: Icon(CupertinoIcons.clear),
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
                    ? Icon(CupertinoIcons.mail_solid)
                    : Icon(CupertinoIcons.circle_fill, size: 8),
                currentPage == 1
                    ? Icon(CupertinoIcons.checkmark_rectangle_fill)
                    : Icon(CupertinoIcons.circle_fill, size: 8),
                currentPage == 2
                    ? Icon(CupertinoIcons.padlock_solid)
                    : Icon(CupertinoIcons.circle_fill, size: 8),
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
