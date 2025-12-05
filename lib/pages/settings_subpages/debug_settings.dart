import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugSettingsPage extends StatefulWidget {
  const DebugSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _DebugSettingsPageState();
}

class _DebugSettingsPageState extends State<DebugSettingsPage> {
  final data = Data();
  final router = ConnectionController();
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
                SettingsTile(title: Text("Nom d'utilisateur"), value: Text(data.username ?? "-")),
                SettingsTile(title: Text("Version"), value: Text(appVersion)),
                SettingsTile(title: Text("Photos de profil en cache"), value: Text(data.pfpNotifiersCache.length.toString())),
              ],
            ),
            SettingsSection(
              title: Text("Connexion"),
              tiles: [
                SettingsTile(title: Text("Mode de test local"), value: Text(ConnectionController.useLocalhost ? "Oui" : "Non")),

                SettingsTile(title: Text("Adresse du serveur"), value: Text(ConnectionController.serverHTTPAddress.substring(7))),

                SettingsTile(
                  title: Text("État du WebSocket"),
                  value: ValueListenableBuilder(
                    valueListenable: router.connectionState,
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
                SettingsTile(title: Text("Jeton d'accès JWT"), value: Text(data.token != null ? "Enregistré" : "Manquant")),
                SettingsTile(title: Text("Jeton de renouvellement"), value: Text(isRefreshTokenStored ? "Enregistré" : "Manquant")),
                SettingsTile(
                  title: Text("Jeton FCM"),
                  value: SizedBox(width: 150, child: Text(data.fcmToken ?? "Manquant", overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Logs de l'application"),
              tiles: [
                SettingsTile(
                  title: Text("Tout copier"),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedCopy02, color: CupertinoColors.label.resolveFrom(context)),
                  onPressed: (context) => copy(context, data.appLogs.join("\n")),
                  description: SizedBox.shrink(),
                ),
                SettingsTile(
                  title:
                      data.appLogs.isNotEmpty
                          ? ListView.builder(
                            itemBuilder: (context, index) {
                              final logIndex = data.appLogs.length - 1 - index;
                              final content = data.appLogs[logIndex].split(" ");

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(content.sublist(1).join(" ")),
                                  Text(
                                    content[0].replaceAll(RegExp(r'[\[\]]'), ''),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontSize: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                                  ),
                                  Divider(color: CupertinoColors.separator.resolveFrom(context).withAlpha(50)),
                                ],
                              );
                            },
                            itemCount: data.appLogs.length,
                            reverse: true,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                          )
                          : Row(
                            spacing: 8,
                            children: [HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: CupertinoColors.systemYellow), Text("Aucun log disponible.")],
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
