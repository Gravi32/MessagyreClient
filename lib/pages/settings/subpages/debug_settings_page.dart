import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugSettingsPage extends StatefulWidget {
  const DebugSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _DebugSettingsPageState();
}

class _DebugSettingsPageState extends State<DebugSettingsPage> {
  final globals = GlobalsService();
  final network = NetworkService();
  final secureStorage = FlutterSecureStorage();

  bool isRefreshTokenStored = false;
  String appVersion = "?";

  Future<void> checkRefreshToken() async {
    final token = await secureStorage.read(key: "RefreshToken");
    setState(() {
      isRefreshTokenStored = token != null;
    });
  }

  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  @override
  void initState() {
    super.initState();

    checkRefreshToken();
    loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Débogage")),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Informations générales"),
              tiles: [
                SettingsTile(title: Text("Nom d'utilisateur"), value: Text(globals.username ?? "-")),
                SettingsTile(title: Text("Version"), value: Text(appVersion)),
                SettingsTile(title: Text("Photos de profil en cache"), value: Text(globals.pfpNotifiersCache.length.toString())),
              ],
            ),
            SettingsSection(
              title: Text("Connexion"),
              tiles: [
                SettingsTile(title: Text("Mode de test local"), value: Text(NetworkService().isLocalhost ? "Oui" : "Non")),

                SettingsTile(title: Text("Adresse du serveur"), value: Text(NetworkService().getBackendUri().host)),

                SettingsTile(
                  title: Text("État du WebSocket"),
                  value: ValueListenableBuilder(
                    valueListenable: network.connectionState,
                    builder: (context, connectionState, _) {
                      return Text(connectionState.name);
                    },
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Jetons"),
              tiles: [
                SettingsTile(title: Text("Jeton d'accès JWT"), value: Text(globals.token != null ? "Enregistré" : "Manquant")),
                SettingsTile(title: Text("Jeton de renouvellement"), value: Text(isRefreshTokenStored ? "Enregistré" : "Manquant")),
                SettingsTile(
                  title: Text("Jeton FCM"),
                  value: SizedBox(width: 150, child: Text(globals.fcmToken ?? "Manquant", overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Logs de l'application"),
              tiles: [
                SettingsTile(
                  title: Text("Tout copier"),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedCopy02, color: AppColors.text.adaptTo(context)),
                  onPressed: (context) => copy(context, globals.appLogs.join("\n")),
                  description: SizedBox.shrink(),
                ),
                SettingsTile(
                  title:
                      globals.appLogs.isNotEmpty
                          ? ListView.builder(
                            itemBuilder: (context, index) {
                              final logIndex = globals.appLogs.length - 1 - index;
                              final content = globals.appLogs[logIndex].split(" ");

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(content.sublist(1).join(" ")),
                                  Text(
                                    content[0].replaceAll(RegExp(r'[\[\]]'), ''),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context)),
                                  ),
                                  Divider(color: AppColors.separator.adaptTo(context).withAlpha(50)),
                                ],
                              );
                            },
                            itemCount: globals.appLogs.length,
                            reverse: true,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                          )
                          : Row(
                            spacing: 8,
                            children: [HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.yellow), Text("Aucun log disponible.")],
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
