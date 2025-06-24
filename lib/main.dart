import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/access.dart';
import 'package:messagyre_client/pages/homework.dart';
import 'package:messagyre_client/pages/search.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/chats.dart';
import 'package:messagyre_client/pages/grades.dart';
import 'package:messagyre_client/pages/settings.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(HomeworkAdapter());
  Hive.registerAdapter(SubjectAdapter());

  await Hive.openBox<Chat>("Chats");
  await Hive.openBox<Homework>("Homework");
  final miscBox = await Hive.openBox("Misc");

  final data = Data();

  data.username = miscBox.get("Username")?.toString();
  data.appBrightnessNotifier.value =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  await initializeDateFormatting('fr_CH', null);

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

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final _tabController = CupertinoTabController(initialIndex: 2);

  late final router = ConnectionController();
  late final data = Data();

  void _switchToAccess() {
    navigatorKey.currentState?.push(
      CupertinoPageRoute(builder: (_) => AccessOverlay()),
    );
  }

  @override
  void initState() {
    router.start();
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ConnectionController().onUnauthorized = _switchToAccess;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _tabController.dispose();

    router.disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        iconSize: 25,
        onTap: (_) {
          setState(() {});
        },
        items:
            App.pages.map((page) {
              return BottomNavigationBarItem(
                icon: Icon(
                  (_tabController.index == App.pages.indexOf(page)
                      ? page.selectedIcon
                      : page.idleIcon),
                ),
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
