import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/cutout_widget.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ProfilePictureDisplay extends StatefulWidget {
  final String? accountUsername;
  final double? radius;
  final String? picturePath;
  final String? pictureURL;

  const ProfilePictureDisplay({this.accountUsername, this.picturePath, this.pictureURL, super.key, this.radius});

  @override
  State<StatefulWidget> createState() => _ProfilePictureDisplayState();
}

class _ProfilePictureDisplayState extends State<ProfilePictureDisplay> {
  final globals = GlobalsService();
  double diameter = 0;

  Widget withoutPicture() {
    final firstLetter = widget.accountUsername == null || widget.accountUsername!.isNotEmpty ? widget.accountUsername![0] : '?';
    final color = Colors.primaries[firstLetter.toLowerCase().codeUnitAt(0) % Colors.primaries.length];

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: color,
      child: Text(firstLetter.toUpperCase(), style: TextStyle(fontSize: diameter / 4, color: color.shade900)),
    );
  }

  Widget withLocalPicture() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.transparent,
      child: ClipOval(child: Image.file(File(widget.picturePath!), width: diameter, height: diameter, fit: BoxFit.cover)),
    );
  }

  Widget withPictureURL() {
    final noImageFound = widget.pictureURL == null;

    return noImageFound
        ? withoutPicture()
        : CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.transparent,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: widget.pictureURL!,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorWidget: (context, _, _) => withoutPicture(),
            ),
          ),
        );
  }

  Widget withUsername() {
    return ValueListenableBuilder(
      valueListenable: globals.getPfpNotifier(widget.accountUsername!),
      builder: (context, newImageURL, child) {
        final noImageFound = newImageURL == null || newImageURL.isEmpty;

        return noImageFound
            ? withoutPicture()
            : CircleAvatar(
              radius: widget.radius,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: newImageURL,
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  errorWidget: (context, _, _) => withoutPicture(),
                ),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    diameter = (widget.radius ?? 20) * 2;

    Widget adequateChild = SizedBox.shrink();

    if (widget.picturePath != null) {
      adequateChild = withLocalPicture();
    } else if (widget.pictureURL != null) {
      adequateChild = withPictureURL();
    } else if (widget.accountUsername != null) {
      adequateChild = withUsername();
    } else {
      adequateChild = withoutPicture();
    }

    final cutoutSize = clampDouble(diameter / 2.25, 0, 26);
    final badge = getBadge();

    return Center(
      child:
          badge == null
              ? adequateChild
              : CutoutWidget(
                cutoutSize: cutoutSize,
                childToCutout: adequateChild,
                childInCutout: CustomIcon(icon: badge, color: AppColors.text.adaptTo(context), size: cutoutSize * 0.8),
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
