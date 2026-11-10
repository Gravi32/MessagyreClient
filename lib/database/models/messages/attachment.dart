import 'dart:convert';

import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:path/path.dart' as p;

enum AttachmentKind { image, file }

/// A photo or file sent in a chat. This description travels inside the end-to-end encrypted message
/// ("Attachment" field, encrypted with the message's key): the server only stores the file's encrypted bytes,
/// under [fileId], and never sees its name, its key or its preview.
class Attachment {
  final AttachmentKind kind;

  /// The file on the server (null until the upload is done)
  final String? fileId;

  /// AES-256-GCM key and nonce of the file's bytes (base64)
  final String key;
  final String iv;

  final String name;
  final String mimeType;
  final int size;

  /// Photos only: size in pixels and a tiny JPEG preview (base64), shown until the photo is downloaded
  final int? width;
  final int? height;
  final String? thumbnail;

  /// The text typed with the photo or file
  final String? caption;

  /// A photo of the global chat: not encrypted (everyone reads that chat), checked and re-encoded by the server,
  /// downloaded from /global/photo with [fileId]. [key] and [iv] are empty.
  final bool isPublic;

  const Attachment({
    required this.kind,
    this.fileId,
    required this.key,
    required this.iv,
    required this.name,
    required this.mimeType,
    required this.size,
    this.width,
    this.height,
    this.thumbnail,
    this.caption,
    this.isPublic = false,
  });

  /// The kinds of files that can be sent and opened: documents, photos, sound and video. Programs, scripts, web
  /// pages and archives (which can hide them) are refused, sent or received: they could harm the phone or the
  /// computer they are opened on.
  static const allowedExtensions = {
    "pdf", "doc", "docx", "odt", "rtf", "txt", "md", "pages", "epub",
    "xls", "xlsx", "ods", "csv", "numbers",
    "ppt", "pptx", "odp", "key",
    "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "bmp", "tif", "tiff",
    "mp3", "m4a", "wav", "aac", "ogg", "flac", "opus",
    "mp4", "mov", "m4v", "webm", "3gp", "avi", "mkv",
  };

  static bool isAllowedName(String name) => allowedExtensions.contains(p.extension(name).replaceFirst('.', '').toLowerCase());

  /// A file of a kind that is never opened (sent by an app before 4.108, which didn't check)
  bool get isBlocked => !isImage && !isAllowedName(name);

  bool get isImage => kind == AttachmentKind.image;

  double? get aspectRatio => (width != null && height != null && width! > 0 && height! > 0) ? width! / height! : null;

  String get extension => p.extension(name).replaceFirst('.', '').toLowerCase();

  /// The text older apps show instead of the attachment (and the notifications)
  String get previewText => caption?.trim().isNotEmpty == true ? caption!.trim() : (isImage ? "📷 Photo" : "📎 $name");

  List<List<dynamic>> get icon => switch (extension) {
    "pdf" => AppIcons.pdf,
    "zip" || "rar" || "7z" || "tar" || "gz" => AppIcons.archive,
    "txt" || "md" || "rtf" => AppIcons.text,
    "doc" || "docx" || "odt" || "pages" => AppIcons.document,
    "xls" || "xlsx" || "ods" || "csv" || "numbers" => AppIcons.spreadsheet,
    "ppt" || "pptx" || "odp" || "key" => AppIcons.presentation,
    "mp4" || "mov" || "avi" || "mkv" || "webm" => AppIcons.video,
    "mp3" || "m4a" || "wav" || "aac" || "ogg" || "flac" => AppIcons.audio,
    _ => isImage ? AppIcons.photo : AppIcons.file,
  };

  Attachment copyWith({String? fileId, String? caption, int? width, int? height}) => Attachment(
    kind: kind,
    fileId: fileId ?? this.fileId,
    key: key,
    iv: iv,
    name: name,
    mimeType: mimeType,
    size: size,
    width: width ?? this.width,
    height: height ?? this.height,
    thumbnail: thumbnail,
    caption: caption ?? this.caption,
    isPublic: isPublic,
  );

  Map<String, dynamic> toMap() => {
    "Version": 1,
    "Kind": kind.name,
    "FileId": fileId,
    "Key": key,
    "Iv": iv,
    "Name": name,
    "MimeType": mimeType,
    "Size": size,
    if (width != null) "Width": width,
    if (height != null) "Height": height,
    if (thumbnail != null) "Thumbnail": thumbnail,
    if (caption != null) "Caption": caption,
    if (isPublic) "Public": true,
  };

  String toJson() => jsonEncode(toMap());

  /// Null for anything that isn't a valid description (a message from a newer app, a corrupted one...)
  static Attachment? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json);
      if (map is! Map) return null;

      final key = map["Key"], iv = map["Iv"], name = map["Name"];
      if (key is! String || iv is! String || name is! String) return null;

      return Attachment(
        kind: AttachmentKind.values.asNameMap()[map["Kind"]] ?? AttachmentKind.file,
        fileId: map["FileId"] as String?,
        key: key,
        iv: iv,
        // Only the name: a path coming from someone else must never decide where a file is written
        name: p.basename(name).isEmpty ? "fichier" : p.basename(name),
        mimeType: map["MimeType"] as String? ?? "application/octet-stream",
        size: (map["Size"] as num?)?.toInt() ?? 0,
        width: (map["Width"] as num?)?.toInt(),
        height: (map["Height"] as num?)?.toInt(),
        thumbnail: map["Thumbnail"] as String?,
        caption: map["Caption"] as String?,
        isPublic: map["Public"] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
