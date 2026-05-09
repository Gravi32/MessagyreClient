import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';

class TopBar extends StatefulWidget {
  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final bool isSliver;

  const TopBar({super.key, this.leading, this.middle, this.trailing, this.isSliver = false});

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

  factory TopBar.tab(BuildContext context, {String? title}) {
    return TopBar(
      leading: Button.icon(context, icon: HugeIcons.strokeRoundedArrowLeft01, onTap: () => Navigator.pop(context)),
      middle: title != null
          ? Padding(
              padding: .symmetric(horizontal: 8),
              child: Text(title, style: AppStyles.header(context), textAlign: .center),
            )
          : null,
    );
  }

  factory TopBar.sliver({String? title, Widget? leading, Widget? trailing}) {
    return TopBar(middle: title != null ? Text(title) : null, leading: leading, trailing: trailing, isSliver: true);
  }

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.isSliver) {
      return CupertinoSliverNavigationBar(leading: widget.leading, largeTitle: widget.middle, trailing: widget.trailing);
    }

    return Container(
      padding: .symmetric(horizontal: 10, vertical: 8),
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
