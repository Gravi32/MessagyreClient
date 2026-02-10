import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/pages/assignments/assignments_list_page.dart';
import 'package:messagyre_client/pages/chats/chats_list_page.dart';
import 'package:messagyre_client/pages/grades/grades_list_page.dart';
import 'package:messagyre_client/pages/search/search_page.dart';
import 'package:messagyre_client/pages/settings/settings_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:messagyre_client/utility/__database_migration__.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/services/lifecycle_service.dart';
import 'package:messagyre_client/services/firebase_api_service.dart';
import 'package:messagyre_client/pages/bootstrap/terms_of_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  //FlutterError.onError = (details) => FlutterError.dumpErrorToConsole(details);

  WidgetsFlutterBinding.ensureInitialized();

  // Print override
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    GlobalsService().log(message);
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  await NetworkService().checkLocalhostAvailability();

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
        await Hive.openBox<Assignment>("Homework");
        await Hive.openBox<Grade>("Grades");
        await Hive.openBox<List>("SubjectOrder");
        await Hive.openBox<Settings>("Settings");

        // --- HIVE → ISAR MIGRATION ---
        await DatabaseService().init();
        await migrateHiveToIsar();

        //initMessageNotifiers();
        final globals = GlobalsService(); // DATA IS TO BE CALLED AFTER HIVE INITIALIZATION

        // Misc data
        try {
          final miscBox = await Hive.openBox("Misc");
          globals.username = miscBox.get("Username")?.toString();
        } catch (e) {
          debugPrint("Misc box could not be opened: $e");
        }

        try {
          await Hive.openBox("RegistrationData");
        } catch (e) {
          debugPrint("RegistrationData box could not be opened: $e");
        }

        globals.appBrightnessNotifier.value = Brightness.dark;

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

        runApp(Phoenix(child: LifecycleService(child: App())));
      } catch (e, stack) {
        debugPrint("Error during initialization: $e");
        debugPrint(stack.toString());
      }
    },
    (error, stack) {
      debugPrint("UNCAUGHT ERROR: $error");
      debugPrint(stack.toString());
    },
  );
}

class App extends StatelessWidget {
  App({super.key});
  final globals = GlobalsService();

  static List<AppPage> pages = [
    AppPage(name: "Notes", icon: HugeIcons.strokeRoundedCheckmarkBadge04, build: () => GradesListPage()),
    AppPage(name: "Dévoirs", icon: HugeIcons.strokeRoundedWork, build: () => AssignmentsListPage(key: assignmentListPageKey)),
    AppPage(name: "Conversations", icon: HugeIcons.strokeRoundedMessageMultiple02, build: () => ChatsListPage()),
    AppPage(name: "Recherche", icon: HugeIcons.strokeRoundedSearch01, build: () => SearchPage()),
    AppPage(name: "Réglages", icon: HugeIcons.strokeRoundedSettings05, build: () => SettingsListPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: globals.appBrightnessNotifier,
      builder: (context, brightness, _) {
        return CupertinoApp(
          navigatorKey: navigatorKey,
          theme: CupertinoThemeData(
            brightness: brightness,
            primaryColor: AppColors.accent,
            scaffoldBackgroundColor: AppColors.background.adaptTo(context),
            barBackgroundColor: AppColors.background.adaptTo(context),
          ),
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
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
  late final network = NetworkService();
  late final globals = GlobalsService();
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

    network.start();
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
            return Container(color: AppColors.red);
          }
        }).toList();

    MainPage.pageIndex.addListener(swipeToPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationsService().init(context);
      askUserToAcceptTermsOfService(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    MainPage.pageIndex.dispose();
    network.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.adaptTo(context),
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
              backgroundColor: AppColors.secondaryBackground.adaptTo(context),
              strokeColor: AppColors.transparent,
              selectedColor: AppColors.text.adaptTo(context),
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
                            style: TextStyle(fontSize: 10, color: AppColors.secondaryText.adaptTo(context)),
                          ),
                          selectedTitle: Text(
                            page.name,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(fontSize: 10, color: AppColors.text.adaptTo(context)),
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
