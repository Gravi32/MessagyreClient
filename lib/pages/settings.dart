import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/other/eula.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/pages/settings_subpages/calendar_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/debug_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/storage_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/wallpaper_settings.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  final data = Data();
  final router = ConnectionController();
  final secureStorage = FlutterSecureStorage();

  late bool isDarkMode;

  Account? account;

  Future getAccount() async {
    if (data.username == null) return;

    final receivedAccount = await router.getAccount(data.username!);

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
              CupertinoDialogAction(
                child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.2))),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    isDarkMode = data.appBrightness == Brightness.dark;
    getAccount();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (account == null) getAccount();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Réglages"), stretch: true)];
        },
        body: SafeArea(
          top: false,
          child: SettingsList(
            shrinkWrap: true,
            platform: DevicePlatform.iOS,
            sections: [
              SettingsSection(
                title: Text("Votre compte"),
                tiles: [
                  (account == null || data.username == null)
                      ? SettingsTile(
                        title: SizedBox(
                          height: 39,
                          child: Center(child: LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14)),
                        ),
                      )
                      : SettingsTile.navigation(
                        leading: ProfilePictureDisplay(accountUsername: data.username!, radius: 28),
                        title: Padding(
                          padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(account!.displayName ?? account!.defaultDisplayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                              Text(data.username!, style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 16)),
                            ],
                          ),
                        ),
                        onPressed: (context) async {
                          if (account!.username != data.username) await getAccount();

                          if (!context.mounted) return;

                          Navigator.of(context).push(CupertinoPageRoute(builder: (context) => ProfileOverlay(account!))).then((updated) {
                            if (updated) getAccount();
                          });
                        },
                      ),

                  SettingsTile.navigation(
                    onPressed:
                        (context) => showLogoutDialog(context, () {
                          account = null;
                          router.logout();
                          restartApp(context);
                        }),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedLogoutSquare02),
                    title: Text("Se déconnecter"),
                  ),
                ],
              ),

              SettingsSection(
                title: Text("Apparence"),
                tiles: [
                  SettingsTile.switchTile(
                    onToggle: (value) {
                      setState(() {
                        isDarkMode = value;
                        data.appBrightness = value ? Brightness.dark : Brightness.light;
                      });
                    },
                    initialValue: isDarkMode,
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedMoon02),
                    title: Text('Mode sombre'),
                  ),
                  SettingsTile.navigation(
                    onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WallpaperSettingsPage())),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedBackground),
                    title: Text("Fond d'écran"),
                  ),
                ],
              ),

              SettingsSection(
                title: Text("Options"),
                tiles: [
                  SettingsTile.navigation(
                    onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => CalendarSettingsPage())),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04),
                    title: Text("Calendrier"),
                  ),
                  // SettingsTile.navigation(
                  //   onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SubjectsSettingsPage())),
                  //   leading: HugeIcon(icon: HugeIcons.strokeRoundedBooks02),
                  //   title: Text("Vos branches"),
                  // ),
                ],
              ),

              SettingsSection(
                title: Text("Stockage"),
                tiles: [
                  SettingsTile.navigation(
                    onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StorageSettingsPage())),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete01),
                    title: Text("Effacer les données"),
                  ),
                  // SettingsTile(
                  //   onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StorageSettingsPage())),
                  //   leading: HugeIcon(icon: HugeIcons.strokeRoundedUploadSquare02),
                  //   title: Text("Exporter les données"),
                  //   enabled: false, // Placeholder for future implementation
                  // ),
                  // SettingsTile(
                  //   onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StorageSettingsPage())),
                  //   leading: HugeIcon(icon: HugeIcons.strokeRoundedDownloadSquare02),
                  //   title: Text("Importer les données"),
                  //   enabled: false, // Placeholder for future implementation
                  // ),
                ],
              ),

              SettingsSection(
                title: Text("Autres"),
                tiles: [
                  SettingsTile.navigation(
                    onPressed: (context) => showEulaReadOnly(context),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedAudit01),
                    title: Text("Conditions d'utilisation"),
                  ),
                  // SettingsTile.navigation(
                  //   onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => FeedbackSettingsPage())),
                  //   leading: HugeIcon(icon: HugeIcons.strokeRoundedComment01),
                  //   title: Text("Envoyez un commentaire"),
                  // ),
                  SettingsTile.navigation(
                    onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => DebugSettingsPage())),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedSourceCodeSquare),
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
