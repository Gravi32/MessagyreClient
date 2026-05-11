import 'package:flutter/material.dart' hide ListTile;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class ListSection extends StatelessWidget {
  final List<ListTile>? children;
  final String? title;
  final String? footer;
  final EdgeInsets? margin;
  final bool useLargeTitle;

  const ListSection({super.key, this.children, this.title, this.footer, this.margin, this.useLargeTitle = false});

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
              child: Text(title!, style: useLargeTitle ? AppStyles.header(context) : AppStyles.secondaryHeader(context)),
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
          if (footer != null)
            Padding(
              padding: .symmetric(horizontal: 16).add(.only(top: 8)),
              child: CustomText(footer!, style: AppStyles.footer(context)),
            ),
        ],
      ),
    );
  }
}
