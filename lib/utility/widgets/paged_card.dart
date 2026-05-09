import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';

class PagedCard extends StatefulWidget {
  final List<Widget> pages;
  final double height;

  const PagedCard({super.key, required this.pages, this.height = 100});

  @override
  State<PagedCard> createState() => _PagedCardState();
}

class _PagedCardState extends State<PagedCard> {
  late final PageController _controller;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(top: 6, bottom: 20),
      child: CupertinoPressable(
        onTap: null,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          border: .all(color: AppColors.tertiaryBackground.adaptTo(context)),
          borderRadius: .circular(12),
        ),
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: widget.height,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return FractionallySizedBox(widthFactor: 1 / _controller.viewportFraction, child: widget.pages[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: .center,
              children: List.generate(widget.pages.length, (index) {
                final isActive = index == _currentPage;
                return Container(
                  width: isActive ? 5 : 4,
                  height: isActive ? 5 : 4,
                  margin: const .symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: isActive ? AppColors.white : AppColors.white.withAlpha(0.4.toByte()), shape: .circle),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
