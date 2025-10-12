import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/utility.dart';

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final data = Data();

  final box = Hive.box("Misc");
  late final savedWallpapers = List<String>.from(box.get("SavedWallpapers", defaultValue: <String>[]));
  late String currentWallpaper = box.get("CurrentWallpaper", defaultValue: "");

  void saveData() {
    box.put("SavedWallpapers", savedWallpapers);
    box.put("CurrentWallpaper", currentWallpaper);
  }

  void pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    if (!context.mounted) return;
    final mountedContext = context;
    final size = MediaQuery.of(mountedContext).size;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: CropAspectRatio(ratioX: size.width, ratioY: size.height),
      uiSettings: [IOSUiSettings(title: "Retailler l'image", aspectRatioLockEnabled: true)],
    );

    if (croppedFile != null) {
      setState(() {
        savedWallpapers.add(croppedFile.path);
        currentWallpaper = croppedFile.path;
      });
      saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Fond d'écran")),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: Column(
            spacing: 12,
            children: [
              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.zero,
                children: [
                  CupertinoListTile(
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedBackground, color: CupertinoColors.label.resolveFrom(context)),
                    title: Text("Fond d'écran par défaut"),
                    trailing: CupertinoSwitch(
                      value: data.settings.useDefaultWallpaper,
                      onChanged: (newValue) {
                        setState(() {
                          data.settings.useDefaultWallpaper = newValue;
                        });
                        data.settings.save();
                      },
                    ),
                  ),
                ],
              ),
              if (!data.settings.useDefaultWallpaper) ...[
                CupertinoListSection.insetGrouped(
                  header: Text("Vos fonds d'écran"),
                  margin: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: EdgeInsets.all(10),
                        scrollDirection: Axis.horizontal,
                        itemCount: savedWallpapers.length,
                        itemBuilder: (context, index) {
                          final path = savedWallpapers[index];

                          return GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              decoration:
                                  currentWallpaper == path
                                      ? BoxDecoration(
                                        border: Border.all(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25)),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                      : null,
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(7),
                                clipBehavior: Clip.hardEdge,
                                child: Image.file(File(path), fit: BoxFit.cover),
                              ),
                            ),
                            onTap: () {
                              setState(() => currentWallpaper = path);
                              saveData();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedImageAdd02, color: CupertinoColors.label.resolveFrom(context)),
                      title: Text("Ajoutez une photo de la galérie"),
                      onTap: () => pickImage(ImageSource.gallery),
                    ),
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: CupertinoColors.label.resolveFrom(context)),
                      title: Text("Prenez une photo"),
                      onTap: () => pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
