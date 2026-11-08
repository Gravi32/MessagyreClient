import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/chats/widgets/message_bubble.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/utility/workarounds/field_header_delegate.dart';

/// Wraps a widget like the app does (Cupertino, French, a phone-sized screen)
Widget app(Widget child, {Brightness brightness = Brightness.light, double textScale = 1}) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), platformBrightness: brightness, textScaler: TextScaler.linear(textScale), padding: const EdgeInsets.only(top: 47, bottom: 34)),
  child: CupertinoApp(debugShowCheckedModeBanner: false, home: child),
);

String thumbnail() => base64.encode(img.encodeJpg(img.Image(width: 32, height: 24), quality: 60));

void main() {
  setUpAll(() => initializeDateFormatting('fr_CH'));

  testWidgets("The old assignments body (an unbounded ListView under pull to refresh) is what crashed", (tester) async {
    await tester.pumpWidget(
      app(
        Page.sliver(
          topBar: TopBar.sliver(title: "Devoirs"),
          onRefresh: () async {},
          body: ListView(children: const [Text("a"), Text("b")]),
        ),
      ),
    );
    // "Vertical viewport was given unbounded height", followed by the layout errors it causes
    expect(tester.takeException(), isNotNull);
  });

  group("Pinned search bar", () {
    for (final scale in [1.0, 1.2]) {
      testWidgets("fits its header without overflowing (text ×$scale)", (tester) async {
        await tester.pumpWidget(
          app(
            CupertinoPageScaffold(
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(pinned: true, delegate: FieldHeaderDelegate(field: Field.search(placeholder: "Chercher un devoir…"))),
                  SliverList.list(children: List.generate(30, (i) => SizedBox(height: 40, child: Text("$i")))),
                ],
              ),
            ),
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull);

        // Typing shows the clear button: still no overflow, and it empties the field
        await tester.enterText(find.byType(CupertinoTextField), "maths");
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text("maths"), findsOneWidget);

        final fieldHeight = tester.getSize(find.byType(Field)).height;
        expect(fieldHeight, AppSizes.compactControl);
      });
    }
  });

  testWidgets("A sliver page with pull to refresh lays out a long body (the assignments page used to crash)", (tester) async {
    await tester.pumpWidget(
      app(
        Page.sliver(
          topBar: TopBar.sliver(title: "Devoirs"),
          field: Field.search(placeholder: "Chercher un devoir…"),
          onRefresh: () async {},
          body: Column(
            children: [
              ListSection(
                title: "Partagés avec la classe",
                useLargeTitle: true,
                children: [
                  for (var i = 0; i < 12; i++)
                    SharedAssignmentTile(
                      assignment: SharedAssignment(id: i, title: "Test $i", content: "Chapitre $i", authorUsername: "jean.dupont", dueDate: DateTime(2026, 11, 10 + i), type: i.isEven ? AssignmentType.test : AssignmentType.assignment),
                    ),
                ],
              ),
              const EmptyState(icon: AppIcons.emptyList, title: "Rien pour le moment…", subtitle: "Vos devoirs s'afficheront ici"),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("Test 0"), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group("Shared assignments", () {
    test("are parsed from the server's rows, and malformed rows are skipped", () {
      final parsed = SharedAssignment.parseList([
        {"ID": 3, "Title": null, "Content": "Exercices 1 à 4", "AuthorUsername": "jean.dupont", "DueDate": "2026-11-10T00:00:00", "Type": "Assignment"},
        {"ID": 4, "Title": "Fonctions", "Content": null, "DueDate": "2026-11-12T00:00:00", "Type": "Test"},
        {"ID": 5, "Content": "sans date"},
        "not a row",
      ]);
      expect(parsed.length, 2);
      expect(parsed[0].displayTitle, "Exercices 1 à 4");
      expect(parsed[1].type, AssignmentType.test);
      expect(parsed[1].content, "");
      expect(parsed[1].dueDate, DateTime(2026, 11, 12));
    });
  });

  group("Message bubbles", () {
    final now = DateTime(2026, 11, 8, 14, 30);

    Message text(String content, {bool owned = false, MessageStatus status = MessageStatus.Delivered, bool deleted = false}) =>
        Message.custom(chatUsername: "jean.dupont", content: content, sentAt: now, isOwned: owned, status: status, isDeleted: deleted);

    Message withAttachment(Attachment attachment, {bool owned = false, TransferState transfer = TransferState.pending}) =>
        Message.custom(chatUsername: "jean.dupont", content: attachment.previewText, sentAt: now, isOwned: owned, attachment: attachment, transfer: transfer);

    final photo = Attachment(kind: AttachmentKind.image, fileId: "a" * 32, key: "k", iv: "i", name: "photo.jpg", mimeType: "image/jpeg", size: 350000, width: 1600, height: 1200, thumbnail: thumbnail());
    final pdf = const Attachment(kind: AttachmentKind.file, fileId: null, key: "k", iv: "i", name: "Résumé du chapitre 4 — fonctions exponentielles.pdf", mimeType: "application/pdf", size: 2400000, caption: "Voilà le résumé");

    for (final brightness in Brightness.values) {
      testWidgets("render every kind of message without overflow ($brightness)", (tester) async {
        await tester.pumpWidget(
          app(
            CupertinoPageScaffold(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  MessageBubble(message: text("Salut ! Tu as fait l'exercice 3 ?")),
                  MessageBubble(message: text("Oui, *regarde* : c'est assez long pour passer sur plusieurs lignes dans la bulle, avec l'heure en bas.", owned: true, status: MessageStatus.Read), joinsPrevious: true),
                  MessageBubble(message: text("Envoi en cours", owned: true, status: MessageStatus.Sending)),
                  MessageBubble(message: text("Pas envoyé", owned: true, status: MessageStatus.Failed)),
                  MessageBubble(message: text("x", deleted: true)),
                  MessageBubble(message: withAttachment(photo)),
                  MessageBubble(message: withAttachment(photo.copyWith(caption: "La photo du tableau"), owned: true, transfer: TransferState.expired)),
                  MessageBubble(message: withAttachment(pdf, owned: true, transfer: TransferState.failed)),
                  MessageBubble(message: withAttachment(pdf)),
                ],
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text("La photo du tableau"), findsOneWidget);
        expect(find.text("Supprimé"), findsOneWidget);
      });
    }
  });

  group("Attachments", () {
    test("survive a round trip through their JSON description", () {
      final original = Attachment(kind: AttachmentKind.image, fileId: "f" * 32, key: "key", iv: "iv", name: "IMG_2041.jpg", mimeType: "image/jpeg", size: 1234, width: 4, height: 3, thumbnail: "abc", caption: "Le tableau");
      final copy = Attachment.tryParse(original.toJson())!;
      expect(copy.fileId, original.fileId);
      expect(copy.aspectRatio, 4 / 3);
      expect(copy.caption, "Le tableau");
      expect(copy.previewText, "Le tableau");
    });

    test("never keep a path from the sender", () {
      final parsed = Attachment.tryParse(jsonEncode({"Key": "k", "Iv": "i", "Name": "../../shared_prefs/evil.xml", "Kind": "file"}))!;
      expect(parsed.name, "evil.xml");
      expect(Attachment.tryParse("not json"), isNull);
      expect(Attachment.tryParse(jsonEncode({"Name": "x"})), isNull);
    });
  });

  // The in-app banner of a new message: a picture with a radius in a Row of a Column of unbounded height
  // ("RenderAspectRatio has unbounded constraints", then a dozen layout errors at every message)
  testWidgets("A profile picture with a radius sizes itself where nothing bounds it", (tester) async {
    await tester.pumpWidget(
      app(
        const Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ProfilePictureDisplay(radius: 30),
                  Expanded(child: Text("Léa")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ProfilePictureDisplay)), const Size(60, 60));
  });
}
