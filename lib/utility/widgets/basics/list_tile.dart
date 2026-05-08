import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';

class ListTile extends StatefulWidget {
  final Widget? child;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final void Function()? onTap;

  const ListTile({super.key, this.child, this.leading, this.trailing, this.onTap, this.isLoading = false});

  factory ListTile.simple(BuildContext context, {String? title, List<List>? icon, void Function()? onTap, Widget? trailing, bool isLoading = false}) {
    return ListTile(
      leading: icon != null ? HugeIcon(icon: icon) : null,
      onTap: onTap,
      trailing: trailing,
      isLoading: isLoading,
      child: title != null ? Text(title, style: AppStyles.primaryText(context)) : null,
    );
  }

  @override
  State<ListTile> createState() => _ListTileState();
}

class _ListTileState extends State<ListTile> {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: .zero,
      minimumSize: .fromHeight(36),
      onPressed: () => widget.onTap?.call(),
      child: Container(
        color: AppColors.secondaryBackground.adaptTo(context).withTransparency(.5),
        padding: .symmetric(horizontal: 24, vertical: 14),
        child: widget.isLoading
            ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
            : Row(
                spacing: 12,
                children: [
                  if (widget.leading != null) widget.leading!,
                  Expanded(child: widget.child ?? SizedBox()),
                  widget.trailing ?? CupertinoListTileChevron(),
                ],
              ),
      ),
    );
  }
}
