import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/access.dart';
import 'package:messagyre_client/api/firebase_api.dart';
import 'package:messagyre_client/pages/homework.dart';
import 'package:messagyre_client/pages/search.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/chats.dart';
import 'package:messagyre_client/pages/grades.dart';
import 'package:messagyre_client/pages/settings.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/singletons/notifications_controller.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Overriding debugPrint to log even in release
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    // You can also send logs to Hive or Firebase Crashlytics
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  // Hive initialization
  try {
    await Hive.initFlutter();

    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(ChatAdapter());
    Hive.registerAdapter(HomeworkAdapter());
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(GradeAdapter());

    await Hive.openBox<Chat>("Chats");
    await Hive.openBox<Homework>("Homework");
    await Hive.openBox<Grade>("Grades");
    await Hive.openBox<List>("SubjectOrder");

    final miscBox = await Hive.openBox("Misc");
    final data = Data();
    data.username = miscBox.get("Username")?.toString();
    data.appBrightnessNotifier.value = Brightness.dark;

    print("Hive initialized successfully");
  } catch (e, s) {
    print("HIVE ERROR: $e\n$s");
  }

  // Firebase initialization
  try {
    await Firebase.initializeApp();
    await FirebaseApi().initialize();
    print("Firebase initialized successfully");
  } catch (e, s) {
    print("FIREBASE ERROR: $e\n$s");
  }

  // Date formatting
  try {
    await initializeDateFormatting('fr_CH', null);
    print("Date formatting initialized successfully");
  } catch (e, s) {
    print("DATE FORMATTING ERROR: $e\n$s");
  }

  // System overlay style
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e, s) {
    print("SYSTEMCHROME ERROR: $e\n$s");
  }

  // Initialize notifiers
  try {
    initMessageNotifiers();
    NotificationController().init(null); // if context is needed, move it to build
    print("Notifiers initialized successfully");
  } catch (e, s) {
    print("NOTIFIERS ERROR: $e\n$s");
  }

  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final data = Data();

  static List<Page> pages = [
    Page(
      name: "Notes",
      idleIcon: CupertinoIcons.table,
      selectedIcon: CupertinoIcons.table_fill,
      build: () => GradesPage(),
    ),
    Page(
      name: "Dévoirs",
      idleIcon: CupertinoIcons.checkmark_square,
      selectedIcon: CupertinoIcons.checkmark_square_fill,
      build: () => HomeworkPage(),
    ),
    Page(
      name: "Conversations",
      idleIcon: CupertinoIcons.chat_bubble_2,
      selectedIcon: CupertinoIcons.chat_bubble_2_fill,
      build: () => ChatsPage(),
    ),
    Page(
      name: "Récherche",
      idleIcon: CupertinoIcons.person_2,
      selectedIcon: CupertinoIcons.person_2_fill,
      build: () => SearchPage(),
    ),
    Page(
      name: "Réglages",
      idleIcon: CupertinoIcons.gear,
      selectedIcon: CupertinoIcons.gear_solid,
      build: () => SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: data.appBrightnessNotifier,
      builder: (context, brightness, _) {
        return CupertinoApp(
          navigatorKey: navigatorKey,
          theme: CupertinoThemeData(
            brightness: brightness,
            primaryColor: Color.fromRGBO(100, 25, 104, 1),
          ),
          localizationsDelegates: [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: MainPage(),
        );
      },
    );
  }
}

class Page {
  final String name;
  final IconData idleIcon;
  final IconData selectedIcon;
  final Widget Function() build;

  const Page({
    required this.name,
    required this.idleIcon,
    required this.selectedIcon,
    required this.build,
  });
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final CupertinoTabController tabController = CupertinoTabController(
    initialIndex: 2,
  );

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final router = ConnectionController();
  late final data = Data();

  void _switchToAccess() {
    navigatorKey.currentState?.push(
      CupertinoPageRoute(builder: (_) => AccessOverlay()),
    );
  }

  @override
  void initState() {
    super.initState();
    router.start();
    WidgetsBinding.instance.addObserver(this);
    ConnectionController().onUnauthorized = _switchToAccess;

    NotificationController().init(context);

    MainPage.tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainPage.tabController.dispose();
    router.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: MainPage.tabController,
      tabBar: CupertinoTabBar(
        iconSize: 26,
        height: 50,
        onTap: (_) {
          setState(() {});
        },
        items:
            App.pages.map((page) {
              final index = App.pages.indexOf(page);
              final isSelected = MainPage.tabController.index == index;
              return BottomNavigationBarItem(
                icon: Icon(isSelected ? page.selectedIcon : page.idleIcon),
                label: page.name,
              );
            }).toList(),
      ),
      tabBuilder: (BuildContext context, int currentPage) {
        return CupertinoTabView(
          builder: (context) {
            return App.pages[currentPage].build();
          },
        );
      },
    );
  }
}
