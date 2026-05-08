import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

class Page extends StatelessWidget {
  final Widget child;
  final bool canPop;
  final Color? backgroundColor;
  final TopBar? navigationBar;

  const Page({super.key, required this.child, this.canPop = true, this.backgroundColor, this.navigationBar});

  factory Page.scrollable(BuildContext context, {required List<Widget> children, bool canPop = true, Color? backgroundColor}) {
    return Page(
      child: SingleChildScrollView(
        padding: .symmetric(vertical: 20),
        child: Column(mainAxisSize: .min, crossAxisAlignment: .stretch, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? AppColors.background.adaptTo(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              if (navigationBar != null) navigationBar!,
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: backgroundColor ?? AppColors.background.adaptTo(context)),
                  child: SafeArea(minimum: const .symmetric(horizontal: 10), child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
