import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final globals = GlobalsService();

  late final savedWallpapers = List<String>.from(globals.persistent.getStringList("SavedWallpapers") ?? []);
  late String currentWallpaper = globals.persistent.getString("CurrentWallpaper") ?? "";

  bool isEditMode = false;

  void saveData() {
    globals.persistent.setStringList("SavedWallpapers", savedWallpapers);
    globals.persistent.setString("CurrentWallpaper", currentWallpaper);
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
    return Page.scrollable(
      context,
      topBar: TopBar.tab(context, title: "Fond d'écran"),
      children: [
        ListSection(
          children: [
            ListTile.simple(
              context,
              title: "Fond d'écran par défaut",
              icon: HugeIcons.strokeRoundedBackground,
              trailing: CupertinoSwitch(
                value: globals.persistent.getBool("useDefaultWallpaper") ?? true,
                onChanged: (newValue) {
                  setState(() {
                    globals.persistent.setBool("useDefaultWallpaper", newValue);
                  });
                },
              ),
            ),
          ],
        ),
        if (!(globals.persistent.getBool("useDefaultWallpaper") ?? true)) ...[
          ListSection(
            title: "Vos fonds d'écran",
            children: [
              ListTile(
                buildChevron: false,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: .horizontal,
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
                                          radius: .circular(8),
                                          strokeCap: .round,
                                          borderPadding: .all(2),
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.aspectRatio * 180,
                                          child: Center(
                                            child: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.secondaryText.adaptTo(context)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                          : GestureDetector(
                              onTap: isEditMode
                                  ? null
                                  : () {
                                      setState(() => currentWallpaper = path);
                                      saveData();
                                    },
                              onLongPress: () => setState(() => isEditMode = true),
                              child: Stack(
                                children: [
                                  Container(
                                    margin: .symmetric(vertical: 10, horizontal: 5),
                                    decoration: currentWallpaper == path
                                        ? BoxDecoration(
                                            border: .all(color: AppColors.accent, strokeAlign: BorderSide.strokeAlignOutside),
                                            borderRadius: .circular(8),
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
                                          padding: .all(6),
                                          decoration: BoxDecoration(shape: .circle, color: AppColors.tertiaryBackground.adaptTo(context)),
                                          child: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: AppColors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                    },
                  ),
                ),
              ),
              if (isEditMode)
                ListTile.simple(
                  context,
                  title: "Terminé",
                  buildChevron: false,
                  icon: HugeIcons.strokeRoundedTick02,
                  onTap: () => setState(() => isEditMode = false),
                ),
            ],
          ),

          ListSection(
            children: [
              ListTile.simple(context, title: "Prenez une photo", icon: HugeIcons.strokeRoundedCamera01, onTap: () => pickImage(.camera)),
              ListTile.simple(context, title: "Ajoutez une photo depuis la galérie", icon: HugeIcons.strokeRoundedImageAdd02, onTap: () => pickImage(.gallery)),
            ],
          ),
        ],
      ],
    );
  }
}
