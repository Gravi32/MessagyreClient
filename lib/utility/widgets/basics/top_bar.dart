import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';

class TopBar extends StatefulWidget {
  final Widget? leading;
  final Widget? middle;

  const TopBar({super.key, this.leading, this.middle});

  factory TopBar.form(BuildContext context, {String? title, void Function()? onPop, void Function()? onCloseConfirmed}) {
    return TopBar(
      leading: Button.icon(
        icon: HugeIcons.strokeRoundedCancel01,
        transparent: true,
        color: AppColors.secondaryButton.adaptTo(context),
        iconColor: AppColors.text.adaptTo(context),
        onTap: () {
          if (onCloseConfirmed == null) {
            onPop?.call();
            return;
          }

          showCupertinoDialog(
            context: context,
            builder: (context) {
              return Dialog.confirm(
                content: "Voulez-vous vraiment *annuler la procédure*? Cette action est irréversible.",
                isDestructive: true,
                onConfirm: () => onCloseConfirmed.call(),
              );
            },
          );
        },
      ),
      middle: title != null ? Text(title, style: AppStyles.header(context), textAlign: .center) : null,
    );
  }

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: .symmetric(horizontal: 10, vertical: 4),
      height: 60,
      child: Row(
        children: [
          if (widget.leading != null) widget.leading!,
          if (widget.middle != null) Expanded(child: widget.middle!),
          if (widget.leading != null) AspectRatio(aspectRatio: 1),
        ],
      ),
    );
  }
}
