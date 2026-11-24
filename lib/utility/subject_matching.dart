import 'package:messagyre_client/database/models/subjects/subject.dart';

/// Finds the subject of this phone that a classmate means with [name]: everyone names their subjects a little
/// differently ("Francais" / "Français", "Maths" / "Mathématiques", "Histoire " / "histoire").
///
/// In order: the same name without case, accents, spaces and punctuation; the same with a final "s" dropped
/// ("Maths" = "Math"); then a name that starts the other ("Math" → "Mathématiques", "Bio" → "Biologie", 3 letters at
/// least), only when a single subject fits. Null when nothing fits or it is ambiguous: the user then picks it.
Subject? matchSubjectByName(String? name, Iterable<Subject> subjects) {
  final wanted = subjectKey(name ?? "");
  if (wanted.isEmpty) return null;
  final all = subjects.toList();

  for (final subject in all) {
    if (subjectKey(subject.name) == wanted) return subject;
  }

  final wantedStem = _stem(wanted);
  for (final subject in all) {
    if (_stem(subjectKey(subject.name)) == wantedStem) return subject;
  }

  if (wantedStem.length < 3) return null;
  final candidates = all.where((subject) {
    final stem = _stem(subjectKey(subject.name));
    return stem.length >= 3 && (stem.startsWith(wantedStem) || wantedStem.startsWith(stem));
  }).toList();
  return candidates.length == 1 ? candidates.single : null;
}

/// The name reduced to what matters: lowercase letters and digits, without accents
String subjectKey(String name) {
  final buffer = StringBuffer();
  for (final char in name.toLowerCase().split("")) {
    final plain = _accents[char] ?? char;
    if (RegExp(r"[a-z0-9]").hasMatch(plain)) buffer.write(plain);
  }
  return buffer.toString();
}

String _stem(String key) => key.length > 3 && key.endsWith("s") ? key.substring(0, key.length - 1) : key;

const _accents = {
  "à": "a", "á": "a", "â": "a", "ä": "a", "ã": "a", "å": "a",
  "ç": "c",
  "è": "e", "é": "e", "ê": "e", "ë": "e",
  "ì": "i", "í": "i", "î": "i", "ï": "i",
  "ñ": "n",
  "ò": "o", "ó": "o", "ô": "o", "ö": "o", "õ": "o",
  "ù": "u", "ú": "u", "û": "u", "ü": "u",
  "ý": "y", "ÿ": "y",
  "œ": "oe", "æ": "ae", "ß": "ss",
};
