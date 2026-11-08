// Screenshots of whole pages, with a real Isar database in a temporary folder and Windows' Segoe UI font.
// Not a regular test (it needs the Isar library): run it to look at the pages with
//   ISAR_LIBRARY=<path of isar_windows_x64.dll> flutter test test/screenshots --run-skipped --update-goldens
// The pictures are written next to this file, in goldens/ (ignored by git).
@Tags(["screenshots"])
library;

import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/assignments/assignments_list_page.dart';
import 'package:messagyre_client/pages/chats/chats_list_page.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/bottom_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TemporaryPaths extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final String root;
  _TemporaryPaths(this.root);
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
}

Future<void> _loadFonts() async {
  Future<ByteData> font(String name) async => ByteData.sublistView(await File("C:/Windows/Fonts/$name").readAsBytes());
  for (final family in ["FlutterTest", "Roboto", "CupertinoSystemText", "CupertinoSystemDisplay", ".SF Pro Text", ".SF Pro Display", ".SF UI Text", ".SF UI Display"]) {
    final loader = FontLoader(family);
    for (final file in ["segoeui.ttf", "seguisb.ttf", "segoeuib.ttf", "segoeuii.ttf"]) {
      loader.addFont(font(file));
    }
    await loader.load();
  }
}

Future<void> _seed(Isar isar, String root) async {
  final now = DateTime.now();
  DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

  final maths = Subject()
    ..code = "maths"
    ..name = "Mathématiques"
    ..colorValue = AppColors.blue.toARGB32()
    ..iconCodePoint = 0xe11f;
  final french = Subject()
    ..code = "francais"
    ..name = "Français"
    ..colorValue = AppColors.orange.toARGB32()
    ..iconCodePoint = 0xe0ef;

  // A real photo on disk for the received picture
  final photo = img.Image(width: 1200, height: 900);
  img.fillRect(photo, x1: 0, y1: 0, x2: 1200, y2: 900, color: img.ColorRgb8(60, 120, 200));
  img.fillCircle(photo, x: 600, y: 450, radius: 280, color: img.ColorRgb8(250, 210, 80));
  final photoPath = "$root/photo.jpg";
  await File(photoPath).writeAsBytes(img.encodeJpg(photo));
  final thumbnail = base64.encode(img.encodeJpg(img.copyResize(photo, width: 32), quality: 60));

  Message m(String chat, String text, bool owned, int minutesAgo, {MessageStatus? status, Attachment? attachment, TransferState transfer = TransferState.none, String? localPath}) => Message.custom(
    chatUsername: chat,
    content: attachment?.previewText ?? text,
    sentAt: ago(minutesAgo),
    isOwned: owned,
    status: status ?? (owned ? MessageStatus.Read : MessageStatus.Delivered),
    attachment: attachment,
    transfer: transfer,
    localPath: localPath,
  );

  final messages = [
    m("lea.martin", "Salut ! Tu as compris l'exercice 4 de maths ?", false, 60 * 26),
    m("lea.martin", "Pas vraiment 😅 on regarde ensemble demain ?", true, 60 * 26 - 3),
    m("lea.martin", "Ok ! Voilà la photo du tableau", false, 42),
    m("lea.martin", "", false, 41,
        attachment: Attachment(kind: AttachmentKind.image, fileId: "a" * 32, key: "k", iv: "i", name: "tableau.jpg", mimeType: "image/jpeg", size: 380000, width: 1200, height: 900, thumbnail: thumbnail),
        transfer: TransferState.ready,
        localPath: photoPath),
    m("lea.martin", "Merci beaucoup !! Et le résumé du cours ?", true, 30),
    m("lea.martin", "", false, 12,
        attachment: Attachment(kind: AttachmentKind.file, fileId: "b" * 32, key: "k", iv: "i", name: "Résumé chapitre 4 - Fonctions.pdf", mimeType: "application/pdf", size: 2400000),
        transfer: TransferState.pending),
    m("lea.martin", "Parfait, à demain 👋", true, 2, status: MessageStatus.Delivered),
    m("lea.martin", "J'arrive dans 5 minutes", true, 1, status: MessageStatus.Sending),
    m("noah.dubois", "Tu viens au match samedi ?", false, 60 * 5),
    m("support.messagyre", "Bonjour, merci pour votre retour !", false, 60 * 24 * 3),
    m("emma.rossi", "", true, 60 * 2,
        attachment: Attachment(kind: AttachmentKind.image, fileId: "c" * 32, key: "k", iv: "i", name: "IMG_2041.jpg", mimeType: "image/jpeg", size: 300000, width: 900, height: 1200, thumbnail: thumbnail)),
  ];

  await isar.writeTxn(() async {
    await isar.subjects.putAll([maths, french]);
    await isar.chats.putAll([
      Chat.custom(username: "lea.martin", displayUsername: "Léa Martin"),
      Chat.custom(username: "noah.dubois", displayUsername: "Noah", unreadMessages: 1),
      Chat.custom(username: "support.messagyre", displayUsername: "Support Messagyre", isPinned: true),
      Chat.custom(username: "emma.rossi", displayUsername: "Emma Rossi"),
    ]);
    await isar.messages.putAll(messages);

    final today = DateTime(now.year, now.month, now.day);
    Assignment a(String content, Subject subject, int inDays, {AssignmentType type = AssignmentType.assignment, String? title, bool done = false}) {
      final assignment = Assignment()
        ..content = content
        ..title = title
        ..type = type
        ..isMarkedAsDone = done
        ..dueDate = today.add(Duration(days: inDays))
        ..notificationDate = null
        ..referenceId = "$content$inDays";
      assignment.subject.value = subject;
      return assignment;
    }

    final assignments = [
      a("Exercices 4 à 7 p. 52", maths, 1),
      a("Lire le chapitre 3 de Candide", french, 1, done: true),
      a("Fonctions exponentielles", maths, 3, type: AssignmentType.test, title: "Test de maths"),
      a("Dissertation", french, 6),
      a("Série 12", maths, -2, done: true),
    ];
    await isar.assignments.putAll(assignments);
    for (final assignment in assignments) {
      await assignment.subject.save();
    }
  });
}

