import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/pages/settings/subpages/debug_logs_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class DebugSettingsPage extends StatefulWidget {
  const DebugSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _DebugSettingsPageState();
}

class _DebugSettingsPageState extends State<DebugSettingsPage> {
  final globals = GlobalsService();
  final network = NetworkService();
  final secureStorage = SecureStorageService();

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
    return Page(
      topBar: TopBar.tab(context, title: "Débogage"),
      child: ListView(
        children: [
          ListSection(
            title: "Informations générales",
            margin: .only(top: 16),
            children: [
              ListTile.simple(context, title: "Nom d'utilisateur", trailing: Text(globals.username ?? "-")),
              ListTile.simple(context, title: "Version", trailing: Text(globals.appVersion)),
              ListTile.simple(context, title: "Photos de profil en cache", trailing: Text(globals.pfpNotifiersCache.length.toString())),
            ],
          ),
          ListSection(
            title: "Connexion",
            margin: .only(top: 16),
            children: [
              ListTile.simple(context, title: "Mode de test local", trailing: Text(NetworkService().isLocalhost ? "Oui" : "Non")),

              ListTile.simple(context, title: "Adresse du serveur", trailing: Text(NetworkService().getBackendUri().host)),

              ListTile.simple(
                context,
                title: "État du WebSocket",
                trailing: ValueListenableBuilder(
                  valueListenable: network.connectionState,
                  builder: (context, connectionState, _) {
                    return Text(connectionState.name);
                  },
                ),
              ),
            ],
          ),
          ListSection(
            title: "Jetons",
            margin: .only(top: 16),
            children: [
              ListTile.simple(context, title: "Jeton d'accès JWT", trailing: Text(globals.token != null ? "Enregistré" : "Manquant")),
              ListTile.simple(context, title: "Jeton de renouvellement", trailing: Text(isRefreshTokenStored ? "Enregistré" : "Manquant")),
              ListTile.simple(
                context,
                title: "Jeton FCM",
                trailing: SizedBox(
                  width: 150,
                  child: Text(globals.fcmToken ?? "Manquant", overflow: TextOverflow.ellipsis, textAlign: .end),
                ),
              ),
            ],
          ),
          ListSection(
            title: "Logs de l'application",
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Voir les logs",
                onTap: () => showCupertinoSheet(context: context, enableDrag: false, builder: (context) => DebugLogsPage()),
              ),
            ],
          ),
          BottomSpacing(),
        ],
      ),
    );
  }
}
