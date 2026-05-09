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
  final bool buildChevron;
  final bool enabled;
  final void Function()? onTap;

  const ListTile({super.key, this.child, this.leading, this.trailing, this.onTap, this.isLoading = false, this.buildChevron = true, this.enabled = true});

  factory ListTile.simple(
    BuildContext context, {
    String? title,
    List<List>? icon,
    void Function()? onTap,
    Widget? trailing,
    bool isLoading = false,
    bool isDestructive = false,
    bool buildChevron = true,
    bool enabled = true,
  }) {
    return ListTile(
      leading: icon != null
          ? HugeIcon(icon: icon, color: enabled ? (isDestructive ? AppColors.red : AppColors.accent) : AppColors.inactive.adaptTo(context))
          : null,
      onTap: onTap,
      trailing: trailing,
      isLoading: isLoading,
      buildChevron: buildChevron,
      enabled: enabled,
      child: title != null
          ? Text(
              title,
              style: AppStyles.primaryText(context).copyWith(color: enabled ? (isDestructive ? AppColors.red : null) : AppColors.inactive.adaptTo(context)),
            )
          : null,
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
      onPressed: widget.enabled ? widget.onTap : null,
      child: Container(
        color: AppColors.secondaryBackground.adaptTo(context).withTransparency(widget.enabled ? .5 : .25),
        padding: .symmetric(horizontal: 24, vertical: 14),
        child: widget.isLoading
            ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
            : Row(
                spacing: 12,
                children: [
                  if (widget.leading != null) widget.leading!,
                  Expanded(child: widget.child ?? SizedBox()),
                  widget.trailing ?? (widget.buildChevron ? const CupertinoListTileChevron() : const SizedBox()),
                ],
              ),
      ),
    );
  }
}
