import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/utility.dart';

class Account {
  late String username;
  late String? displayName;
  late String emailAddress;
  late String? classOrRole;
  late DateTime? creationDate;
  late DateTime? lastLogin;
  late Map<String, dynamic>? profile;

  String get defaultDisplayName => getDefaultDisplayName(username);

  static String getDefaultDisplayName(String fromUsername) {
    return fromUsername.replaceAll('.', ' ').capitalize(everyWord: true);
  }

  static Account? fromJson(String? source) {
    if (source == null || source.trim().isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        debugPrint("Account.fromJson error: JSON is not a valid map.");
        return null;
      }
      return fromMap(decoded);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: "Account.fromJson error: $e\nsource: $source");
      return null;
    }
  }

  static Account? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    try {
      return Account()
        ..username = map["Username"] ?? "unknown"
        ..displayName = map["DisplayName"]
        ..emailAddress = map["EmailAddress"] ?? "unknown"
        ..classOrRole = map["ClassOrRole"]
        ..creationDate = DateTime.tryParse(map["CreationDate"] ?? "")
        ..lastLogin = DateTime.tryParse(map["LastLogin"] ?? "")
        ..profile = _parseProfile(map["Profile"]);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: "Account.fromMap error: $e");
      return null;
    }
  }

  static Map<String, dynamic> _parseProfile(dynamic data) {
    if (data == null) return {};

    if (data is String) {
      if (data.trim().isEmpty) return {};
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        debugPrint("[classes.dart] Account Parse Error: $e");
        return {};
      }
    }

    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  @override
  String toString() {
    String profileString = "";
    profile?.forEach((key, value) => profileString += "\n\t\t$key: $value");
    return "[Account: $username]\n\tEmail: $emailAddress\n\tProfile: {$profileString\n}\n";
  }
}
