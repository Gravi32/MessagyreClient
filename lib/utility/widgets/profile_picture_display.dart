import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/graphics/cutout_widget.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ProfilePictureDisplay extends StatefulWidget {
  final String? accountUsername;
  final String? picturePath;
  final String? pictureURL;
  final bool isBlocked;
  final double? radius;

  const ProfilePictureDisplay({this.accountUsername, this.picturePath, this.pictureURL, super.key, this.isBlocked = false, this.radius});

  @override
  State<StatefulWidget> createState() => _ProfilePictureDisplayState();
}

class _ProfilePictureDisplayState extends State<ProfilePictureDisplay> {
  final globals = GlobalsService();

  double getRadius(double diameter) => diameter / 2;

  Widget withoutPicture(double diameter) {
    final firstLetter = widget.accountUsername == null || widget.accountUsername!.isEmpty ? '?' : widget.accountUsername![0];
    final color = Colors.primaries[firstLetter.toLowerCase().codeUnitAt(0) % Colors.primaries.length];

    return CircleAvatar(
      radius: getRadius(diameter),
      backgroundColor: color,
      child: Text(
        firstLetter.toUpperCase(),
        style: TextStyle(fontSize: diameter / 3, color: color.shade900),
      ),
    );
  }

  Widget withLocalPicture(double diameter) {
    return CircleAvatar(
      radius: getRadius(diameter),
      backgroundColor: AppColors.transparent,
      child: ClipOval(
        child: Image.file(File(widget.picturePath!), width: diameter, height: diameter, fit: .cover),
      ),
    );
  }

  Widget withPictureURL(double diameter) {
    if (widget.pictureURL == null) return withoutPicture(diameter);

    return CircleAvatar(
      radius: getRadius(diameter),
      backgroundColor: AppColors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.pictureURL!,
          width: diameter,
          height: diameter,
          fit: .cover,
          errorWidget: (context, _, _) => withoutPicture(diameter),
        ),
      ),
    );
  }

  Widget withUsername(double diameter) {
    return ValueListenableBuilder(
      valueListenable: globals.getPfpNotifier(widget.accountUsername!),
      builder: (context, newImageURL, child) {
        final noImageFound = newImageURL == null || newImageURL.isEmpty;

        return noImageFound
            ? withoutPicture(diameter)
            : CircleAvatar(
                radius: getRadius(diameter),
                backgroundColor: AppColors.transparent,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: newImageURL,
                    width: diameter,
                    height: diameter,
                    fit: .cover,
                    errorWidget: (context, _, _) => withoutPicture(diameter),
                  ),
                ),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double diameter = constraints.maxWidth;

          Widget adequateChild;
          if (widget.picturePath != null) {
            adequateChild = withLocalPicture(diameter);
          } else if (widget.pictureURL != null) {
            adequateChild = withPictureURL(diameter);
          } else if (widget.accountUsername != null) {
            adequateChild = withUsername(diameter);
          } else {
            adequateChild = withoutPicture(diameter);
          }

          final cutoutSize = clampDouble(diameter / 2.25, 0, diameter * 0.4);
          final badge = getBadge();

          return Container(
            foregroundDecoration: widget.isBlocked ? const BoxDecoration(color: AppColors.grey, backgroundBlendMode: BlendMode.saturation) : null,
            child: Center(
              child: CutoutWidget(
                enabled: badge != null,
                cutoutSize: cutoutSize,
                childToCutout: adequateChild,
                childInCutout: badge != null ? CustomIcon(icon: badge, color: AppColors.text.adaptTo(context), size: cutoutSize * 0.8) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  List<List<dynamic>>? getBadge() {
    final username = widget.accountUsername;
    if (username == "support.messagyre") return HugeIcons.strokeRoundedCustomerService01;
    if (username == "pietro.gravina") return HugeIcons.strokeRoundedSourceCode;
    if (username != null && username.contains("test.")) return HugeIcons.strokeRoundedTestTube01;
    return null;
  }
}
