import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/pages/settings_subpages/debug_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/feedback_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/storage_settings.dart';
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

  void getAccount() {
    if (data.username == null) return;

    router
        .getAccount(data.username!)
        .then(
          (receivedAccount) => setState(() {
            account = receivedAccount;
          }),
        );
  }

  void showLogoutDialog(BuildContext context, VoidCallback onLogoutConfirmed) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text("Déconnexion"),
            content: Text("Voulez-vous vraiment vous déconnecter ?\n\nVous serez redirigé vers la page de connexion."),
            actions: [
              CupertinoDialogAction(child: Text("Non"), onPressed: () => Navigator.of(context).pop()),
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
        body: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Votre compte"),
              tiles: [
                (account == null || data.username == null)
                    ? SettingsTile(title: SizedBox(height: 39, child: CupertinoActivityIndicator()))
                    : SettingsTile.navigation(
                      leading: ProfilePictureDisplay(accountUsername: data.username!),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(data.username!.split('.')[0].capitalize(everyWord: true), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          Text(data.username!, style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 15)),
                        ],
                      ),
                      onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => ProfileOverlay(account!))),
                    ),

                SettingsTile.navigation(
                  onPressed:
                      (context) => showLogoutDialog(context, () async {
                        router.get("/Auth/Logout"); // Notifies the server

                        data.username = null;
                        data.token = null;
                        await secureStorage.delete(key: "AccessToken");
                        await secureStorage.delete(key: "RefreshToken");
                        await Hive.box("Misc").delete("Username");

                        if (router.onUnauthorized != null) {
                          router.onUnauthorized!();
                        }
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
                SettingsTile(
                  onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StorageSettingsPage())),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedUploadSquare02),
                  title: Text("Exporter les données"),
                  enabled: false, // Placeholder for future implementation
                ),
                SettingsTile(
                  onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StorageSettingsPage())),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedDownloadSquare02),
                  title: Text("Importer les données"),
                  enabled: false, // Placeholder for future implementation
                ),
              ],
            ),

            SettingsSection(
              title: Text("Autres"),
              tiles: [
                SettingsTile.navigation(
                  onPressed: (context) => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => FeedbackSettingsPage())),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedComment01),
                  title: Text("Envoyez un commentaire"),
                ),
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
    );
  }
}
