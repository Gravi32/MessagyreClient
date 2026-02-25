import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/main.dart';

class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainPage.pageIndex,
      builder:
          (context, currentIndex, _) => Container(
            height: 60,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    App.pages.mapIndexed((index, page) {
                      final color = (index == currentIndex ? AppColors.text : AppColors.secondaryText).adaptTo(context);
                      return AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => MainPage.pageIndex.value = index,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              HugeIcon(icon: page.icon, color: color),
                              Text(page.name, overflow: TextOverflow.fade, softWrap: false, style: TextStyle(fontSize: 10, color: color)),
                            ],
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
