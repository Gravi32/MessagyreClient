import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';

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

  Future<void> checkRefreshToken() async {
    final token = await secureStorage.read(key: "RefreshToken");
    setState(() {
      isRefreshTokenStored = token != null;
    });
  }

  @override
  void initState() {
    super.initState();

    checkRefreshToken();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Débogage")),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
          physics: const ClampingScrollPhysics(),
          children: [
            CupertinoListSection.insetGrouped(
               margin: EdgeInsets.zero,
              backgroundColor: AppColors.transparent,
              header: Text("Informations générales"),
              children: [
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Nom d'utilisateur"),
                  trailing: Text(globals.username ?? "-"),
                ),
                CupertinoListTile(backgroundColor: AppColors.secondaryBackground.adaptTo(context), title: Text("Version"), trailing: Text(globals.appVersion)),
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Photos de profil en cache"),
                  trailing: Text(globals.pfpNotifiersCache.length.toString()),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
               margin: EdgeInsets.zero,
              backgroundColor: AppColors.transparent,
              header: Text("Connexion"),
              children: [
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Mode de test local"),
                  trailing: Text(NetworkService().isLocalhost ? "Oui" : "Non"),
                ),

                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Adresse du serveur"),
                  trailing: Text(NetworkService().getBackendUri().host),
                ),

                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("État du WebSocket"),
                  trailing: ValueListenableBuilder(
                    valueListenable: network.connectionState,
                    builder: (context, connectionState, _) {
                      return Text(connectionState.name);
                    },
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              backgroundColor: AppColors.transparent,
              header: Text("Jetons"),
              children: [
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Jeton d'accès JWT"),
                  trailing: Text(globals.token != null ? "Enregistré" : "Manquant"),
                ),
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Jeton de renouvellement"),
                  trailing: Text(isRefreshTokenStored ? "Enregistré" : "Manquant"),
                ),
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Jeton FCM"),
                  trailing: SizedBox(width: 150, child: Text(globals.fcmToken ?? "Manquant", overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              backgroundColor: AppColors.transparent,
              header: Text("Logs de l'application"),
              children: [
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title: Text("Tout copier"),
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedCopy02, color: AppColors.text.adaptTo(context)),
                  onTap: () => copy(context, globals.appLogs.join("\n")),
                ),
                CupertinoListTile(
                  backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  title:
                      globals.appLogs.isNotEmpty
                          ? ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 450),
                            child: ListView.separated(
                              itemCount: globals.appLogs.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final logIndex = globals.appLogs.length - 1 - index;
                                final content = globals.appLogs[logIndex].split(" ");

                                return Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          content.sublist(1).join(" "),
                                          style: TextStyle(fontSize: 14, color: AppColors.secondaryText.adaptTo(context)),
                                          softWrap: true,
                                        ),
                                      ),
                                      Text(
                                        content[0].replaceAll(RegExp(r'[\[\]]'), ''),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) => Divider(height: 0, color: AppColors.separator.adaptTo(context).withAlpha(10)),
                            ),
                          )
                          : Row(spacing: 8, children: [HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.yellow), Text("Aucun log disponible.")]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
