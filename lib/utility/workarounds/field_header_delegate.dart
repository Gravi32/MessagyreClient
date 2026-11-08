import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';

/// The search bar pinned under a page's large title. Its height comes from the field's own fixed height,
/// so the field always fits (a fixed 64 px with a taller field used to overflow at the bottom).
class FieldHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Field field;
  const FieldHeaderDelegate({required this.field});

  static const double _verticalPadding = AppSpacing.s;

  double get _extent => Field.heightOf(thin: field.thin) + 2 * _verticalPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background.adaptTo(context),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: _verticalPadding),
      alignment: Alignment.center,
      child: field,
    );
  }

  @override
  double get maxExtent => _extent;

  @override
  double get minExtent => _extent;

  @override
  bool shouldRebuild(FieldHeaderDelegate oldDelegate) => oldDelegate.field != field;
}
