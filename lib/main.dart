import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
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
  print("main() started");

  // Overriding debugPrint
  final originalDebugPrint = debugPrint;

  debugPrint = (String? message, {int? wrapWidth}) {
    Data().log(message);
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
  print("debugPrint overridden");

  // Initializing Hive and other stuff
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(ChatAdapter());
    Hive.registerAdapter(HomeworkAdapter());
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(GradeAdapter());
    Hive.registerAdapter(SettingsAdapter());

    await Hive.openBox<Chat>("Chats");
    await Hive.openBox<Homework>("Homework");
    await Hive.openBox<Grade>("Grades");
    await Hive.openBox<List>("SubjectOrder");
    await Hive.openBox<Settings>("Settings");
  } catch (e) {
    debugPrint("Hive could not be initialized: $e");
  }
  print("Hive initialized");

  initMessageNotifiers();
  print("Message notifiers initialized");

  final data = Data();

  try {
    final miscBox = await Hive.openBox("Misc");
    data.username = miscBox.get("Username")?.toString();
  } catch (e) {
    debugPrint("Misc box could not be opened: $e");
  }
  print("Misc box opened");

  data.appBrightnessNotifier.value = Brightness.dark;

  // Initializing Firebase Messaging
  try {
    await Firebase.initializeApp();
    await FirebaseApi().initialize();
  } catch (e) {
    debugPrint("Firebase could not be initialized: $e");
  }
  print("Firebase initialized");

  // Initializing visual stuff
  await initializeDateFormatting('fr_CH', null);
  print("Date formatting initialized");

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  print("System UI overlay style set");

  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final data = Data();

  static List<AppPage> pages = [
    AppPage(name: "Notes", icon: HugeIcons.strokeRoundedCheckmarkBadge04, build: () => GradesPage()),
    AppPage(name: "Dévoirs", icon: HugeIcons.strokeRoundedWork, build: () => HomeworkPage()),
    AppPage(name: "Conversations", icon: HugeIcons.strokeRoundedMessageMultiple02, build: () => ChatsPage()),
    AppPage(name: "Récherche", icon: HugeIcons.strokeRoundedUserGroup, build: () => SearchPage()),
    AppPage(name: "Réglages", icon: HugeIcons.strokeRoundedSettings05, build: () => SettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: data.appBrightnessNotifier,
      builder: (context, brightness, _) {
        print("App built");
        return CupertinoApp(
          navigatorKey: navigatorKey,
          theme: CupertinoThemeData(brightness: brightness, primaryColor: Color.fromRGBO(100, 25, 104, 1)),
          localizationsDelegates: [DefaultMaterialLocalizations.delegate, DefaultCupertinoLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
          home: MainPage(),
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

  void _switchToAccess() {
    navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => AccessOverlay()));
  }

  @override
  void initState() {
    super.initState();
    router.start();
    WidgetsBinding.instance.addObserver(this);
    router.onUnauthorized = _switchToAccess;

    NotificationController().init(context);

    MainPage.pageIndex.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainPage.pageIndex.dispose();
    router.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainPage.pageIndex,
      builder:
          (context, currentIndex, _) => Scaffold(
            extendBody: true,
            body: IndexedStack(index: currentIndex, children: App.pages.map((page) => page.build()).toList()),
            bottomNavigationBar: CustomNavigationBar(
              isFloating: true,
              borderRadius: const Radius.circular(12),
              backgroundColor: CupertinoColors.secondarySystemBackground.resolveFrom(context),
              selectedColor: CupertinoTheme.of(context).primaryColor,
              strokeColor: CupertinoColors.transparent,
              currentIndex: currentIndex,
              onTap: (index) => MainPage.pageIndex.value = index,
              items:
                  App.pages
                      .map(
                        (page) => CustomNavigationBarItem(
                          icon: HugeIcon(icon: page.icon), //Icon(page.idleIcon),
                          selectedIcon: HugeIcon(icon: page.icon, strokeWidth: 2),
                          // title: Text(
                          //   page.name,
                          //   overflow: TextOverflow.fade,
                          //   softWrap: false,
                          //   style: TextStyle(fontSize: 10, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                          // ),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }
}
