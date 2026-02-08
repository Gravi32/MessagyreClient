import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/pages/assignments.dart';
import 'package:messagyre_client/pages/chats.dart';
import 'package:messagyre_client/pages/grades.dart';
import 'package:messagyre_client/pages/search.dart';
import 'package:messagyre_client/pages/settings.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/notifications_controller.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/other/lifecycle_handler.dart';
import 'package:messagyre_client/other/firebase_api.dart';
import 'package:messagyre_client/other/terms_of_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messagyre_client/utility/utility.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print override
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    Data().log(message);
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  await ConnectionController().checkLocalhostAvailability();

  runZonedGuarded(
    () async {
      try {
        // Hive setup
        await Hive.initFlutter();
        Hive.registerAdapter(MessageAdapter());
        Hive.registerAdapter(ChatAdapter());
        Hive.registerAdapter(AssignmentAdapter());
        Hive.registerAdapter(SubjectAdapter());
        Hive.registerAdapter(GradeAdapter());
        Hive.registerAdapter(SettingsAdapter());

        await Hive.openBox<Chat>("Chats");
        await Hive.openBox<Assignment>("Assignment");
        await Hive.openBox<Grade>("Grades");
        await Hive.openBox<List>("SubjectOrder");
        await Hive.openBox<Settings>("Settings");

        initMessageNotifiers();
        final data = Data(); // DATA IS TO BE CALLED AFTER HIVE INITIALIZATION

        // Misc data
        try {
          final miscBox = await Hive.openBox("Misc");
          data.username = miscBox.get("Username")?.toString();
        } catch (e) {
          debugPrint("Misc box could not be opened: $e");
        }

        try {
          await Hive.openBox("RegistrationData");
        } catch (e) {
          debugPrint("RegistrationData box could not be opened: $e");
        }

        data.appBrightnessNotifier.value = Brightness.dark;

        // Firebase
        try {
          await Firebase.initializeApp();
          await FirebaseApi().initialize();
        } catch (e) {
          debugPrint("Firebase could not be initialized: $e");
        }

        // Initialize date formatting
        await initializeDateFormatting('fr_CH', null);

        // System UI
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );

        runApp(Phoenix(child: LifecycleHandler(child: App())));
      } catch (e, stack) {
        debugPrint("Error during initialization: $e");
        debugPrint(stack.toString());
      }
    },
    (error, stack) {
      debugPrint("UNCAUGHT ERROR: $error");
      debugPrint(stack.toString());
      Data().log("UNCAUGHT ERROR: $error\n$stack");
    },
  );
}

class App extends StatelessWidget {
  App({super.key});
  final data = Data();

  static List<AppPage> pages = [
    AppPage(name: "Notes", icon: HugeIcons.strokeRoundedCheckmarkBadge04, build: () => GradesPage()),
    AppPage(name: "Dévoirs", icon: HugeIcons.strokeRoundedWork, build: () => AssignmentPage(key: assignmentPageKey)),
    AppPage(name: "Conversations", icon: HugeIcons.strokeRoundedMessageMultiple02, build: () => ChatsPage()),
    AppPage(name: "Recherche", icon: HugeIcons.strokeRoundedSearch01, build: () => SearchPage()),
    AppPage(name: "Réglages", icon: HugeIcons.strokeRoundedSettings05, build: () => SettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: data.appBrightnessNotifier,
      builder: (context, brightness, _) {
        return CupertinoApp(
          navigatorKey: navigatorKey,
          theme: CupertinoThemeData(brightness: brightness, primaryColor: const Color(0xFFAB0CB3)),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr'), Locale('fr', 'CH')],
          locale: Locale('fr', 'CH'),
          home: const MainPage(),
        );
      },
    );
  }
}

class AppPage {
  final String name;
  final List<List<dynamic>> icon;
  final Widget Function() build;

  const AppPage({required this.name, required this.icon, required this.build});
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final ValueNotifier<int> pageIndex = ValueNotifier<int>(2);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final router = ConnectionController();
  late final data = Data();
  late final PageController pageController;
  late final List<Widget> builtPages;
  bool isAnimating = false;

  void swipeToPage() {
    if (isAnimating) return;
    isAnimating = true;
    pageController
        .animateToPage(MainPage.pageIndex.value, duration: const Duration(milliseconds: 200), curve: Curves.fastEaseInToSlowEaseOut)
        .then((_) => isAnimating = false);
  }

  @override
  void initState() {
    super.initState();

    router.start();
    WidgetsBinding.instance.addObserver(this);

    pageController = PageController(initialPage: MainPage.pageIndex.value);

    // Wrap every page build in try/catch to avoid crashing the whole PageView
    builtPages =
        App.pages.map((p) {
          try {
            return KeepAliveWrapper(child: p.build());
          } catch (e, stack) {
            debugPrint("Error building page ${p.name}: $e");
            debugPrint(stack.toString());
            return Container(color: CupertinoColors.systemRed);
          }
        }).toList();

    MainPage.pageIndex.addListener(swipeToPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationController().init(context);
      askUserToAcceptEula(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    MainPage.pageIndex.dispose();
    router.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: pageController,
        allowImplicitScrolling: true,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (!isAnimating) MainPage.pageIndex.value = index;
        },
        children: builtPages,
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: MainPage.pageIndex,
        builder:
            (context, currentIndex, _) => CustomNavigationBar(
              isFloating: true,
              borderRadius: const Radius.circular(12),
              backgroundColor: CupertinoColors.secondarySystemBackground.resolveFrom(context),
              strokeColor: CupertinoColors.transparent,
              selectedColor: CupertinoColors.label.resolveFrom(context),
              currentIndex: currentIndex,
              onTap: (index) => MainPage.pageIndex.value = index,
              items:
                  App.pages
                      .map(
                        (page) => CustomNavigationBarItem(
                          icon: HugeIcon(icon: page.icon),
                          selectedIcon: HugeIcon(icon: page.icon, strokeWidth: 1.5),
                          title: Text(
                            page.name,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(fontSize: 10, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                          ),
                          selectedTitle: Text(
                            page.name,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(fontSize: 10, color: CupertinoColors.label.resolveFrom(context)),
                          ),
                        ),
                      )
                      .toList(),
            ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({required this.child, super.key});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
