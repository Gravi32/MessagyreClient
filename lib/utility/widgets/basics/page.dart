import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

class Page extends StatelessWidget {
  final Widget child;
  final bool canPop;
  final Color? backgroundColor;
  final TopBar? topBar;
  final bool isSliver;
  final List<Widget> Function(BuildContext, bool)? sliverHeaderBuilder;
  final ScrollController? scrollController;

  const Page({
    super.key,
    required this.child,
    this.canPop = true,
    this.backgroundColor,
    this.topBar,
    this.isSliver = false,
    this.sliverHeaderBuilder,
    this.scrollController,
  });

  factory Page.scrollable(BuildContext context, {required List<Widget> children, TopBar? topBar, bool canPop = true, Color? backgroundColor}) {
    return Page(
      backgroundColor: backgroundColor,
      canPop: canPop,
      topBar: topBar,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(mainAxisSize: .min, crossAxisAlignment: .stretch, children: children),
      ),
    );
  }

  factory Page.sliver({required Widget body, required TopBar topBar, ScrollController? controller, bool canPop = true, Color? backgroundColor}) {
    return Page(
      isSliver: true,
      sliverHeaderBuilder: (_, _) => [topBar],
      scrollController: controller,
      canPop: canPop,
      backgroundColor: backgroundColor,
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.background.adaptTo(context);

    return PopScope(
      canPop: canPop,
      child: CupertinoPageScaffold(
        backgroundColor: bgColor,
        child: isSliver
            ? NestedScrollView(
                controller: scrollController,
                headerSliverBuilder: sliverHeaderBuilder!,
                body: SafeArea(top: false, minimum: .symmetric(horizontal: 10), child: child),
              )
            : SafeArea(
                minimum: const .symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    if (topBar != null) topBar!,
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: bgColor),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
