import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/classes.dart';

enum Subject {
  French,
  Italian,
  English,
  German,
  Spanish,
  SpanishOS,

  Maths,
  MathsOS,
  MathsOC,
  Biology,
  BiologyOS,
  BiologyOC,
  Chemistry,
  ChemistryOS,
  ChemistryOC,
  Physics,
  PhysicsOS,
  PhysicsOC,

  IT,
  ITOC,

  History,
  HistoryOC,
  Geography,
  GeographyOC,
  Philosophy,
  PhilosophyOS,
  Psychology,
  PsychologyOS,
  HistoryAndReligionsOC,

  Music,
  MusicOC,
  Art,
  ArtOC,

  EconomicsAndLaw,
  EconomicsAndLawOS,
  EconomicsAndLawOC,

  TM,

  SportOC,

  Other,

  NotSet,
}

class SubjectHelper {
  static String toFrench(Subject s) {
    return toFrenchOrNull(s) ?? "Aucune branche";
  }

  static String? toFrenchOrNull(Subject? s) {
    switch (s) {
      case Subject.French:
        return "Français";
      case Subject.Italian:
        return "Italien";
      case Subject.English:
        return "Anglais";
      case Subject.German:
        return "Allemand";
      case Subject.Spanish:
        return "Espagnol";
      case Subject.SpanishOS:
        return "Espagnol OS";

      case Subject.Maths:
        return "Mathématiques";
      case Subject.MathsOS:
        return "Mathématiques OS";
      case Subject.MathsOC:
        return "Application des mathématiques OC";

      case Subject.Biology:
        return "Biologie";
      case Subject.BiologyOS:
        return "Biologie OS";
      case Subject.BiologyOC:
        return "Biologie OC";

      case Subject.Chemistry:
        return "Chimie";
      case Subject.ChemistryOS:
        return "Chimie OS";
      case Subject.ChemistryOC:
        return "Chimie OC";

      case Subject.Physics:
        return "Physique";
      case Subject.PhysicsOS:
        return "Physique OS";
      case Subject.PhysicsOC:
        return "Physique OC";

      case Subject.IT:
        return "Informatique";
      case Subject.ITOC:
        return "Informatique OC";

      case Subject.History:
        return "Histoire";
      case Subject.HistoryOC:
        return "Histoire OC";
      case Subject.Geography:
        return "Géographie";
      case Subject.GeographyOC:
        return "Géographie OC";

      case Subject.Philosophy:
        return "Philosophie";
      case Subject.PhilosophyOS:
        return "Philosophie OS";
      case Subject.Psychology:
        return "Psychologie";
      case Subject.PsychologyOS:
        return "Psychologie OS";

      case Subject.HistoryAndReligionsOC:
        return "Histoire et sciences des religions OC";

      case Subject.Music:
        return "Musique";
      case Subject.MusicOC:
        return "Musique OC";

      case Subject.Art:
        return "Art";
      case Subject.ArtOC:
        return "Arts visuels OC";

      case Subject.EconomicsAndLaw:
        return "Économie et Droit";
      case Subject.EconomicsAndLawOS:
        return "Économie et Droit OS";
      case Subject.EconomicsAndLawOC:
        return "Économie et Droit OC";

      case Subject.TM:
        return "Travail de Maturité";

      case Subject.SportOC:
        return "Sport OC";

      case Subject.Other:
        return "Autre";

      default:
        return null;
    }
  }

  static List<Subject> get sortedSubjects {
    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll('à', 'a')
          .replaceAll('â', 'a')
          .replaceAll('ä', 'a')
          .replaceAll('é', 'e')
          .replaceAll('è', 'e')
          .replaceAll('ê', 'e')
          .replaceAll('ë', 'e')
          .replaceAll('ï', 'i')
          .replaceAll('î', 'i')
          .replaceAll('ô', 'o')
          .replaceAll('ö', 'o')
          .replaceAll('ù', 'u')
          .replaceAll('û', 'u')
          .replaceAll('ü', 'u')
          .replaceAll('ç', 'c');
    }

    final list = Subject.values.toList();
    list.sort((a, b) => normalize(toFrench(a)).compareTo(normalize(toFrench(b))));
    return list;
  }

  static List<Assignment> searchBySimilarity(String query, Map<Subject, Assignment> allAssignment) {
    final lowerQuery = query.toLowerCase().trim();

    int similarityScore(Assignment hw) {
      int score = 0;
      if (hw.content.toLowerCase().contains(lowerQuery)) score += 10;
      if (hw.subject.name.toLowerCase().contains(lowerQuery)) score += 5;
      return score;
    }

    final filtered =
        allAssignment.values.where((hw) => hw.content.toLowerCase().contains(lowerQuery) || hw.subject.name.toLowerCase().contains(lowerQuery)).toList();

    filtered.sort((a, b) => similarityScore(b).compareTo(similarityScore(a)));

    return filtered;
  }

  static String? withPreposition(Subject? s, {bool lowercase = false}) {
    String? name = toFrenchOrNull(s);
    if (name == null) return null;

    if (lowercase) name = name.toLowerCase();

    final firstChar = name[0].toLowerCase();
    if ('aeiouàâäéèêëïîôöùûü'.contains(firstChar)) {
      return "d'$name";
    } else {
      return "de $name";
    }
  }
}

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 3;

  @override
  Subject read(BinaryReader reader) {
    final index = reader.readInt();
    return Subject.values[index];
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.writeInt(obj.index);
  }
}
