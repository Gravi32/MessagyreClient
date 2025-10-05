import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';

class ProfilePictureDisplay extends StatefulWidget {
  final String? accountUsername;
  final double? radius;
  final String? picturePath;
  final String? pictureURL;

  const ProfilePictureDisplay({
    this.accountUsername,
    this.picturePath,
    this.pictureURL,
    super.key,
    this.radius,
  });

  @override
  State<StatefulWidget> createState() => _ProfilePictureDisplayState();
}

class _ProfilePictureDisplayState extends State<ProfilePictureDisplay> {
  final data = Data();
  double diameter = 0;

  Widget withoutPicture() {
    final firstLetter =
        widget.accountUsername == null || widget.accountUsername!.isNotEmpty
            ? widget.accountUsername![0]
            : '?';
    final color =
        Colors.primaries[firstLetter.toLowerCase().codeUnitAt(0) %
            Colors.primaries.length];

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: color,
      child: Text(
        firstLetter.toUpperCase(),
        style: TextStyle(fontSize: diameter / 4, color: color.shade900),
      ),
    );
  }

  Widget withLocalPicture() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: Image.file(
          File(widget.picturePath!),
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
        ),
      ),
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
              errorWidget: (context, url, error) => HugeIcon(icon: HugeIcons.strokeRoundedWifiError02),
            ),
          ),
        );
  }

  Widget withUsername() {
    return ValueListenableBuilder(
      valueListenable: data.getPfpNotifier(widget.accountUsername!),
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
                  errorWidget: (context, url, error) => HugeIcon(icon: HugeIcons.strokeRoundedWifiError02),
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

    return Center(child: adequateChild);
  }
}
