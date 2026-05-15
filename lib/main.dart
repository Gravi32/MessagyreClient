import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/pages/assignments/assignments_list_page.dart';
import 'package:messagyre_client/pages/chats/chats_list_page.dart';
import 'package:messagyre_client/pages/grades/grades_list_page.dart';
import 'package:messagyre_client/pages/search/search_page.dart';
import 'package:messagyre_client/pages/settings/settings_list_page.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/notification_overlays_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:messagyre_client/utility/widgets/bottom_bar.dart';
import 'package:messagyre_client/services/lifecycle_service.dart';
import 'package:messagyre_client/pages/bootstrap/terms_of_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BootProcedure {
  /// Overrides "debugPrint" to send output to the app's debug page as well
  static void overridePrintFunction() {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      GlobalsService().log(message);
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }

  /// Instantiates Globals singleton.
  static Future<void> setupGlobals() async {
    await GlobalsService().initialize();

    final globals = GlobalsService();
    globals.username = globals.persistent.getString("Username");
  }

  /// Initializes the database and its repositories
  static Future<void> setupDatabase() async {
    await DatabaseService().initialize();
    return;
  }

  /// Initializes Firebase and Notification services
  static Future<void> setupNotificationSystems() async {
    try {
      await Firebase.initializeApp();
      await NotificationsService().initialize();
    } catch (e) {
      debugPrint("Firebase could not be initialized: $e");
    }
    return;
  }

  /// Initializes miscellaneous stuff
  static Future<void> setupMiscellaneous() async {
    await initializeDateFormatting('fr_CH', null);
    tz.initializeTimeZones();

    NotificationsService().resetBadge();
  }

  /// Sets native system UI colors
  static void setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: .light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: .light,
      ),
    );
  }
}

void main() async {
  // (Way too verbose) FlutterError.onError = (details) => FlutterError.dumpErrorToConsole(details);
  WidgetsFlutterBinding.ensureInitialized();

  BootProcedure.overridePrintFunction();

  await NetworkService().checkLocalhostAvailability();

  runZonedGuarded(
    () async {
      try {
        await BootProcedure.setupGlobals();
        await BootProcedure.setupDatabase();
        await BootProcedure.setupNotificationSystems();
        await BootProcedure.setupMiscellaneous();

        BootProcedure.setupSystemUI();

        runApp(
          DevicePreview(
            enabled: false, // !kReleaseMode,
            builder: (context) => Phoenix(child: LifecycleService(child: App())),
          ),
        );
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
    AppPage(
      name: "Devoirs",
      icon: HugeIcons.strokeRoundedWork,
      build: () => AssignmentsListPage(key: assignmentListPageKey),
    ),
    AppPage(name: "Conversations", icon: HugeIcons.strokeRoundedMessageMultiple02, build: () => ChatsListPage()),
    AppPage(name: "Recherche", icon: HugeIcons.strokeRoundedSearch01, build: () => SearchPage()),
    AppPage(name: "Réglages", icon: HugeIcons.strokeRoundedSettings05, build: () => SettingsListPage()),
  ];

  @override
  Widget build(BuildContext context) {
    final Brightness? brightness = switch (globals.persistent.getBool("useDarkMode")) {
      true => .dark,
      false => .light,
      _ => null,
    };

    return CupertinoApp(
      navigatorKey: navigatorKey,

      //locale: DevicePreview.locale(context),
      //builder: DevicePreview.appBuilder,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.accent,
          textStyle: TextStyle(color: AppColors.text.adaptTo(context), fontSize: 17),
        ),
        scaffoldBackgroundColor: AppColors.background.adaptTo(context),
        barBackgroundColor: AppColors.background.adaptTo(context),
      ),
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: const [Locale('fr'), Locale('fr', 'CH')],
      locale: Locale('fr', 'CH'),
      home: const MainPage(),
      builder: (context, child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(platformBrightness: brightness, textScaler: data.textScaler.clamp(minScaleFactor: 0, maxScaleFactor: 1.2)),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: child!,
          ),
        );
      },
    );
  }
}

class AppPage {
  final String name;
  final List<List<dynamic>> icon;
  final Widget Function() build;

  final showBadge = ValueNotifier<bool>(false);

  AppPage({required this.name, required this.icon, required this.build});
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final ValueNotifier<int> pageIndex = ValueNotifier<int>(GlobalsService().persistent.getInt("DefaultPage") ?? 2);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final network = NetworkService();
  late final globals = GlobalsService();
  late final PageController pageController;
  late final List<Widget> builtPages;
  bool isAnimating = false;

  void swipeToPage() async {
    if (isAnimating) {
      pageController.jumpToPage(MainPage.pageIndex.value);
      return;
    }

    isAnimating = true;
    await pageController.animateToPage(MainPage.pageIndex.value, duration: const Duration(milliseconds: 200), curve: Curves.easeOutQuart);
    isAnimating = false;
  }

  @override
  void initState() {
    super.initState();

    network.start();
    WidgetsBinding.instance.addObserver(this);

    pageController = PageController(initialPage: MainPage.pageIndex.value);

    // Wrap every page build in try/catch to avoid crashing the whole PageView
    builtPages = App.pages.map((p) {
      try {
        return KeepAliveWrapper(child: p.build());
      } catch (e, stack) {
        debugPrint("Error building page ${p.name}: $e");
        debugPrint(stack.toString());
        return Container(color: AppColors.red);
      }
    }).toList();

    MainPage.pageIndex.addListener(swipeToPage);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationOverlaysService().init(context);
      await askUserToAcceptTermsOfService(context);

      final mountedContext = context;
      if (!context.mounted) return;
      await askUserToAddTheirSubjects(mountedContext);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    network.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.adaptTo(context),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            allowImplicitScrolling: true,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              if (!isAnimating) MainPage.pageIndex.value = index;
            },
            children: builtPages,
          ),
          Positioned(right: 0, bottom: 0, left: 0, child: BottomBar()),
        ],
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
