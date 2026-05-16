import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';

class FieldHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Field field;
  const FieldHeaderDelegate({required this.field});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background.adaptTo(context), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: field);
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(FieldHeaderDelegate oldDelegate) => oldDelegate.field != field;
}
