import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';

/// One choice of an [ActionSheet]
class SheetAction<T> {
  final String text;
  final List<List>? icon;
  final T value;
  final bool isDestructive;

  const SheetAction(this.text, {required this.value, this.icon, this.isDestructive = false});
}

/// The menus that rise from the bottom (a photo's source, a message's actions): a card of rows in the app's colors,
/// and "Annuler" apart. Pops the chosen [SheetAction.value], or null.
class ActionSheet<T> extends StatelessWidget {
  final String? title;
  final String? message;

  /// Above the choices instead of [message] (a preview of the message being acted on)
  final Widget? header;
  final List<SheetAction<T>> actions;

  const ActionSheet({super.key, this.title, this.message, this.header, required this.actions});

  static Future<T?> show<T>(BuildContext context, {String? title, String? message, Widget? header, required List<SheetAction<T>> actions}) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (_) => ActionSheet<T>(title: title, message: message, header: header, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.secondaryBackground.adaptTo(context);
    final outline = AppColors.outline.adaptTo(context);
    final hasHeader = title != null || message != null || header != null;

    BoxDecoration card() => BoxDecoration(
      color: surface,
      borderRadius: .circular(AppRadius.card),
      border: .all(color: outline),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: AppColors.isDark(context) ? .4 : .12),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return SafeArea(
      top: false,
      minimum: const .fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.l),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.s,
        children: [
          Container(
            clipBehavior: .antiAlias,
            decoration: card(),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                if (hasHeader)
                  Padding(
                    padding: const .fromLTRB(AppSpacing.xl, AppSpacing.l, AppSpacing.xl, AppSpacing.l),
                    child: Column(
                      spacing: AppSpacing.xs,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            textAlign: .center,
                            style: AppStyles.strongText(context).copyWith(fontSize: AppStyles.sizeSubheadline),
                          ),
                        if (message != null) Text(message!, textAlign: .center, style: AppStyles.footnote(context).copyWith(height: 1.35)),
                        ?header,
                      ],
                    ),
                  ),
                for (final (index, action) in actions.indexed) ...[
                  if (index > 0 || hasHeader) Container(height: .5, color: AppColors.separator.adaptTo(context)),
                  _Row(action: action),
                ],
              ],
            ),
          ),
          // Cancel, apart
          Container(
            clipBehavior: .antiAlias,
            decoration: card(),
            child: CupertinoButton(
              padding: const .symmetric(vertical: 17),
              minimumSize: .zero,
              pressedOpacity: .5,
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel, style: AppStyles.button(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row<T> extends StatelessWidget {
  final SheetAction<T> action;

  const _Row({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? AppColors.red : AppColors.text.adaptTo(context);

    return CupertinoButton(
      padding: const .symmetric(horizontal: AppSpacing.xl, vertical: 16),
      minimumSize: .zero,
      pressedOpacity: .5,
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context, action.value);
      },
      child: Row(
        spacing: AppSpacing.l,
        children: [
          if (action.icon != null)
            HugeIcon(icon: action.icon!, size: 22, color: action.isDestructive ? AppColors.red : AppColors.secondaryText.adaptTo(context)),
          Expanded(
            child: Text(action.text, style: AppStyles.primaryText(context).copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
