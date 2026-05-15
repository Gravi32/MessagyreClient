import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/biometrics_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final globals = GlobalsService();
  final biometrics = BiometricsService();

  bool? canAuthenticate;

  @override
  void initState() {
    super.initState();

    biometrics.canAuthenticate().then((result) {
      if (mounted) setState(() => canAuthenticate = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Confidentialité"),
      child: ListView(
        children: [
          ListSection(
            footer: canAuthenticate ?? false ? null : "Pas disponible pour cet appareil",
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedFaceId,
                title: "FaceID pour voir les notes",
                isLoading: canAuthenticate == null,
                enabled: canAuthenticate ?? false,
                trailing: CupertinoSwitch(
                  value: globals.persistent.getBool("GradesPageRequiresFaceId") ?? false,
                  onChanged: (enableFaceID) async {
                    if (enableFaceID) if (!await biometrics.authenticate()) return;
                    await globals.persistent.setBool("GradesPageRequiresFaceId", enableFaceID);

                    if (context.mounted) Phoenix.rebirth(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
