import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/assignment_share.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/chats/widgets/message_bubble.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';

Widget app(Widget child, {Brightness brightness = Brightness.light}) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), platformBrightness: brightness),
  child: CupertinoApp(debugShowCheckedModeBanner: false, home: CupertinoPageScaffold(child: Center(child: child))),
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_CH'));

  group("An assignment sent in a chat", () {
    final share = AssignmentShare(type: AssignmentType.test, title: "Fonctions", content: "Chapitres 3 et 4", subjectName: "Maths", dueDate: DateTime(2026, 11, 12));

    test("survives a round trip through its JSON", () {
      final parsed = AssignmentShare.tryParse(share.toJson())!;
      expect(parsed.type, AssignmentType.test);
      expect(parsed.title, "Fonctions");
      expect(parsed.content, "Chapitres 3 et 4");
      expect(parsed.subjectName, "Maths");
      expect(parsed.dueDate, DateTime(2026, 11, 12));
    });

    test("is not taken for a file by the apps 4.84 to 4.104 (they show its text instead)", () {
      expect(Attachment.tryParse(share.toJson()), isNull);
      expect(share.previewText, contains("Test de Maths"));
      expect(share.previewText, contains("Fonctions"));
    });

    test("is not confused with a photo's description", () {
      const photo = Attachment(kind: AttachmentKind.image, key: "k", iv: "i", name: "a.jpg", mimeType: "image/jpeg", size: 1);
      expect(AssignmentShare.tryParse(photo.toJson()), isNull);
      expect(AssignmentShare.tryParse("not json"), isNull);
      expect(AssignmentShare.tryParse(jsonEncode({"Kind": "Assignment"})), isNull);
    });

    test("recognises the copy already added", () {
      final mine = Assignment()
        ..type = AssignmentType.test
        ..content = "Chapitres 3 et 4"
        ..dueDate = DateTime(2026, 11, 12, 8);
      expect(share.isSameAs(mine), isTrue);
      mine.dueDate = DateTime(2026, 11, 13);
      expect(share.isSameAs(mine), isFalse);
    });

    for (final brightness in Brightness.values) {
      testWidgets("is drawn as a card in a bubble ($brightness)", (tester) async {
        final received = Message.custom(content: share.previewText, sentAt: DateTime(2026, 11, 9, 10), isOwned: false, sharedAssignment: share);
        final sent = Message.custom(content: share.previewText, sentAt: DateTime(2026, 11, 9, 10), isOwned: true, sharedAssignment: share);
        await tester.pumpWidget(
          app(Column(mainAxisSize: MainAxisSize.min, children: [MessageBubble(message: received), MessageBubble(message: sent)]), brightness: brightness),
        );
        // The "already added" check reads the database, absent here: the tile says nothing went wrong
        expect(tester.takeException(), isNull);
        expect(find.text("Fonctions"), findsNWidgets(2));
        expect(find.text("Ajouter à mes devoirs"), findsOneWidget);
      });
    }
  });

  group("Class chats", () {
    test("each class has its own color, the same on every phone", () {
      expect(ClassAvatar.colorOf("1M05"), ClassAvatar.colorOf("1M05"));
      final colors = {for (final name in ["1M01", "1M02", "1M03", "1M04", "1M05", "2C3", "3EC1", "4M12"]) ClassAvatar.colorOf(name)};
      expect(colors.length, greaterThan(3));
    });

    testWidgets("the avatar shows the class's name", (tester) async {
      await tester.pumpWidget(app(const ClassAvatar(className: "1M05", size: 64)));
      expect(find.text("1M05"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test("the group's details are read from GET /classes/mine", () {
      final group = ClassGroup.fromJson("1M05", {
        "PictureURL": "https://example.com/a.jpg",
        "Description": "  ",
        "Delegate": "anna.rossi",
        "ViceDelegate": "luca.bianchi",
        "Votes": {
          "Delegate": {"anna.rossi": 5, "luca.bianchi": 2},
          "Vice": {"luca.bianchi": 4},
        },
        "MyVotes": {"Delegate": "anna.rossi"},
      });
      expect(group.pictureUrl, "https://example.com/a.jpg");
      expect(group.description, isNull);
      expect(group.isDelegate("anna.rossi"), isTrue);
      expect(group.isDelegate("luca.bianchi"), isTrue);
      expect(group.isDelegate("marc.dupont"), isFalse);
      expect(group.votesFor(ClassService.delegateRole, "anna.rossi"), 5);
      expect(group.votesFor(ClassService.viceRole, "anna.rossi"), 0);
      expect(group.myVotes[ClassService.delegateRole], "anna.rossi");
    });

    test("an old server's answer (members only) gives a group without delegates", () {
      final group = ClassGroup.fromJson("1M05", {"Class": "1M05", "Members": []});
      expect(group.delegate, isNull);
      expect(group.votes, isEmpty);
    });
  });

  test("shared assignments say whether I can change them", () {
    final list = SharedAssignment.parseList([
      {"ID": 1, "Content": "a", "DueDate": "2026-11-12T00:00:00", "Type": "Assignment", "CanEdit": true, "EditedBy": "anna.rossi"},
      {"ID": 2, "Content": "b", "DueDate": "2026-11-12T00:00:00", "Type": "Test"},
    ]);
    expect(list[0].canEdit, isTrue);
    expect(list[0].editedBy, "anna.rossi");
    expect(list[1].canEdit, isFalse);
  });
}
