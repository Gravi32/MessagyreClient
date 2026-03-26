import 'package:flutter/cupertino.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/pages/bootstrap/privacy_policy.dart';
import 'package:messagyre_client/pages/bootstrap/terms_of_service.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/pages/settings/subpages/calendar_settings_page.dart';
import 'package:messagyre_client/pages/settings/subpages/debug_settings_page.dart';
import 'package:messagyre_client/pages/settings/subpages/wallpaper_settings_page.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class SettingsListPage extends StatefulWidget {
  const SettingsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsListPageState();
}

class _SettingsListPageState extends State<SettingsListPage> {
  final database = DatabaseService();
  final globals = GlobalsService();
  final network = NetworkService();
  final secureStorage = SecureStorageService();

  late bool isDarkMode;

  Account? account;
  bool isCreatingBackup = false;

  Future getAccount() async {
    if (globals.username == null) return;

    final receivedAccount = await network.getAccount(globals.username!);

    setState(() {
      account = receivedAccount;
    });

    return;
  }

  void showLogoutDialog(BuildContext context, VoidCallback onLogoutConfirmed) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text("Déconnexion"),
            content: Text("Voulez-vous vraiment vous déconnecter ?\n\nVous serez redirigé vers la page de connexion."),
            actions: [
              CupertinoDialogAction(child: Text("Annuler", style: TextStyle(color: AppColors.accent)), onPressed: () => Navigator.of(context).pop()),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogoutConfirmed();
                },
                child: Text("Oui"),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    isDarkMode = globals.appBrightness == Brightness.dark;
    getAccount();
  }

  @override
  Widget build(BuildContext context) {
    if (account == null) getAccount();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.secondaryBackground,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Réglages"), stretch: true)];
        },
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: 20),
            physics: const ClampingScrollPhysics(),
            children: [
              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Votre compte"),
                children: [
                  (account == null || globals.username == null)
                      ? CupertinoListTile(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        title: SizedBox(
                          height: 39,
                          child: Center(child: LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)),
                        ),
                      )
                      : CupertinoListTile(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        onTap: () async {
                          if (account!.username != globals.username) await getAccount();

                          if (!context.mounted) return;

                          Navigator.of(context).push(CupertinoPageRoute(builder: (context) => ProfilePage(account!))).then((updated) {
                            if (updated) getAccount();
                          });
                        },
                        title: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 80),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfilePictureDisplay(accountUsername: globals.username!, radius: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account!.displayName ?? account!.defaultDisplayName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(globals.username!, style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context), fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: CupertinoListTileChevron(),
                      ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap:
                        () => showLogoutDialog(context, () {
                          account = null;
                          network.logout();
                          restartApp(context);
                        }),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedLogoutSquare02),
                    title: Text("Se déconnecter"),
                  ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => openUrl("https://hermes.edu-vaud.ch/absences/synoptiques/eleve/"),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedGlobe02),
                    title: Text("Ouvrir Hermes II"),
                    trailing: CupertinoListTileChevron(),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Apparence"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    trailing: CupertinoSwitch(
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                          globals.appBrightness = value ? Brightness.dark : Brightness.light;
                          Phoenix.rebirth(context);
                        });
                      },
                    ),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedMoon02),
                    title: Text('Mode sombre'),
                  ),
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WallpaperSettingsPage())),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedBackground),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Fond d'écran des conversations"),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Options"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => CalendarSettingsPage())),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedCalendar04),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Calendrier"),
                  ),
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SubjectsListPage())),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedBooks02),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Branches"),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Stockage"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () async {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (dialogContext) => CupertinoAlertDialog(
                              title: Text("Exporter en local ?"),
                              content: Text(
                                "Messagyre copiera vos notes et vos devoirs dans un nouveau fichier que vous pourrez utiliser pour passer les données sur un autre dispositif.",
                              ),
                              actions: [
                                CupertinoDialogAction(child: Text("Annuler"), onPressed: () => Navigator.pop(dialogContext)),
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  child: Text("Continuer"),
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    setState(() => isCreatingBackup = true);

                                    database.saveBackup();
                                    await Future.delayed(Duration(seconds: 5));

                                    setState(() => isCreatingBackup = false);

                                    if (!context.mounted) return;

                                    showCupertinoDialog(
                                      context: context,
                                      builder:
                                          (ctx) => CupertinoAlertDialog(
                                            title: Text("Exportation terminée"),
                                            content: Text(
                                              "Les données ont été copiées et enregistrés dans un fichier.\nVous pouvez l'utiliser pour passer vos donnés sur un autre dispositif.",
                                            ),
                                            actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(ctx))],
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                      );
                    },
                    leading: isCreatingBackup ? null : CustomIcon(icon: HugeIcons.strokeRoundedUploadSquare02),
                    title:
                        isCreatingBackup
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 6,
                              children: [
                                LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
                                Text("Exportation en cours", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                              ],
                            )
                            : Text("Exporter les données"),
                  ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () async {
                      final confirm = await showCupertinoDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => CupertinoAlertDialog(
                              title: Text("Confirmer l'importation"),
                              content: Text(
                                "L'importation de nouvelles données va remplacer vos données actuelles. "
                                "Voulez-vous continuer ?",
                              ),
                              actions: [
                                CupertinoDialogAction(child: Text("Annuler"), onPressed: () => Navigator.pop(ctx, false)),
                                CupertinoDialogAction(isDestructiveAction: true, child: Text("Continuer"), onPressed: () => Navigator.pop(ctx, true)),
                              ],
                            ),
                      );

                      if (confirm != true) return;

                      try {
                        database.loadBackup();

                        if (!context.mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (ctx) => CupertinoAlertDialog(
                                title: Text("Importation terminée"),
                                content: Text(
                                  "Les données ont été importées avec succès.\n\nPour qu'elles s'appliquent il est nécessaire de redémarrer Messagyre !",
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("Ok"),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ],
                              ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (ctx) => CupertinoAlertDialog(
                                title: Text("Erreur"),
                                content: Text("Impossible d'importer les données :\n$e"),
                                actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(ctx))],
                              ),
                        );
                      }
                    },
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedDownloadSquare02),
                    title: Text("Importer des données"),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Informations légales"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => TermsOfServicePage(readOnly: true))),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedAudit01),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Conditions d'utilisation"),
                  ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => PrivacyPolicyPage(readOnly: true))),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedPolicy),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Politique de confidentialité"),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: Text("Autres"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () async {
                      if (await InAppReview.instance.isAvailable()) {
                        InAppReview.instance.requestReview();
                      } else {
                        InAppReview.instance.openStoreListing(appStoreId: "6752887226");
                      }
                    },
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedStar),
                    title: Text("Laisser un avis"),
                  ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () {
                      try {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (dialogContext) => CupertinoAlertDialog(
                                title: Text("Contacter le support"),
                                content: CustomText(
                                  "Si vous avez la moindre question concernant Messagyre, vous pouvez écrire à *Support Messagyre*.\n\nVous recevrez une réponse sous *48 heures*.",
                                ),
                                actions: [
                                  CupertinoDialogAction(onPressed: () => Navigator.pop(dialogContext), child: Text("Annuler")),
                                  CupertinoDialogAction(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.push(context, CupertinoPageRoute(builder: (context) => ChatPage(username: "support.messagyre")));
                                    },
                                    isDefaultAction: true,
                                    child: Text("Continuer"),
                                  ),
                                ],
                              ),
                        );
                      } catch (e, s) {
                        debugPrint("[ERROR] Support page opening failed: $e. Stacktrace: $s");

                        showCupertinoDialog(
                          context: context,
                          builder:
                              (dialogContext) => CupertinoAlertDialog(
                                title: Text("Erreur !"),
                                content: Text(
                                  "Une erreur est survenue pendant l'ouverture de la conversation avec le support. Vous trouverez ce qui s'est passé dans la page de débogage.",
                                ),
                                actions: [
                                  CupertinoDialogAction(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: Text("Fermer")),
                                ],
                              ),
                        );
                      }
                    },
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedComment01),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Support"),
                  ),

                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => DebugSettingsPage())),
                    leading: CustomIcon(icon: HugeIcons.strokeRoundedSourceCodeSquare),
                    trailing: CupertinoListTileChevron(),
                    title: Text("Débogage"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
