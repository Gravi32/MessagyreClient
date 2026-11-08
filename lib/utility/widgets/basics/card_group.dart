import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

/// Rows (grades, subjects, assignments) grouped in one card, separated by a hairline that starts under their text:
/// lighter than a card per row.
class CardGroup extends StatelessWidget {
  final List<Widget> children;

  /// Where the separators start (past the rows' leading figure)
  final double separatorInset;
  final EdgeInsets? margin;

  const CardGroup({super.key, required this.children, this.separatorInset = AppSpacing.l, this.margin});

  @override
  Widget build(BuildContext context) {
    final separator = AppColors.separator.adaptTo(context);
    return RoundContainer(
      padding: .zero,
      margin: margin,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0)
              Container(
                height: .5,
                margin: .only(left: separatorInset),
                color: separator,
              ),
            child,
          ],
        ],
      ),
    );
  }
}
