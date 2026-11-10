import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message_reply.dart';

void main() {
  group("An answer", () {
    const reply = MessageReply(uuid: "a1", sender: "lea.martin", text: "Tu as fait le devoir ?");

    test("travels next to a photo without changing it (the apps before 4.108 still read the photo)", () {
      const photo = Attachment(kind: AttachmentKind.image, key: "k", iv: "i", name: "photo.jpg", mimeType: "image/jpeg", size: 10);
      final merged = MessageReply.mergeInto(photo.toJson(), reply)!;
      expect(Attachment.tryParse(merged)?.name, "photo.jpg");
      expect(MessageReply.fromPayload(merged)?.uuid, "a1");
    });

    test("alone, is ignored by the apps before 4.108 (no attachment in it)", () {
      final merged = MessageReply.mergeInto(null, reply)!;
      expect(Attachment.tryParse(merged), isNull);
      expect(MessageReply.fromPayload(merged)?.text, "Tu as fait le devoir ?");
    });

    test("keeps only the beginning of a long message, on one line", () {
      final long = MessageReply.of(uuid: "b", sender: "x", text: "Ligne\n\n${"a" * 500}");
      expect(long.text.length, MessageReply.maxTextLength + 1);
      expect(long.text.contains("\n"), isFalse);
    });

    test("nothing is added when there is no answer", () {
      expect(MessageReply.mergeInto(null, null), isNull);
      expect(MessageReply.fromPayload(jsonEncode({"Key": "k"})), isNull);
      expect(MessageReply.fromPayload("not json"), isNull);
    });
  });

  group("A file", () {
    test("documents, photos, sound and video are accepted", () {
      for (final name in ["devoir.pdf", "notes.DOCX", "photo.heic", "son.m4a", "film.mov", "tableau.xlsx"]) {
        expect(Attachment.isAllowedName(name), isTrue, reason: name);
      }
    });

    test("programs, scripts, web pages and archives are refused", () {
      for (final name in ["jeu.apk", "setup.exe", "script.js", "page.html", "archive.zip", "raccourci.lnk", "sans-extension"]) {
        expect(Attachment.isAllowedName(name), isFalse, reason: name);
      }
    });

    test("received from an old app, a refused file is blocked; a photo never is", () {
      const program = Attachment(kind: AttachmentKind.file, key: "k", iv: "i", name: "jeu.apk", mimeType: "application/octet-stream", size: 1);
      const photo = Attachment(kind: AttachmentKind.image, key: "k", iv: "i", name: "photo", mimeType: "image/jpeg", size: 1);
      expect(program.isBlocked, isTrue);
      expect(photo.isBlocked, isFalse);
    });

    test("a photo of the global chat says it is public", () {
      const photo = Attachment(kind: AttachmentKind.image, key: "", iv: "", name: "photo.jpg", mimeType: "image/jpeg", size: 0, fileId: "abc", isPublic: true);
      expect(Attachment.tryParse(photo.toJson())?.isPublic, isTrue);
    });
  });
}
