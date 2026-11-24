import 'dart:math';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/widgets/color_picker.dart' show colorFromHex, colorToHex;
import 'package:messagyre_client/utility/widgets/shimmer.dart';
import 'package:stac/stac.dart';

/// What the server stores for an announcement (a row of its News table), read without trusting its shape
class NewsContent {
  final Map<String, dynamic> row;
  late final Map<String, dynamic> metadata = _map(row["Metadata"]);
  late final Map<String, dynamic>? coverWidget = _mapOrNull(row["CoverWidget"]);
  late final Map<String, dynamic>? pageWidget = _mapOrNull(row["PageWidget"]);

  NewsContent(this.row);

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value == null) return {};
    final decoded = value is String ? tryJsonDecode(value) : value;
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  static Map<String, dynamic> _map(Object? value) => _mapOrNull(value) ?? {};

  String get author => (row["AuthorUsername"] ?? "").toString();
  String? get url => metadata["OnTapUrl"]?.toString();
  String? get colorName => metadata["BackgroundColor"]?.toString();

  /// Since 4.111: any colour ("#RRGGBB"; [colorName] is then the nearest named one, for the older apps)
  String? get customColor => colorFromHex(metadata["CustomColor"]?.toString()) == null ? null : metadata["CustomColor"].toString();

  /// The card's colour: the custom one, or the named one
  Color? get color => colorFromHex(customColor) ?? AppColors.fromName(colorName);

  bool get shimmer => metadata["Shimmer"] == true;
  String? get backgroundImage => metadata["BackgroundImageUrl"]?.toString();
  String? get contentImage => metadata["ContentImageUrl"]?.toString();

  /// How many people saw it (GET /admin/news only)
  int? get views => (row["Views"] as num?)?.toInt();
  int? get id => (row["ID"] as num?)?.toInt();

  /// Every text of the card, in reading order (for an announcement written before the editor existed)
  List<String> get texts {
    final found = <String>[];
    void walk(Object? node) {
      if (node is Map) {
        if (node["type"] == "app_text" && node["data"] is String) found.add(node["data"]);
        walk(node["child"]);
        walk(node["children"]);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    walk(coverWidget);
    return found;
  }

  String get title => metadata["Title"]?.toString() ?? texts.firstOrNull ?? "";
  String get text => metadata["Text"]?.toString() ?? texts.skip(1).join("\n\n");

  /// The card the server builds from a title and a text (POST /admin/news/save): the same here, for the preview
  static Map<String, dynamic> build({
    required String title,
    required String text,
    required String? colorName,
    Color? customColor,
    bool shimmer = false,
    String? imageUrl,
    String imageMode = "",
    String? url,
    String author = "",
  }) {
    final onColor = colorName != null && colorName.isNotEmpty;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final background = hasImage && imageMode == "Background", content = hasImage && imageMode == "Content";
    final white = onColor || background;
    return {
      "AuthorUsername": author,
      "PageWidget": "{}",
      "CoverWidget": {
        "type": "column",
        "crossAxisAlignment": "stretch",
        "spacing": 6,
        "children": [
          if (content) contentImageNode(imageUrl),
          {"type": "app_text", "data": title, "style": "header", if (white) "color": "white"},
          if (text.isNotEmpty) {"type": "app_text", "data": text, "style": "primaryText", if (white) "color": "white"},
        ],
      },
      "Metadata": {
        if (onColor) "BackgroundColor": colorName,
        if (white) "ForegroundColor": "white",
        if (onColor && customColor != null) "CustomColor": colorToHex(customColor),
        if (shimmer) "Shimmer": true,
        if (background) "BackgroundImageUrl": imageUrl,
        if (content) "ContentImageUrl": imageUrl,
        if (url != null && url.isNotEmpty) "OnTapUrl": url,
      },
    };
  }

  /// The picture above the title, as the server writes it (Stac's own widgets: the older apps show it too)
  static Map<String, dynamic> contentImageNode(String url) => {
    "type": "clipRRect",
    "borderRadius": {"topLeft": 12, "topRight": 12, "bottomLeft": 12, "bottomRight": 12},
    "child": {"type": "image", "src": url, "imageType": "network", "fit": "cover"},
  };
}

/// An announcement as everyone sees it in the search tab. With [onTap] it does that instead of opening its link.
class NewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  final VoidCallback? onTap;
  final EdgeInsets margin;

  const NewsCard({super.key, required this.news, this.onTap, this.margin = const .only(bottom: AppSpacing.m)});

  @override
  Widget build(BuildContext context) {
    final content = NewsContent(news);
    final metadata = content.metadata;
    final coverWidget = content.coverWidget;
    final pageWidget = content.pageWidget;
    final hasBackgroundImage = content.backgroundImage != null;
    final hasAuthor = content.author != "";
    final backgroundColor = content.color;
    final foregroundColor = AppColors.fromName(metadata["ForegroundColor"]?.toString());
    final onTapUrl = content.url;

    if (coverWidget == null || pageWidget == null) return const SizedBox();
    final isTappable = onTapUrl != null || pageWidget.isNotEmpty;
    const double authorPictureHeight = 30;
    const double trailingButtonHeight = 40;
    final double bottomPadding = max((hasAuthor ? authorPictureHeight + 8 : 0), (isTappable ? trailingButtonHeight + 8 : 0));

    return Button(
      margin: margin,
      // A coloured announcement is filled with its colour (white text on it); a soft wash would not carry it
      transparent: backgroundColor == null,
      padding: .zero,
      color: backgroundColor ?? AppColors.secondaryBackground.adaptTo(context),
      rawChild: Stack(
        children: [
          if (hasBackgroundImage)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: .circular(AppRadius.card),
                child: Stack(
                  fit: .expand,
                  children: [
                    Image.network(content.backgroundImage!, fit: .cover, errorBuilder: (_, _, _) => const SizedBox()),
                    // The white text stays readable on a light picture
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: .topCenter,
                          end: .bottomCenter,
                          colors: [Color(0x26000000), Color(0x8C000000)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: .all(AppSpacing.card),
            margin: .only(bottom: bottomPadding),
            child: Stac.fromJson(coverWidget, context) ?? const SizedBox(),
          ),
          // The light sweeping over it, inside its corners
          if (content.shimmer) Positioned.fill(child: Shimmer(borderRadius: .circular(AppRadius.card))),
          if (hasAuthor)
            Positioned(
              bottom: 8,
              left: 8,
              child: SizedBox.square(
                dimension: authorPictureHeight,
                child: ProfilePictureDisplay(accountUsername: content.author, includeBadge: false),
              ),
            ),
          if (isTappable)
            Positioned(
              bottom: 8,
              right: 8,
              child: Button.icon(
                context,
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: trailingButtonHeight,
                color: backgroundColor,
                iconColor: foregroundColor,
              ),
            ),
        ],
      ),
      onTap:
          onTap ??
          (isTappable
              ? () => onTapUrl != null
                    ? openUrl(onTapUrl, tryApp: true)
                    : showCupertinoSheet(
                        context: context,
                        builder: (context) => Page(
                          topBar: TopBar.tab(context),
                          child: Stac.fromJson(pageWidget, context) ?? Center(child: Text(AppStrings.pageError, style: AppStyles.error(context))),
                        ),
                      )
              // Nothing to open: still a live button, or it would be drawn faded like a disabled one
              : () {}),
    );
  }
}
