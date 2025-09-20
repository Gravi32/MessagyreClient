import 'package:hive_flutter/hive_flutter.dart';

enum Subject {
  French,
  Italian,
  English,
  German,
  Spanish,
  SpanishOS,
  
  Maths,
  MathsOS,
  Biology,
  BiologyOS,
  Chemistry,
  ChemistryOS,
  Physics,
  PhysicsOS,
  
  IT,
  
  History,
  Geography,
  Philosophy,
  PhilosophyOS,
  Psychology,
  PsychologyOS,
  
  Music,
  Art,
  
  EconomicsAndLaw,
  EconomicsAndLawOS,
  
  TM,
}

class SubjectHelper {
  static String toFrench(Subject s) {
    switch (s) {
      case Subject.French: return "Français";
      case Subject.Italian: return "Italien";
      case Subject.English: return "Anglais";
      case Subject.German: return "Allemand";
      case Subject.Spanish: return "Espagnol";
      case Subject.SpanishOS: return "Espagnol OS";

      case Subject.Maths: return "Mathématiques";
      case Subject.MathsOS: return "Mathématiques OS";
      case Subject.Biology: return "Biologie";
      case Subject.BiologyOS: return "Biologie OS";
      case Subject.Chemistry: return "Chimie";
      case Subject.ChemistryOS: return "Chimie OS";
      case Subject.Physics: return "Physique";
      case Subject.PhysicsOS: return "Physique OS";

      case Subject.IT: return "Informatique";

      case Subject.History: return "Histoire";
      case Subject.Geography: return "Géographie";
      case Subject.Philosophy: return "Philosophie";
      case Subject.PhilosophyOS: return "Philosophie OS";
      case Subject.Psychology: return "Psychologie";
      case Subject.PsychologyOS: return "Psychologie OS";

      case Subject.Music: return "Musique";
      case Subject.Art: return "Art";

      case Subject.EconomicsAndLaw: return "Économie et Droit";
      case Subject.EconomicsAndLawOS: return "Économie et Droit OS";

      case Subject.TM: return "Travail de Maturité";
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
