import 'package:flutter/material.dart' hide ListTile;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

class ListSection extends StatelessWidget {
  final List<ListTile>? children;
  final String? title;
  final EdgeInsets? margin;

  const ListSection({super.key, this.children, this.title, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? .zero,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (title != null)
            Padding(
              padding: .symmetric(horizontal: 16).add(.only(bottom: 8)),
              child: Text(title!, style: AppStyles.secondaryHeader(context)),
            ),
          RoundContainer(
            padding: .zero,
            blurOnly: true,
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: .zero,
              itemCount: children?.length ?? 0,
              itemBuilder: (context, index) => children?[index],
              separatorBuilder: (context, _) => Divider(thickness: .5, height: 0, color: AppColors.tertiaryBackground.adaptTo(context)),
            ),
          ),
        ],
      ),
    );
  }
}
