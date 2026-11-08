import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class TopBar extends StatefulWidget {
  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final Field? field;
  final bool isSliver;

  /// The title of a sliver bar once collapsed, when [middle] (its large title) is more than a text
  final Widget? collapsedMiddle;

  /// Hero animation between routes. Must be off for the bars of the main tabs: they live
  /// together in the same PageView, and several bars with the default hero tag in one
  /// route make Flutter throw "multiple heroes that share the same tag".
  final bool transitionBetweenRoutes;

  const TopBar({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.field,
    this.isSliver = false,
    this.collapsedMiddle,
    this.transitionBetweenRoutes = true,
  });

  factory TopBar.form(BuildContext context, {String? title, void Function()? onPop, void Function()? onCloseConfirmed, Widget? trailing}) {
    return TopBar(
      leading: Button.icon(
        context,
        icon: AppIcons.close,
        onTap: () {
          if (onCloseConfirmed == null) {
            (onPop ?? () => Navigator.pop(context)).call();
            return;
          }

          showCupertinoDialog(
            context: context,
            builder: (context) {
              return Dialog.confirm(content: AppStrings.confirmCancel, isDestructive: true, onConfirm: () => onCloseConfirmed.call());
            },
          );
        },
      ),
      middle: title != null ? Text(title, style: AppStyles.barTitle(context), textAlign: .center, maxLines: 1, overflow: .ellipsis) : null,
      trailing: trailing,
    );
  }

  factory TopBar.tab(BuildContext context, {String? title, bool buildChevron = true}) {
    return TopBar(
      leading: buildChevron ? Button.icon(context, icon: AppIcons.back, onTap: () => Navigator.pop(context)) : null,
      middle: title != null
          ? Padding(
              padding: .symmetric(horizontal: 8),
              child: Text(title, style: AppStyles.barTitle(context), textAlign: .center, maxLines: 1, overflow: .ellipsis),
            )
          : null,
    );
  }

  /// The bar of the main tabs: a large title that shrinks on scroll
  factory TopBar.sliver({required String title, Widget? leading, Widget? trailing, Field? field}) {
    return TopBar(
      middle: Text(title, maxLines: 1, overflow: .ellipsis),
      collapsedMiddle: Text(title),
      leading: leading,
      trailing: trailing,
      field: field,
      isSliver: true,
      transitionBetweenRoutes: false,
    );
  }

  factory TopBar.sliverWithChevron(BuildContext context, {required String title, List<List>? icon, Widget? trailing}) {
    return TopBar(
      middle: Row(
        spacing: 8,
        children: [
          if (icon != null) CustomIcon(icon: icon, strokeWidth: 1.5),
          Text(title),
        ],
      ),
      leading: Button.icon(context, margin: .only(bottom: 2), icon: AppIcons.back, onTap: () => Navigator.pop(context)),
      isSliver: true,
      trailing: trailing,
    );
  }

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.isSliver) {
      return CupertinoSliverNavigationBar(
        leading: widget.leading,
        largeTitle: widget.middle,
        middle: widget.collapsedMiddle,
        alwaysShowMiddle: widget.collapsedMiddle == null,
        trailing: widget.trailing,
        transitionBetweenRoutes: widget.transitionBetweenRoutes,
        backgroundColor: AppColors.background.adaptTo(context),
        border: null,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.page - 4),
        bottom: widget.field != null
            ? PreferredSize(
                preferredSize: const .fromHeight(60),
                child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s), child: widget.field!),
              )
            : null,
      );
    }

    return Container(
      padding: const .symmetric(vertical: AppSpacing.s),
      height: AppSizes.topBar,
      child: Row(
        children: [
          if ((widget.leading ?? widget.trailing) != null) widget.leading ?? AspectRatio(aspectRatio: 1),
          Expanded(child: widget.middle ?? SizedBox()),
          if ((widget.leading ?? widget.trailing) != null) widget.trailing ?? AspectRatio(aspectRatio: 1),
        ],
      ),
    );
  }
}
