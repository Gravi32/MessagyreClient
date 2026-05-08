import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/cutout_widget.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainPage.pageIndex,
      builder: (context, currentIndex, _) => Container(
        height: 100,
        alignment: .bottomCenter,
        padding: .only(bottom: 10, top: 2, left: 2, right: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topCenter,
            end: .bottomCenter,
            colors: [AppColors.background.adaptTo(context).withTransparency(0), AppColors.background.adaptTo(context)],
            stops: [0, .4],
          ),
        ),

        child: SafeArea(
          child: Row(
            mainAxisAlignment: .spaceAround,
            crossAxisAlignment: .stretch,
            children: App.pages.mapIndexed((index, page) {
              final isSelected = index == currentIndex;
              final color = (isSelected ? AppColors.text : AppColors.secondaryText).adaptTo(context);
              final icon = Button.icon(
                icon: page.icon,
                transparent: true,
                color: AppColors.secondaryButton.adaptTo(context),
                iconColor: isSelected ? AppColors.text.adaptTo(context) : null,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: showNotification
                                ? CutoutWidget(
                                    cutoutSize: 12,
                                    childToCutout: icon,
                                    childInCutout: Container(
                                      margin: EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                    ),
                                    cutoutAlignment: Alignment.topRight,
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
      ),
    );
  }
}
