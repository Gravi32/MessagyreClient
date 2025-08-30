import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugSettingsPage extends StatefulWidget {
  const DebugSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _DebugSettingsPageState();
}

class _DebugSettingsPageState extends State<DebugSettingsPage> {
  final data = Data();
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
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Réglages",
        middle: Text("Débogage"),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Informations générales"),
              tiles: [
                SettingsTile(
                  title: Text("Nom d'utilisateur"),
                  value: Text(data.username ?? "-"),
                ),
                SettingsTile(
                  title: Text("Version"),
                  value: Text(appVersion),
                ),
                SettingsTile(
                  title: Text("Photos de profil en cache"),
                  value: Text(data.pfpNotifiersCache.length.toString()),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Connexion"),
              tiles: [
                SettingsTile(
                  title: Text("Mode de test local"),
                  value: Text(
                    ConnectionController.useLocalhost ? "Oui" : "Non",
                  ),
                ),

                SettingsTile(
                  title: Text("Adresse du serveur"),
                  value: Text(
                    ConnectionController.serverHTTPAddress.substring(7),
                  ),
                ),

                SettingsTile(
                  title: Text("Dernière requête HTTP"),
                  value: Text(data.token != null ? "Oui" : "Non"),
                ),

                SettingsTile(
                  title: Text("État du WebSocket"),
                  value: ValueListenableBuilder<bool>(
                    valueListenable: data.isConnecting,
                    builder: (context, isConnecting, _) {
                      if (isConnecting) {
                        return Text("Connexion en cours...");
                      }

                      return ValueListenableBuilder<bool>(
                        valueListenable: data.isConnected,
                        builder: (context, isConnected, _) {
                          return Text(isConnected ? "Connecté" : "Déconnecté");
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Tokens"),
              tiles: [
                SettingsTile(
                  title: Text("Token d'accès (JWT)"),
                  value: Text(data.token != null ? "Oui" : "Non"),
                ),
                SettingsTile(
                  title: Text("Token de renouvellement"),
                  value: Text(isRefreshTokenStored ? "Oui" : "Non"),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Logs de l'application"),
              tiles: [
                SettingsTile(
                  title:
                      data.appLogs.isNotEmpty
                          ? ListView.builder(
                            
                            itemBuilder: (context, index) {
                              final logIndex = data.appLogs.length - 1 - index;
                              return Text(data.appLogs[logIndex]);
                            },
                            itemCount: data.appLogs.length,
                            reverse: true,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                          )
                          : Row(
                            spacing: 8,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: CupertinoColors.systemYellow,
                              ),
                              Text("Aucun log disponible."),
                            ],
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
