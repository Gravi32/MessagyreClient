import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class Page extends StatelessWidget {
  final Widget child;
  final bool canPop;
  final Color? backgroundColor;

  const Page({super.key, required this.child, this.canPop = true, this.backgroundColor});

  factory Page.scrollable(BuildContext context, {required List<Widget> children, bool canPop = true, Color? backgroundColor}) {
    
    return Page(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Container(
        decoration: BoxDecoration(color: backgroundColor ?? AppColors.background.adaptTo(context)),
        child: SafeArea(minimum: const EdgeInsets.symmetric(horizontal: 10), child: child),
      ),
    );
  }
}
