import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/services/biometrics_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/workarounds/field_header_delegate.dart';

class Page extends StatefulWidget {
  final Widget child;
  final TopBar? topBar;

  final bool canPop;
  final bool isSliver;
  final bool ignorePadding;
  final bool requireFaceId;
  final ValueNotifier<int>? lockNotifier;

  final int? pageIndex;
  final Color? backgroundColor;
  final ScrollController? scrollController;

  final List<Widget> Function(BuildContext, bool)? sliverHeaderBuilder;
  final void Function()? onFloatingButtonTap;
  final Future<void> Function()? onRefresh;

  const Page({
    super.key,
    required this.child,
    this.topBar,

    this.canPop = true,
    this.isSliver = false,
    this.ignorePadding = false,
    this.requireFaceId = false,
    this.lockNotifier,

    this.pageIndex,
    this.backgroundColor,
    this.scrollController,

    this.sliverHeaderBuilder,
    this.onFloatingButtonTap,
    this.onRefresh,
  });

  factory Page.scrollable(
    BuildContext context, {
    required List<Widget> children,
    TopBar? topBar,
    bool canPop = true,
    Color? backgroundColor,
    double spacing = 0,
  }) {
    return Page(
      backgroundColor: backgroundColor,
      canPop: canPop,
      topBar: topBar,
      child: SingleChildScrollView(
        padding: const .symmetric(vertical: 20),
        child: Column(mainAxisSize: .min, crossAxisAlignment: .stretch, spacing: spacing, children: children),
      ),
    );
  }

  factory Page.sliver({
    required Widget body,
    required TopBar topBar,
    Field? field,
    ScrollController? controller,
    bool canPop = true,
    bool requireFaceId = false,
    ValueNotifier<int>? lockNotifier,
    int? pageIndex,
    Color? backgroundColor,
    void Function()? onFloatingButtonTap,
    Future<void> Function()? onRefresh,
  }) {
    return Page(
      isSliver: true,
      sliverHeaderBuilder: (_, innerBoxIsScrolled) => [
        topBar,
        if (field != null) SliverPersistentHeader(pinned: true, delegate: FieldHeaderDelegate(field: field)),
      ],
      scrollController: controller,
      canPop: canPop,
      requireFaceId: requireFaceId,
      lockNotifier: lockNotifier,
      pageIndex: pageIndex,
      backgroundColor: backgroundColor,
      onFloatingButtonTap: onFloatingButtonTap,
      onRefresh: onRefresh,
      child: body,
    );
  }

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  final globals = GlobalsService();
  final biometrics = BiometricsService();

  late bool isUnlocked = false;
  late bool authInProgress = false;
  late bool authFailed = false;

  @override
  void initState() {
    super.initState();
    widget.lockNotifier?.addListener(
      () => setState(() {
        isUnlocked = false;
        authFailed = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding = const .symmetric(horizontal: 10);
    final bgColor = widget.backgroundColor ?? AppColors.background.adaptTo(context);
    final authOverlayOpacity = isUnlocked ? 0 : 1;

    if (widget.requireFaceId && MainPage.pageIndex.value == widget.pageIndex && !isUnlocked && !authInProgress && !authFailed) {
      authInProgress = true;
      biometrics.authenticate().then(
        (unlocked) => setState(() {
          authInProgress = false;
          unlocked ? isUnlocked = true : authFailed = true;
        }),
      );
    }

    return PopScope(
      canPop: widget.canPop,
      child: CupertinoPageScaffold(
        backgroundColor: bgColor,
        child: Stack(
          children: [
            widget.isSliver
                ? NestedScrollView(
                    controller: widget.scrollController,
                    headerSliverBuilder: widget.sliverHeaderBuilder!,
                    physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    body: widget.onRefresh != null
                        ? CustomScrollView(
                            slivers: [
                              CupertinoSliverRefreshControl(onRefresh: widget.onRefresh!),
                              SliverToBoxAdapter(
                                child: SafeArea(top: false, minimum: padding, child: widget.child),
                              ),
                            ],
                          )
                        : SafeArea(top: false, minimum: padding, child: widget.child),
                  )
                : SafeArea(
                    minimum: widget.ignorePadding ? .zero : padding,
                    child: Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        if (widget.topBar != null) SafeArea(minimum: widget.ignorePadding ? padding : .zero, child: widget.topBar!),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: bgColor),
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
            if (widget.onFloatingButtonTap != null)
              Positioned(
                bottom: MediaQuery.viewPaddingOf(context).bottom + 90,
                right: 13,
                child: SizedBox(
                  height: 50,
                  child: Button.icon(context, icon: HugeIcons.strokeRoundedAdd01, onTap: () => widget.onFloatingButtonTap!()),
                ),
              ),

            if (widget.requireFaceId)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: authOverlayOpacity == 0,
                  child: AnimatedOpacity(
                    opacity: authOverlayOpacity.toDouble(),
                    curve: Curves.easeInOutQuart,
                    duration: Duration(milliseconds: 200),
                    child: BlurredContainer(
                      blur: 24,
                      padding: .all(24),
                      child: authInProgress
                          ? null
                          : Column(
                              mainAxisAlignment: .center,
                              spacing: 16,
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedFaceId, size: 36),
                                Text("Page bloquée", style: AppStyles.header(context)),

                                const SizedBox(height: 16),

                                Text(
                                  "Cette page est confidentielle,\nauthentifiez-vous avec le FaceID pour continuer.",
                                  style: AppStyles.primaryText(context),
                                  textAlign: .center,
                                ),
                                Text("Vous pouvez désactiver cet écran dans les réglages.", style: AppStyles.tertiaryText(context), textAlign: .center),

                                const SizedBox(height: 16),

                                Button(text: "FaceID", transparent: true, onTap: () => setState(() => authFailed = false)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
