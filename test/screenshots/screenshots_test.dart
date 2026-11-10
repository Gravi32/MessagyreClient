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
import 'package:isar_community/isar.dart';
import 'package:messagyre_client/database/models/messages/message_reply.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/pages/grades/grades_list_page.dart';
import 'package:messagyre_client/pages/grades/subpages/subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/report_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/pages/settings/settings_list_page.dart';
import 'package:messagyre_client/pages/settings/subpages/class_picker_page.dart';
import 'package:messagyre_client/pages/search/search_page.dart';
import 'package:messagyre_client/pages/bootstrap/login_page.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_subject_page.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/main.dart' show appTheme;
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/pages/bootstrap/registration_page.dart';
import 'package:messagyre_client/pages/settings/subpages/wallpaper_settings_page.dart';
import 'package:messagyre_client/pages/settings/subpages/preferences_settings_page.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_by_subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/recent_grades_page.dart';
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
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/settings/subpages/archives_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_composite_subject_page.dart';
import 'package:messagyre_client/services/archive_service.dart';
import 'package:messagyre_client/utility/utility.dart';

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
  for (final family in [
    "FlutterTest",
    "Roboto",
    "CupertinoSystemText",
    "CupertinoSystemDisplay",
    ".SF Pro Text",
    ".SF Pro Display",
    ".SF UI Text",
    ".SF UI Display",
  ]) {
    final loader = FontLoader(family);
    for (final file in ["segoeui.ttf", "seguisb.ttf", "segoeuib.ttf", "segoeuii.ttf"]) {
      loader.addFont(font(file));
    }
    await loader.load();
  }

  // The app's own fonts (see pubspec.yaml)
  for (final family in [AppStyles.fontFamily, AppStyles.titleFontFamily]) {
    final loader = FontLoader(family);
    for (final file in Directory("assets/fonts").listSync().whereType<File>().where((f) => f.path.contains(family) && f.path.endsWith(".ttf"))) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
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

  Message m(
    String chat,
    String text,
    bool owned,
    int minutesAgo, {
    MessageStatus? status,
    Attachment? attachment,
    TransferState transfer = TransferState.none,
    String? localPath,
  }) => Message.custom(
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
    m(
      "lea.martin",
      "",
      false,
      41,
      attachment: Attachment(
        kind: AttachmentKind.image,
        fileId: "a" * 32,
        key: "k",
        iv: "i",
        name: "tableau.jpg",
        mimeType: "image/jpeg",
        size: 380000,
        width: 1200,
        height: 900,
        thumbnail: thumbnail,
      ),
      transfer: TransferState.ready,
      localPath: photoPath,
    ),
    m("lea.martin", "Merci beaucoup !! Et le résumé du cours ?", true, 30),
    m(
      "lea.martin",
      "",
      false,
      12,
      attachment: Attachment(
        kind: AttachmentKind.file,
        fileId: "b" * 32,
        key: "k",
        iv: "i",
        name: "Résumé chapitre 4 - Fonctions.pdf",
        mimeType: "application/pdf",
        size: 2400000,
      ),
      transfer: TransferState.pending,
    ),
    m("lea.martin", "Parfait, à demain 👋", true, 2, status: MessageStatus.Delivered),
    m("lea.martin", "J'arrive dans 5 minutes", true, 1, status: MessageStatus.Sending),
    m("noah.dubois", "Tu viens au match samedi ?", false, 60 * 5),
    m("support.messagyre", "Bonjour, merci pour votre retour !", false, 60 * 24 * 3),
    m(
      "emma.rossi",
      "",
      true,
      60 * 2,
      attachment: Attachment(
        kind: AttachmentKind.image,
        fileId: "c" * 32,
        key: "k",
        iv: "i",
        name: "IMG_2041.jpg",
        mimeType: "image/jpeg",
        size: 300000,
        width: 900,
        height: 1200,
        thumbnail: thumbnail,
      ),
    ),
  ];

  // The global chat: several people, an answer, a photo (blurred until touched)
  final globalMessages = [
    Message.custom(uuid: "g1", chatUsername: "@general", senderUsername: "lea.martin", content: "Quelqu'un a les corrigés du test de chimie ?", sentAt: now.subtract(const Duration(minutes: 40)), isOwned: false, status: MessageStatus.Delivered),
    Message.custom(uuid: "g2", chatUsername: "@general", senderUsername: "noah.dubois", content: "Oui, je les poste ce soir", sentAt: now.subtract(const Duration(minutes: 35)), isOwned: false, status: MessageStatus.Delivered,
        reply: MessageReply.of(uuid: "g1", sender: "lea.martin", text: "Quelqu'un a les corrigés du test de chimie ?")),
    Message.custom(uuid: "g3", chatUsername: "@general", content: "Merci beaucoup !", sentAt: now.subtract(const Duration(minutes: 30)), isOwned: true, status: MessageStatus.Sent,
        reply: MessageReply.of(uuid: "g2", sender: "noah.dubois", text: "Oui, je les poste ce soir")),
  ];

  await isar.writeTxn(() async {
    await isar.subjects.putAll([maths, french]);
    await isar.messages.putAll(globalMessages);
    await isar.chats.putAll([
      Chat.custom(username: "@general", displayUsername: "Conversation générale", isPinned: true, unreadMessages: 2),
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

    Grade g(Subject subject, String title, double mark, int daysAgo, {double weight = 1}) {
      final grade = Grade()
        ..title = title
        ..grade = mark
        ..weight = weight
        ..date = now.subtract(Duration(days: daysAgo));
      grade.subject.value = subject;
      return grade;
    }

    final grades = [
      g(maths, "Test fonctions", 5, 3, weight: 2),
      g(maths, "Série 10", 4.5, 12),
      g(maths, "TE dérivées", 5.5, 30, weight: 2),
      g(french, "Dissertation", 4, 6, weight: 2),
      g(french, "Lecture Candide", 5.5, 20),
    ];
    await isar.grades.putAll(grades);
    for (final grade in grades) {
      await grade.subject.save();
    }
  });
}

Widget _app(Widget page, Brightness brightness) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: 2, platformBrightness: brightness, padding: const EdgeInsets.only(top: 47, bottom: 34)),
  child: Builder(
    builder: (context) => CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(context, brightness),
      home: Stack(
        children: [
          page,
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomBar()),
        ],
      ),
    ),
  ),
);

