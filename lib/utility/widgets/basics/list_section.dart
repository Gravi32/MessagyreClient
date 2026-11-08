import 'package:flutter/material.dart' hide ListTile;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
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
              padding: .symmetric(horizontal: 4).add(.only(bottom: 10)),
              child: Text(title!, style: useLargeTitle ? AppStyles.header(context) : AppStyles.section(context)),
            ),
          RoundContainer(
            padding: .zero,
            borderRadius: AppRadius.card,
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: .zero,
              itemCount: children?.length ?? 0,
              itemBuilder: (context, index) => children?[index],
              // Under the text, as on iOS: past the icon when the row below has one
              separatorBuilder: (context, index) => Container(
                height: .5,
                margin: .only(left: children?[index + 1].leading != null ? 62 : 16),
                color: AppColors.separator.adaptTo(context),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: .symmetric(horizontal: 4).add(.only(top: 8)),
              child: CustomText(footer!, style: AppStyles.footer(context)),
            ),
        ],
      ),
    );
  }
}
