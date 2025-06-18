import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/singletons/data.dart';

class ProfilePictureDisplay extends StatefulWidget {
  final String accountUsername;
  final double? radius;

  const ProfilePictureDisplay(this.accountUsername, {super.key, this.radius});

  @override
  State<StatefulWidget> createState() => _ProfilePictureDisplayState();
}

class _ProfilePictureDisplayState extends State<ProfilePictureDisplay> {
  final data = Data();

  @override
  Widget build(BuildContext context) {
    final double diameter = (widget.radius ?? 20) * 2;

    return ValueListenableBuilder(
      valueListenable: data.getPfpNotifier(widget.accountUsername),
      builder: (context, newImageURL, child) {
        final useDefaultIcon = newImageURL == null || newImageURL.isEmpty;
        final firstLetter =
            widget.accountUsername.isNotEmpty ? widget.accountUsername[0] : '?';
        final defaultIconColor =
            Colors.primaries[firstLetter.toLowerCase().codeUnitAt(0) %
                Colors.primaries.length];
        return Center(
          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor:
                useDefaultIcon ? defaultIconColor : Colors.transparent,
            child:
                useDefaultIcon
                    ? Text(
                      firstLetter.toUpperCase(),
                      style: TextStyle(
                        fontSize: diameter / 4,
                        color: defaultIconColor.shade900,
                      ),
                    )
                    : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: newImageURL,
                        width: diameter,
                        height: diameter,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
          ),
        );
      },
    );
  }
}