Widget _plain(Widget page, Brightness brightness) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: 2, platformBrightness: brightness, padding: const EdgeInsets.only(top: 47, bottom: 34)),
  child: Builder(
    builder: (context) => CupertinoApp(debugShowCheckedModeBanner: false, theme: appTheme(context, brightness), home: page),
  ),
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

  testWidgets("typing a message and tapping send stores it (the send button used to be covered)", (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_plain(const ChatPage(username: "noah.dubois"), Brightness.light));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(CupertinoTextField), "Oui je viens !");
    await tester.pump();
    final sendIcon = find.byWidgetPredicate((widget) => widget is HugeIcon && widget.icon == AppIcons.send);
    // The tap must land on the send button itself, not on something drawn over it
    final hit = tester.hitTestOnBinding(tester.getCenter(sendIcon));
    expect(hit.path.first.target.toString(), isNot(contains("Opacity")));
    await tester.tap(sendIcon);
    await tester.pump();
    expect(tester.widget<CupertinoTextField>(find.byType(CupertinoTextField)).controller?.text, isEmpty);
    // The database writes in real time: alternate real waits and frames until the message is there
    bool stored() => DatabaseService().messages.ofChat("noah.dubois").any((m) => m.isOwned && m.content == "Oui je viens !");
    for (var i = 0; i < 40 && !stored(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final sent = DatabaseService().messages.ofChat("noah.dubois").where((m) => m.isOwned).toList();
    expect(sent.map((m) => m.content), contains("Oui je viens !"));
    // Offline in the tests: it waits in the queue, to be sent at the next connection
    expect(sent.last.status, MessageStatus.Sending);
    for (var i = 0; i < 40 && find.text("Oui je viens !").evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text("Oui je viens !"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets("a composite subject of three subjects averages them by periods per week", (tester) async {
    final isar = DatabaseService().isar;
    final subjects = [
      for (final (code, name) in [("bio", "Biologie"), ("chimie", "Chimie"), ("physique", "Physique")])
        Subject()
          ..code = code
          ..name = name
          ..colorValue = AppColors.green.toARGB32(),
    ];
    final composite = CompositeSubject()
      ..code = "sciences"
      ..name = "Sciences"
      ..firstSubjectPeriodsPerWeek = 2
      ..secondSubjectPeriodsPerWeek = 1
      ..thirdSubjectPeriodsPerWeek = 1;

    await tester.runAsync(() async {
      await isar.writeTxn(() => isar.subjects.putAll(subjects));
      composite.firstSubject.value = subjects[0];
      composite.secondSubject.value = subjects[1];
      composite.thirdSubject.value = subjects[2];
      await DatabaseService().compositeSubjects.save(composite);
      for (final (subject, mark) in [(subjects[0], 6.0), (subjects[1], 4.0), (subjects[2], 3.0)]) {
        final grade = Grade()
          ..title = "Test"
          ..grade = mark
          ..date = DateTime.now();
        grade.subject.value = subject;
        await DatabaseService().grades.save(grade);
      }
    });

    final stored = DatabaseService().compositeSubjects.getByCode("sciences")!;
    stored.firstSubject.loadSync();
    stored.secondSubject.loadSync();
    stored.thirdSubject.loadSync();
    expect(stored.parts.length, 3);
    // (6×2 + 4×1 + 3×1) / 4
    expect(calculateCompositeSubjectAverage(stored), closeTo(19 / 4, 1e-9));

    await shoot(tester, _plain(NewCompositeSubjectPage(toEdit: stored), Brightness.light), "composite_three");
  });

  testWidgets("archiving the year hides grades and assignments without deleting them, and restoring brings them back", (tester) async {
    final database = DatabaseService();
    final gradesBefore = database.grades.getAll().length;
    final assignmentsBefore = database.assignments.getAll().length;
    expect(gradesBefore, greaterThan(0));

    await tester.runAsync(() => ArchiveService().archive("2025-2026"));
    expect(database.grades.getAll(), isEmpty);
    expect(database.assignments.getAll(), isEmpty);
    final archived = ArchiveService().archivedYears();
    expect(archived.single.label, "2025-2026");
    expect(archived.single.grades.length, gradesBefore);
    expect(archived.single.assignments.length, assignmentsBefore);

    await shoot(tester, _plain(const ArchivesPage(), Brightness.light), "archives");

    await tester.runAsync(() => ArchiveService().restore("2025-2026"));
    expect(database.grades.getAll().length, gradesBefore);
    expect(database.assignments.getAll().length, assignmentsBefore);
    expect(ArchiveService().archivedYears(), isEmpty);
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets("chats list ($suffix)", (tester) async => shoot(tester, _app(const ChatsListPage(), brightness), "chats_$suffix"));
    testWidgets("chat ($suffix)", (tester) async => shoot(tester, _plain(const ChatPage(username: "lea.martin"), brightness), "chat_$suffix"));
    testWidgets("global chat ($suffix)", (tester) async => shoot(tester, _plain(const ChatPage(username: "@general"), brightness), "global_$suffix"));
    testWidgets("assignments ($suffix)", (tester) async => shoot(tester, _app(AssignmentsListPage(key: GlobalKey()), brightness), "assignments_$suffix"));
  }

  // Every other page, to look at the design (run with --plain-name "gallery")
  for (final brightness in Brightness.values) {
    final suffix = brightness.name;
    Subject maths() => DatabaseService().isar.subjects.filter().codeEqualTo("maths").findFirstSync()!;
    final pages = <String, Widget Function()>{
      "grades": () => _app(const GradesListPage(), brightness),
      "settings": () => _app(const SettingsListPage(), brightness),
      "search": () => _app(const SearchPage(), brightness),
      "subject": () => _plain(GradesSubjectPage(subject: maths()), brightness),
      "report": () => _plain(const ReportCardPage(), brightness),
      "new_grade": () => _plain(const NewGradePage(), brightness),
      "new_assignment": () => _plain(const NewAssignmentPage(), brightness),
      "login": () => _plain(const LoginPage(), brightness),
      "class_picker": () => _plain(const ClassPickerPage(isOnboarding: true), brightness),
      "subjects": () => _plain(const SubjectsListPage(), brightness),
      "new_subject": () => _plain(const NewSubjectPage(), brightness),
      "registration": () => _plain(const RegistrationPage(), brightness),
      "wallpaper": () => _plain(const WallpaperSettingsPage(), brightness),
      "preferences": () => _plain(PreferencesSettingsPage(), brightness),
      "by_subject": () => _plain(const GradesBySubjectPage(), brightness),
      "recent": () => _plain(const RecentGradesPage(), brightness),
      "profile": () => _plain(
        ProfilePage(
          Account.fromMap({
            "Username": "lea.martin",
            "DisplayName": "Léa Martin",
            "ClassOrRole": "2M05",
            "CreationDate": "2025-09-01T10:00:00",
            "Profile": {"Bio": "En 2M05, fan de bio et de volley."},
          })!,
        ),
        brightness,
      ),
      "action_sheet": () => _plain(
        CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ActionSheet<String>(
              title: "Photo de profil",
              actions: const [
                SheetAction("Prendre une photo", icon: HugeIcons.strokeRoundedCamera01, value: "camera"),
                SheetAction("Choisir dans la galerie", icon: HugeIcons.strokeRoundedAlbum02, value: "gallery"),
                SheetAction("Supprimer la photo", icon: HugeIcons.strokeRoundedDelete04, value: "delete", isDestructive: true),
              ],
            ),
          ),
        ),
        brightness,
      ),
      "dialog": () => _plain(Dialog.confirm(content: "Voulez-vous vraiment supprimer cette note ?", isDestructive: true), brightness),
    };
    for (final MapEntry(key: name, value: build) in pages.entries) {
      testWidgets("gallery $name ($suffix)", (tester) async => shoot(tester, build(), "${name}_$suffix"));
    }
  }

  testWidgets("the dock on a narrow phone with large text: long names end with an ellipsis", (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 160));
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 2;
    final widget = MediaQuery(
      data: const MediaQueryData(size: Size(320, 160), devicePixelRatio: 2, textScaler: TextScaler.linear(1.4)),
      child: Builder(
        builder: (context) => CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(context, Brightness.dark),
          home: const CupertinoPageScaffold(child: Align(alignment: Alignment.bottomCenter, child: BottomBar())),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await expectLater(find.byWidget(widget), matchesGoldenFile("goldens/dock_narrow.png"));
  });
}
