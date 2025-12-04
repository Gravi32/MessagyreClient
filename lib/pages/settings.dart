import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/other/eula.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/pages/settings_subpages/calendar_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/debug_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/storage_settings.dart';
import 'package:messagyre_client/pages/settings_subpages/wallpaper_settings.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:path_provider/path_provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final data = Data();
  final router = ConnectionController();
  final secureStorage = FlutterSecureStorage();

  late bool isDarkMode;

  Account? account;
  bool isCreatingBackup = false;

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
  void initState() {
    super.initState();
    isDarkMode = data.appBrightness == Brightness.dark;
    getAccount();
  }

  @override
  Widget build(BuildContext context) {
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
                    title: Text("Fond d'écran des conversations"),
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

                  SettingsTile(
                    onPressed: (context) async {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (dialogContext) => CupertinoAlertDialog(
                              title: Text("Sauvegarder en local ?"),
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

                                    try {
                                      final appDir = await getApplicationDocumentsDirectory();
                                      final hiveFiles =
                                          Directory(appDir.path).listSync().where((f) => f.path.endsWith('.hive') || f.path.endsWith('.lock')).toList();

                                      final archive = Archive();
                                      for (var file in hiveFiles) {
                                        final bytes = await File(file.path).readAsBytes();
                                        archive.addFile(ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes));
                                      }

                                      final zipData = ZipEncoder().encode(archive);

                                      await Future.delayed(Duration(seconds: 5));
                                      final path = await FilePicker.platform.saveFile(
                                        dialogTitle: 'Choisir où enregistrer les données',
                                        fileName: 'MessagyreBackup-${DateTime.now().toIso8601String()}.zip',
                                        bytes: Uint8List.fromList(zipData),
                                      );

                                      setState(() => isCreatingBackup = false);

                                      if (path != null || !context.mounted) return;

                                      showCupertinoDialog(
                                        context: context,
                                        builder:
                                            (ctx) => CupertinoAlertDialog(
                                              title: Text("Sauvegarde terminée"),
                                              content: Text(
                                                "Les données ont été copiées et enregistrés dans un fichier.\nVous pouvez l'utiliser pour passer vos donnés sur un autre dispositif.",
                                              ),
                                              actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(ctx))],
                                            ),
                                      );
                                    } catch (e) {
                                      debugPrint("Backup failed: $e");
                                      setState(() => isCreatingBackup = false);

                                      if (!context.mounted) return;
                                      showCupertinoDialog(
                                        context: context,
                                        builder:
                                            (ctx) => CupertinoAlertDialog(
                                              title: Text("Erreur"),
                                              content: Text("Impossible d'effectuer la sauvegarde :\n\n$e"),
                                              actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(ctx))],
                                            ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                      );
                    },
                    leading: isCreatingBackup ? null : HugeIcon(icon: HugeIcons.strokeRoundedUploadSquare02),
                    title:
                        isCreatingBackup
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 6,
                              children: [
                                LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14),
                                Text("Exportation en cours", style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                              ],
                            )
                            : Text("Exporter une sauvegarde"),
                  ),

                  SettingsTile(
                    onPressed: (context) async {
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
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);

                        if (result == null || result.files.isEmpty) return;

                        final filePath = result.files.single.path;
                        if (filePath == null) return;

                        final bytes = await File(filePath).readAsBytes();
                        final archive = ZipDecoder().decodeBytes(bytes);

                        final appDir = await getApplicationDocumentsDirectory();

                        for (final file in archive) {
                          if (file.isFile) {
                            final data = file.content as List<int>;
                            final outFile = File('${appDir.path}/${file.name}');
                            await outFile.create(recursive: true);
                            await outFile.writeAsBytes(data);
                          }
                        }

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
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedDownloadSquare02),
                    title: Text("Importer une sauvegarde"),
                  ),
                ],
              ),

              SettingsSection(
                title: Text("Autres"),
                tiles: [
                  SettingsTile(
                    onPressed: (context) async {
                      if (await InAppReview.instance.isAvailable()) {
                        InAppReview.instance.requestReview();
                      } else {
                        InAppReview.instance.openStoreListing(appStoreId: "6752887226");
                      }
                    },
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedStar),
                    title: Text("Laisser un avis"),
                  ),

                  SettingsTile.navigation(
                    onPressed: (context) {
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
                                      Navigator.push(context, CupertinoPageRoute(builder: (context) => ChatOverlay(recipientUsername: "support.messagyre")));
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
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedComment01),
                    title: Text("Support"),
                  ),

                  SettingsTile.navigation(
                    onPressed: (context) => showEulaReadOnly(context),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedAudit01),
                    title: Text("Conditions d'utilisation"),
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
      ),
    );
  }
}
