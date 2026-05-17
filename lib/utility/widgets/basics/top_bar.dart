import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
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

  const TopBar({super.key, this.leading, this.middle, this.trailing, this.field, this.isSliver = false});

  factory TopBar.form(BuildContext context, {String? title, void Function()? onPop, void Function()? onCloseConfirmed, Widget? trailing}) {
    return TopBar(
      leading: Button.icon(
        context,
        icon: HugeIcons.strokeRoundedCancel01,
        onTap: () {
          if (onCloseConfirmed == null) {
            (onPop ?? () => Navigator.pop(context)).call();
            return;
          }

          showCupertinoDialog(
            context: context,
            builder: (context) {
              return Dialog.confirm(
                content: "Voulez-vous vraiment *annuler*? Cette action est irréversible.",
                isDestructive: true,
                onConfirm: () => onCloseConfirmed.call(),
              );
            },
          );
        },
      ),
      middle: title != null ? Text(title, style: AppStyles.header(context), textAlign: .center) : null,
      trailing: trailing,
    );
  }

  factory TopBar.tab(BuildContext context, {String? title, bool buildChevron = true}) {
    return TopBar(
      leading: buildChevron ? Button.icon(context, icon: HugeIcons.strokeRoundedArrowLeft01, onTap: () => Navigator.pop(context)) : null,
      middle: title != null
          ? Padding(
              padding: .symmetric(horizontal: 8),
              child: Text(title, style: AppStyles.header(context), textAlign: .center),
            )
          : null,
    );
  }

  factory TopBar.sliver({required String title, Widget? leading, Widget? trailing, Field? field}) {
    return TopBar(middle: Text(title), leading: leading, trailing: trailing, field: field, isSliver: true);
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
      leading: Button.icon(context, margin: .only(bottom: 2), icon: HugeIcons.strokeRoundedArrowLeft01, onTap: () => Navigator.pop(context)),
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
        trailing: widget.trailing,
        backgroundColor: AppColors.background.adaptTo(context),
        bottom: widget.field != null
            ? PreferredSize(
                preferredSize: const .fromHeight(60),
                child: Padding(padding: .symmetric(horizontal: 8).add(.only(bottom: 8)), child: widget.field!),
              )
            : null,
      );
    }

    return Container(
      padding: .symmetric(vertical: 8),
      height: 60,
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
