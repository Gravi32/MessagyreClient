import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final globals = GlobalsService();

  final box = Hive.box("Misc");
  late final savedWallpapers = List<String>.from(box.get("SavedWallpapers", defaultValue: <String>[]));
  late String currentWallpaper = box.get("CurrentWallpaper", defaultValue: "");

  bool isEditMode = false;

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
      final permanentPath = await saveToPermanentDir(croppedFile.path);

      setState(() {
        savedWallpapers.add(permanentPath);
        currentWallpaper = permanentPath;
      });

      saveData();
    }
  }

  Future<String> saveToPermanentDir(String originalPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final wallpapersDir = Directory(path.join(dir.path, "wallpapers"));
    if (!wallpapersDir.existsSync()) wallpapersDir.createSync(recursive: true);

    final newPath = path.join(wallpapersDir.path, "wallpaper_${DateTime.now().millisecondsSinceEpoch}${path.extension(originalPath)}");

    final newFile = await File(originalPath).copy(newPath);
    return newFile.path;
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
                backgroundColor: AppColors.transparent,
                margin: EdgeInsets.zero,
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedBackground, color: AppColors.text.adaptTo(context)),
                    title: Text("Fond d'écran par défaut"),
                    trailing: CupertinoSwitch(
                      value: globals.settings.useDefaultWallpaper,
                      onChanged: (newValue) {
                        setState(() {
                          globals.settings.useDefaultWallpaper = newValue;
                        });
                        globals.settings.save();
                      },
                    ),
                  ),
                ],
              ),
              if (!globals.settings.useDefaultWallpaper) ...[
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,
                  decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context)),
                  header: Text("Vos fonds d'écran"),
                  margin: EdgeInsets.zero,
                  footer:
                      isEditMode
                          ? null
                          : Text("Appuyez longuement pour modifier.", style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context))),
                  children: [
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        itemCount: savedWallpapers.length + 1,
                        itemBuilder: (context, index) {
                          final isLastItem = index >= savedWallpapers.length;
                          final path = isLastItem ? "" : savedWallpapers[index];

                          return isLastItem
                              ? isEditMode
                                  ? SizedBox.shrink()
                                  : GestureDetector(
                                    onTap: () => pickImage(ImageSource.gallery),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 5),
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          color: AppColors.secondaryText.adaptTo(context),
                                          strokeWidth: 2,
                                          dashPattern: [4, 5],
                                          radius: Radius.circular(8),
                                          strokeCap: StrokeCap.round,
                                          borderPadding: EdgeInsets.all(2),
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.aspectRatio * 180,
                                          child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.secondaryText.adaptTo(context))),
                                        ),
                                      ),
                                    ),
                                  )
                              : GestureDetector(
                                onTap:
                                    isEditMode
                                        ? null
                                        : () {
                                          setState(() => currentWallpaper = path);
                                          saveData();
                                        },
                                onLongPress: () => setState(() => isEditMode = true),
                                child: Stack(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                                      decoration:
                                          currentWallpaper == path
                                              ? BoxDecoration(
                                                border: Border.all(
                                                  color: CupertinoTheme.of(context).primaryColor.withBrightness(.25),
                                                  strokeAlign: BorderSide.strokeAlignOutside,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              )
                                              : null,
                                      child: ClipRRect(
                                        borderRadius: BorderRadiusGeometry.circular(8),
                                        clipBehavior: Clip.hardEdge,
                                        child: Image.file(File(path), fit: BoxFit.cover),
                                      ),
                                    ),
                                    if (isEditMode)
                                      Positioned(
                                        right: 0,
                                        top: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (path == currentWallpaper) currentWallpaper = "";
                                              savedWallpapers.remove(path);
                                            });
                                            saveData();
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.tertiaryBackground.adaptTo(context),
                                              boxShadow: [BoxShadow(blurRadius: 20, spreadRadius: 2)],
                                            ),
                                            child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: AppColors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                        },
                      ),
                    ),
                    if (isEditMode)
                      CupertinoListTile(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: AppColors.text.adaptTo(context)),
                        title: Text("Terminé"),
                        onTap: () => setState(() => isEditMode = false),
                      ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,

                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedImageAdd02, color: AppColors.text.adaptTo(context)),
                      title: Text("Ajoutez une photo depuis la galérie"),
                      onTap: () => pickImage(ImageSource.gallery),
                    ),
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.text.adaptTo(context)),
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