Widget _app(Widget page, Brightness brightness) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: 2, platformBrightness: brightness, padding: const EdgeInsets.only(top: 47, bottom: 34)),
  child: CupertinoApp(
    debugShowCheckedModeBanner: false,
    theme: CupertinoThemeData(brightness: brightness, primaryColor: AppColors.accent),
    home: Stack(children: [page, const Positioned(left: 0, right: 0, bottom: 0, child: BottomBar())]),
  ),
);

Widget _plain(Widget page, Brightness brightness) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: 2, platformBrightness: brightness, padding: const EdgeInsets.only(top: 47, bottom: 34)),
  child: CupertinoApp(debugShowCheckedModeBanner: false, theme: CupertinoThemeData(brightness: brightness, primaryColor: AppColors.accent), home: page),
);

void main() {
  late Directory root;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_CH');
    await _loadFonts();

    SharedPreferences.setMockInitialValues({"MessagesHaveChatUsername": true, "DefaultPage": 2});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(appName: "Messagyre", packageName: "com.graviware.messagyre", version: "4.0.0", buildNumber: "1000", buildSignature: "");

    root = await Directory.systemTemp.createTemp("messagyre-screens");
    PathProviderPlatform.instance = _TemporaryPaths(root.path);

    // The Isar library for Windows (isar_windows_x64.dll of the 3.1.0+1 release), path in ISAR_LIBRARY
    await Isar.initializeIsarCore(libraries: {Abi.windowsX64: Platform.environment["ISAR_LIBRARY"] ?? "isar.dll"});
    await GlobalsService().initialize();
    await DatabaseService().initialize();
    await _seed(DatabaseService().isar, root.path);
  });

  Future<void> shoot(WidgetTester tester, Widget widget, String name) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;

    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      // Images (the photo) are decoded outside of the fake clock
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    await expectLater(find.byWidget(widget), matchesGoldenFile("goldens/$name.png"));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets("chats list ($suffix)", (tester) async => shoot(tester, _app(const ChatsListPage(), brightness), "chats_$suffix"));
    testWidgets("chat ($suffix)", (tester) async => shoot(tester, _plain(const ChatPage(username: "lea.martin"), brightness), "chat_$suffix"));
    testWidgets("assignments ($suffix)", (tester) async => shoot(tester, _app(AssignmentsListPage(key: GlobalKey()), brightness), "assignments_$suffix"));
  }
}
