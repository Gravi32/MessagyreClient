import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/graphics/cutout_widget.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return ValueListenableBuilder<int>(
      valueListenable: MainPage.pageIndex,
      builder: (context, currentIndex, _) => Container(
        height: bottomPadding + 80,
        alignment: .bottomCenter,
        padding: .only(bottom: bottomPadding + 10, top: 2, left: 2, right: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topCenter,
            end: .bottomCenter,
            colors: [AppColors.background.adaptTo(context).withTransparency(0), AppColors.background.adaptTo(context)],
            stops: [0, .4],
          ),
        ),

        child: Row(
          mainAxisAlignment: .spaceAround,
          crossAxisAlignment: .stretch,
          children: App.pages.mapIndexed((index, page) {
            final isSelected = index == currentIndex;
            final color = (isSelected ? AppColors.text : AppColors.secondaryText).adaptTo(context);
            final icon = Button.icon(
              context,
              icon: page.icon,
              iconColor: isSelected ? null : AppColors.secondaryButton.adaptTo(context),
              onTap: () => MainPage.pageIndex.value = index,
            );

            return Padding(
              padding: .all(2),
              child: AspectRatio(
                aspectRatio: 1,
                child: ValueListenableBuilder(
                  valueListenable: page.showBadge,
                  builder: (context, showNotification, _) {
                    return Column(
                      mainAxisAlignment: .center,
                      crossAxisAlignment: .center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: showNotification
                              ? CutoutWidget(
                                  cutoutSize: 12,
                                  childToCutout: icon,
                                  childInCutout: Container(
                                    margin: .all(2.5),
                                    decoration: BoxDecoration(color: AppColors.accent, shape: .circle),
                                  ),
                                  cutoutAlignment: .topRight,
                                )
                              : icon,
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              page.name,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(fontSize: 10, color: color),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
