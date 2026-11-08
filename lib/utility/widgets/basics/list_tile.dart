import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';

class ListTile extends StatefulWidget {
  final Widget? child;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool buildChevron;
  final bool enabled;
  final EdgeInsets? padding;
  final void Function()? onTap;

  const ListTile({
    super.key,
    this.child,
    this.leading,
    this.trailing,
    this.onTap,
    this.isLoading = false,
    this.buildChevron = true,
    this.enabled = true,
    this.padding,
  });

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
          ? ListTile.iconTile(context, icon: icon, color: enabled ? (isDestructive ? AppColors.red : null) : AppColors.inactive.adaptTo(context))
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

  /// A row's icon, in a small rounded square: grey, or washed with its color when it has one (red to delete)
  static Widget iconTile(BuildContext context, {required List<List> icon, Color? color}) {
    return Container(
      width: 32,
      height: 32,
      alignment: .center,
      decoration: BoxDecoration(
        borderRadius: .circular(9),
        color: color == null ? AppColors.tertiaryBackground.adaptTo(context) : color.withValues(alpha: AppColors.isDark(context) ? .2 : .12),
      ),
      child: HugeIcon(icon: icon, size: 18, color: color ?? AppColors.text.adaptTo(context)),
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
        color: AppColors.secondaryBackground.adaptTo(context),
        padding: widget.padding ?? .symmetric(horizontal: 16, vertical: 13),
        child: Row(
          spacing: 14,
          children: widget.isLoading
              ? [Expanded(child: Center(child: GymnaseLoader(size: 22)))]
              : [
                  if (widget.leading != null) widget.leading!,
                  Expanded(child: widget.child ?? SizedBox()),
                  if (widget.enabled && (widget.trailing != null || widget.buildChevron)) widget.trailing ?? const CupertinoListTileChevron(),
                ],
        ),
      ),
    );
  }
}
