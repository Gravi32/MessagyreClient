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
  static Map<String, dynamic> build({required String title, required String text, required String? colorName, String? url, String author = ""}) {
    final onColor = colorName != null && colorName.isNotEmpty;
    return {
      "AuthorUsername": author,
      "PageWidget": "{}",
      "CoverWidget": {
        "type": "column",
        "crossAxisAlignment": "stretch",
        "spacing": 6,
        "children": [
          {"type": "app_text", "data": title, "style": "header", if (onColor) "color": "white"},
          if (text.isNotEmpty) {"type": "app_text", "data": text, "style": "primaryText", if (onColor) "color": "white"},
        ],
      },
      "Metadata": {if (onColor) "BackgroundColor": colorName, if (onColor) "ForegroundColor": "white", if (url != null && url.isNotEmpty) "OnTapUrl": url},
    };
  }
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
    final hasBackgroundImage = metadata["BackgroundImageUrl"] != null;
    final hasAuthor = content.author != "";
    final backgroundColor = AppColors.fromName(content.colorName);
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
                child: Image.network(metadata["BackgroundImageUrl"].toString(), fit: .cover, errorBuilder: (_, _, _) => const SizedBox()),
              ),
            ),
          Container(
            padding: .all(AppSpacing.card),
            margin: .only(bottom: bottomPadding),
            child: Stac.fromJson(coverWidget, context) ?? const SizedBox(),
          ),
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
