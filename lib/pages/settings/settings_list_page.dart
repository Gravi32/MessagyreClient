import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/pages/settings/subpages/class_picker_page.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/pages/bootstrap/privacy_policy.dart';
import 'package:messagyre_client/pages/bootstrap/terms_of_service.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/pages/settings/subpages/admin_page.dart';
import 'package:messagyre_client/pages/settings/subpages/archives_page.dart';
import 'package:messagyre_client/pages/settings/subpages/preferences_settings_page.dart';
import 'package:messagyre_client/pages/settings/subpages/privacy_settings.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/pages/settings/subpages/debug_settings_page.dart';
import 'package:messagyre_client/pages/settings/subpages/wallpaper_settings_page.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/made_by_gravi.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

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
      builder: (context) =>
          Dialog.confirm(content: "Voulez-vous vraiment *vous déconnecter* ?\nVous serez redirigé vers la page de connexion.", onConfirm: onLogoutConfirmed),
    );
  }

  @override
  void initState() {
    super.initState();
    getAccount();
  }

  Future<void> openProfile() async {
    if (account == null) return;
    if (account!.username != globals.username) await getAccount();
    if (!mounted) return;

    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => ProfilePage(account!))).then((updated) {
      if (updated == true) getAccount();
    });
  }

  /// Who is signed in, on the app icon's gradient with the Gymnase in the corner
  Widget buildProfileCard(BuildContext context) {
    final white = AppColors.white;
    final schoolClass = ClassService().current.value?.name;
    final isLoading = account == null || globals.username == null;

    return Padding(
      padding: const .only(top: AppSpacing.l),
      child: CupertinoButton(
        padding: .zero,
        minimumSize: .zero,
        pressedOpacity: .8,
        onPressed: isLoading ? null : openProfile,
        child: Container(
          height: 112,
          clipBehavior: .antiAlias,
          decoration: BoxDecoration(borderRadius: .circular(AppRadius.l), gradient: AppColors.accentGradient),
          child: Stack(
            children: [
              Positioned(right: -18, bottom: -34, child: GymnaseMark(size: 132, color: white.withValues(alpha: .13))),
              Padding(
                padding: const .all(AppSpacing.l),
                child: isLoading
                    ? Center(child: GymnaseLoader(size: 22, color: white))
                    : Row(
                        spacing: AppSpacing.l,
                        children: [
                          Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(shape: .circle, color: white.withValues(alpha: .35)),
                            child: SizedBox.square(dimension: 64, child: ProfilePictureDisplay(accountUsername: globals.username!)),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: .center,
                              crossAxisAlignment: .start,
                              children: [
                                Text(
                                  account!.displayName ?? account!.defaultDisplayName,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                  style: AppStyles.header(context).copyWith(color: white),
                                ),
                                Text(globals.username!, maxLines: 1, overflow: .ellipsis, style: AppStyles.subheadline(context).copyWith(color: white.withValues(alpha: .8))),
                                if (schoolClass != null) ...[
                                  const SizedBox(height: AppSpacing.xs + 2),
                                  Container(
                                    padding: const .symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                                    decoration: BoxDecoration(borderRadius: .circular(AppRadius.s), color: white.withValues(alpha: .2)),
                                    child: Text("Classe $schoolClass", style: AppStyles.badge(context)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: white.withValues(alpha: .8), size: AppSizes.smallIcon),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (account == null) getAccount();

    return Page.sliver(
      topBar: TopBar.sliver(title: "Réglages"),
      body: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: .zero,
        children: [
          buildProfileCard(context),
          ListSection(
            margin: .only(top: 12),
            children: [
              ListTile.simple(
                context,
                title: "Ma classe",
                icon: HugeIcons.strokeRoundedSchool01,
                trailing: Text(
                  ClassService().current.value?.name ?? (ClassService().savedValue == SchoolClass.outside ? "Aucune" : "À choisir"),
                  style: AppStyles.secondaryText(context),
                ),
                onTap: () => showCupertinoSheet(context: context, builder: (_) => const ClassPickerPage(), enableDrag: false).then((_) => setState(() {})),
              ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedLogoutSquare02,
                title: "Se déconnecter",
                onTap: () => showLogoutDialog(context, () {
                  account = null;
                  network.logout();
                  restartApp(context);
                }),
              ),
            ],
          ),

          ListSection(
            title: "Apparence",
            margin: .only(top: 16),
            children: [
              ListTile(
                buildChevron: false,
                padding: .all(14),
                child: SegmentedControl<Brightness?>(
                  defaultIndex: switch (globals.persistent.getBool("useDarkMode")) {
                    true => 0,
                    false => 1,
                    _ => 2,
                  },
                  options: {"Sombre": .dark, "Clair": .light, "Système": null},
                  onTap: (newBrightness) {
                    globals.persistent.setBool("useDarkMode", newBrightness == .dark);
                    if (newBrightness == null) globals.persistent.remove("useDarkMode");
                    Phoenix.rebirth(context);
                  },
                ),
              ),
              ListTile.simple(
                context,
                title: "Fond d'écran des conversations",
                icon: HugeIcons.strokeRoundedBackground,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WallpaperSettingsPage())),
              ),
            ],
          ),

          ListSection(
            title: "Options",
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Branches",
                icon: HugeIcons.strokeRoundedBooks02,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SubjectsListPage())),
              ),
              ListTile.simple(
                context,
                title: "Confidentialité",
                icon: HugeIcons.strokeRoundedLockKey,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => PrivacySettings())),
              ),
              ListTile.simple(
                context,
                title: "Préférences",
                icon: HugeIcons.strokeRoundedSettings05,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => PreferencesSettingsPage())),
              ),
              ListTile.simple(
                context,
                title: "Archives",
                icon: HugeIcons.strokeRoundedArchive02,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const ArchivesPage())),
              ),
            ],
          ),

          ListSection(
            title: "Stockage",
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Exporter les données",
                icon: HugeIcons.strokeRoundedUploadSquare02,
                isLoading: isCreatingBackup,
                onTap: () async {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog.confirm(
                      content: "Messagyre copiera vos données dans un fichier externe que vous pourrez exporter.",
                      onConfirm: () async {
                        setState(() => isCreatingBackup = true);

                        await database.saveBackup();
                        await Future.delayed(Duration(seconds: 5));

                        setState(() => isCreatingBackup = false);

                        if (!context.mounted) return;

                        showCupertinoDialog(
                          context: context,
                          builder: (_) => Dialog(
                            title: "Exportation terminée",
                            content:
                                "Les données ont été copiées et enregistrés dans un fichier.\nVous pouvez l'utiliser pour transférer vos donnés sur un autre dispositif.",
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              ListTile.simple(
                context,
                title: "Importer des données",
                icon: HugeIcons.strokeRoundedDownloadSquare02,
                onTap: () async {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog.confirm(
                      content: "L'importation de nouvelles données va *remplacer* vos données actuelles.",
                      onConfirm: () async {
                        try {
                          await database.loadBackup();

                          if (!context.mounted) return;
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => Dialog(
                              title: "Importation terminée",
                              content:
                                  "Les données ont été *importées avec succès*.\n\nPour qu'elles s'appliquent il est nécessaire de *redémarrer Messagyre* !",
                            ),
                          );
                        } catch (e) {
                          showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
                        }
                      },
                      isDestructive: true,
                    ),
                  );
                },
              ),
            ],
          ),

          ListSection(
            title: "Informations légales",
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Conditions d'utilisation",
                icon: HugeIcons.strokeRoundedAudit01,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => TermsOfServicePage(readOnly: true))),
              ),
              ListTile.simple(
                context,
                title: "Politique de confidentialité",
                icon: HugeIcons.strokeRoundedPolicy,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => PrivacyPolicyPage(readOnly: true))),
              ),
            ],
          ),

          ListSection(
            title: "Autres",
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Laisser un avis",
                icon: HugeIcons.strokeRoundedStar,
                onTap: () async {
                  if (await InAppReview.instance.isAvailable()) {
                    InAppReview.instance.requestReview();
                  } else {
                    InAppReview.instance.openStoreListing(appStoreId: "6752887226");
                  }
                },
              ),
              ListTile.simple(
                context,
                title: "Contacter le support",
                icon: HugeIcons.strokeRoundedComment01,
                onTap: () {
                  try {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog.confirm(
                        content:
                            "Si vous avez la moindre question concernant Messagyre, vous pouvez écrire à *Support Messagyre*.\n\nVous recevrez une réponse sous *48 heures*.",
                        onConfirm: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => ChatPage(username: "support.messagyre"))),
                      ),
                    );
                  } catch (e) {
                    showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
                  }
                },
              ),

              ListTile.simple(
                context,
                title: "Débogage",
                icon: HugeIcons.strokeRoundedSourceCodeSquare,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => DebugSettingsPage())),
              ),

              if (adminUsernames.contains(globals.username))
                ListTile.simple(
                  context,
                  title: "Administration",
                  icon: HugeIcons.strokeRoundedAnalytics01,
                  onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const AdminPage())),
                ),
            ],
          ),

          const SizedBox(height: 24),
          const MadeByGravi(),

          BottomSpacing(includeBottomBar: true),
        ],
      ),
    );
  }
}
