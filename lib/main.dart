import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/access.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/pages/chats.dart';
import 'package:messagyre_client/pages/grades.dart';
import 'package:messagyre_client/pages/settings.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ChatAdapter());

  await Hive.openBox<Chat>("Chats");
  await Hive.openBox("AccessInfo");

  Data().appBrightnessNotifier.value =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final data = Data();

  static const bool useLocalhost = true;
  static String localIP = "192.168.1.230:5066";

  static String serverWebSocketAddress =
      useLocalhost ? "ws://$localIP" : "wss://messagyre.up.railway.app";

  static String serverHTTPAddress =
      useLocalhost ? "http://$localIP" : "https://messagyre.up.railway.app";

  static List<Page> pages = [
    Page(
      name: "Notes",
      idleIcon: CupertinoIcons.table,
      selectedIcon: CupertinoIcons.table_fill,
      build: () => GradesPage(),
    ),
    Page(
      name: "Conversations",
      idleIcon: CupertinoIcons.chat_bubble_2,
      selectedIcon: CupertinoIcons.chat_bubble_2_fill,
      build: () => ChatsPage(),
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
  final _tabController = CupertinoTabController(initialIndex: 1);

  late ConnectionController router;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    router = ConnectionController();
    router.connect(App.serverWebSocketAddress);
    router.onConnected.listen((_) {
      var loginInfo = Hive.box("AccessInfo");
      router.login(
        loginInfo.get("Username") ?? "",
        loginInfo.get("Password") ?? "",
      );
    });

    router.onSignalReceived.listen((signal) {
      if (signal.type != SignalType.Login) return;

      if (signal.data["Response"] != "success" && mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => AccessOverlay()),
        );
      }
    });
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
