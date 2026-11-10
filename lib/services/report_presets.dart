import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/globals_service.dart';

/// The promotion rules of a school and year of the Gymnase, as the regulations write them (RGY, REM for the
/// maturité, RECG for the ECG, REcom for the école de commerce; GyRe's "vademecum" for the EC). Choosing one sets
/// the bulletin's rules at once; each rule can still be changed by hand.
class ReportPreset {
  final String id;
  final String title;
  final String subtitle;

  /// The rules in words, as the sheet lists them
  final List<String> rules;

  /// What the user still has to do by hand (the subjects of the restricted group can't be guessed)
  final String? todo;

  final int maxFailing;
  final bool doubleCompensation;
  final bool restrictedGroup;
  final bool limitsOnRestrictedGroup;
  final double? maxNegativePoints;

  /// 0: 4 points per subject with an average
  final int minTotalPoints;

  const ReportPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rules,
    this.todo,
    required this.maxFailing,
    this.doubleCompensation = false,
    this.restrictedGroup = false,
    this.limitsOnRestrictedGroup = false,
    this.maxNegativePoints,
    this.minTotalPoints = 0,
  });

  static const _basket =
      "Mettez dans le groupe restreint le français, une branche composée de vos deux langues (L2 et L3), les mathématiques et l'option spécifique : c'est le « panier », qui doit avoir 16 points.";

  static const all = [
    ReportPreset(
      id: "M1",
      title: "Maturité · 1re année",
      subtitle: "École de maturité, bilingue comprise",
      rules: ["Au moins 44 points (11 moyennes × 4)", "Au plus 4 moyennes insuffisantes", "Panier : au moins 16 points"],
      todo: _basket,
      maxFailing: 4,
      restrictedGroup: true,
      minTotalPoints: 44,
    ),
    ReportPreset(
      id: "M2",
      title: "Maturité · 2e année",
      subtitle: "École de maturité, bilingue comprise",
      rules: ["Au moins 44 points (11 moyennes × 4)", "Au plus 4 moyennes insuffisantes", "Panier : au moins 16 points"],
      todo: _basket,
      maxFailing: 4,
      restrictedGroup: true,
      minTotalPoints: 44,
    ),
    ReportPreset(
      id: "M3",
      title: "Maturité · 3e année",
      subtitle: "Certificat de maturité",
      rules: [
        "Au moins 56 points (14 moyennes × 4)",
        "Au plus 4 moyennes insuffisantes",
        "Double compensation des insuffisances",
        "Examens : au moins 3,5 points par examen (pas calculé ici)",
      ],
      maxFailing: 4,
      doubleCompensation: true,
      minTotalPoints: 56,
    ),
    ReportPreset(
      id: "C1",
      title: "ECG · 1re année",
      subtitle: "École de culture générale",
      rules: ["Au moins 36 points (9 moyennes × 4)", "Au plus 3 moyennes insuffisantes", "Au plus 2 points négatifs"],
      maxFailing: 3,
      maxNegativePoints: 2,
      minTotalPoints: 36,
    ),
    ReportPreset(
      id: "C2",
      title: "ECG · 2e année",
      subtitle: "École de culture générale, tous les domaines",
      rules: ["4 points par moyenne (10 ou 11 selon le domaine)", "Au plus 3 moyennes insuffisantes", "Au plus 2 points négatifs"],
      todo: "Le total minimum dépend de votre domaine : 4 points par moyenne du bulletin. Si une branche n'a pas encore de note, choisissez le total à la main (40 pour 10 moyennes, 44 pour 11).",
      maxFailing: 3,
      maxNegativePoints: 2,
    ),
    ReportPreset(
      id: "C3",
      title: "ECG · 3e année",
      subtitle: "Certificat de culture générale",
      rules: [
        "4 points par moyenne",
        "Au plus 3 moyennes insuffisantes",
        "Au plus 2 points négatifs",
        "Examens : au moins 3,5 points par examen (pas calculé ici)",
      ],
      maxFailing: 3,
      maxNegativePoints: 2,
    ),
    ReportPreset(
      id: "EC",
      title: "École de commerce · 1re à 3e année",
      subtitle: "Maturité professionnelle et CFC",
      rules: [
        "Moyenne générale d'au moins 4",
        "Branches MP : moyenne d'au moins 4",
        "Branches MP : au plus 2 moyennes insuffisantes",
        "Branches MP : au plus 2 points négatifs",
      ],
      todo: "Mettez dans le groupe restreint les branches de la maturité professionnelle (MP) : les limites ne comptent que celles-là.",
      maxFailing: 2,
      restrictedGroup: true,
      limitsOnRestrictedGroup: true,
      maxNegativePoints: 2,
    ),
  ];

  static ReportPreset? byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// The rules of my class (null for a class without known rules: the 4th year of the EC is the internship)
  static ReportPreset? forClass(SchoolClass? schoolClass) {
    if (schoolClass == null) return null;
    return switch (schoolClass.school) {
      "M" => byId("M${schoolClass.year}"),
      "C" => byId("C${schoolClass.year}"),
      "EC" => schoolClass.year <= 3 ? byId("EC") : null,
      _ => null,
    };
  }

  /// The one chosen for this bulletin (null: the rules were set by hand, or never)
  static ReportPreset? get current => byId(GlobalsService().persistent.getString("ReportPreset"));

  Future<void> apply() async {
    final persistent = GlobalsService().persistent;
    await persistent.setString("ReportPreset", id);
    await persistent.setInt("MaxFailingSubjects", maxFailing);
    await persistent.setBool("UseDoubleCompensation", doubleCompensation);
    await persistent.setBool("UseRestrictedGroup", restrictedGroup);
    await persistent.setBool("LimitsOnRestrictedGroup", limitsOnRestrictedGroup);
    await persistent.setBool("UseMaxNegativePoints", maxNegativePoints != null);
    if (maxNegativePoints != null) await persistent.setDouble("MaxNegativePoints", maxNegativePoints!);
    await persistent.setInt("MinTotalPoints", minTotalPoints);
  }
}
