import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';

/// The bulletin's little animated lessons: a finger shows on a pretend version of the page what to touch, and the
/// text explains why. Every school and year has other rules (36 points in the 1st year of the ECG, 2 negative points,
/// the maturité's basket...): without being shown, nobody found where to set them.
class ReportTutorial extends StatefulWidget {
  final int initialStep;

  const ReportTutorial({super.key, this.initialStep = 0});

  static const steps = <({String title, String text})>[
    (
      title: "Réglez pour votre classe",
      text:
          "Touchez « Régler pour ma classe » et choisissez votre école et votre année : le bulletin prend les règles du règlement (total minimum, insuffisances, points négatifs…). Vous pouvez ensuite changer chaque règle.",
    ),
    (
      title: "Le total minimum",
      text:
          "Chaque moyenne du bulletin doit valoir 4 en moyenne : 9 moyennes demandent 36 points. Touchez « Total minimum » et choisissez le nombre. « Auto » compte 4 points par branche qui a déjà une moyenne.",
    ),
    (
      title: "Les insuffisances permises",
      text: "Le nombre de moyennes sous 4 que votre école accepte : 4 en maturité, 3 à l'ECG, 2 à l'école de commerce. Touchez la ligne et choisissez.",
    ),
    (
      title: "Les points négatifs",
      text:
          "Une moyenne de 3,5 donne 0,5 point négatif, un 3 en donne 1. À l'ECG et à l'école de commerce, il en faut 2 au plus : activez « Points négatifs max. » et choisissez la limite.",
    ),
    (
      title: "Le groupe restreint",
      text:
          "Quelques branches qui doivent aussi avoir 4 de moyenne ensemble. En maturité c'est le « panier » (français, langues, maths, option spécifique : 16 points) ; à l'école de commerce, les branches MP. Activez-le et ajoutez les branches.",
    ),
    (
      title: "La double compensation",
      text: "En 3e année de maturité : chaque point sous 4 compte double et doit être compensé par des points au-dessus de 4.",
    ),
  ];

  static Future<void> show(BuildContext context, {int initialStep = 0}) =>
      showCupertinoModalPopup(context: context, builder: (_) => ReportTutorial(initialStep: initialStep));

  @override
  State<ReportTutorial> createState() => _ReportTutorialState();
}

class _ReportTutorialState extends State<ReportTutorial> with SingleTickerProviderStateMixin {
  late final pageController = PageController(initialPage: widget.initialStep);
  late int step = widget.initialStep;
  late final animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat();

  @override
  void dispose() {
    animation.dispose();
    pageController.dispose();
    super.dispose();
  }

  Widget demoFor(int index) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      return switch (index) {
        0 => _PresetDemo(t: t),
        1 => _ValueDemo(t: t, icon: HugeIcons.strokeRoundedCalculator, title: "Total minimum", values: const ["Auto", "32", "36"]),
        2 => _ValueDemo(t: t, icon: HugeIcons.strokeRoundedAlertCircle, title: "Insuffisances permises", values: const ["4", "3"]),
        3 => _NegativeDemo(t: t),
        4 => _GroupDemo(t: t),
        _ => _CompensationDemo(t: t),
      };
    },
  );

  @override
  Widget build(BuildContext context) {
    final isLast = step == ReportTutorial.steps.length - 1;
    return SafeArea(
      top: false,
      minimum: const .fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.l),
      child: Container(
        height: math.min(560, MediaQuery.sizeOf(context).height * .8),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.card),
          border: .all(color: AppColors.outline.adaptTo(context)),
        ),
        clipBehavior: .antiAlias,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: ReportTutorial.steps.length,
                onPageChanged: (index) {
                  setState(() => step = index);
                  animation.forward(from: 0);
                  animation.repeat();
                },
                itemBuilder: (context, index) {
                  final content = ReportTutorial.steps[index];
                  return Padding(
                    padding: const .fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
                    child: Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        Container(
                          height: 230,
                          padding: const .all(AppSpacing.l),
                          decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(AppRadius.m)),
                          child: index == step ? demoFor(index) : const SizedBox(),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: .stretch,
                              spacing: AppSpacing.s,
                              children: [
                                Text(content.title, style: AppStyles.header(context)),
                                Text(content.text, style: AppStyles.secondaryText(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const .fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
              child: Row(
                children: [
                  // Where we are
                  for (var index = 0; index < ReportTutorial.steps.length; index++)
                    AnimatedContainer(
                      duration: AppDurations.normal,
                      curve: Curves.easeOutCubic,
                      margin: const .only(right: 6),
                      width: index == step ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: index == step ? AppColors.accent : AppColors.quaternaryText.adaptTo(context),
                        borderRadius: .circular(4),
                      ),
                    ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const .symmetric(horizontal: 18, vertical: 10),
                    minimumSize: .zero,
                    color: AppColors.accent,
                    borderRadius: .circular(AppRadius.l),
                    onPressed: () => isLast
                        ? Navigator.pop(context)
                        : pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                    child: Text(isLast ? "Terminé" : "Suivant", style: AppStyles.button(context).copyWith(color: AppColors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// #region -> Pieces of the pretend page

/// 0 → 1 between [start] and [end] of the loop, eased
double _phase(double t, double start, double end) => Curves.easeInOutCubic.transform(((t - start) / (end - start)).clamp(0.0, 1.0));

/// The whole demo fades out at the end of the loop and back in at its start
double _loopOpacity(double t) => t < .06 ? t / .06 : (t > .92 ? (1 - t) / .08 : 1);

/// A row like the bulletin's ListTiles
class _Row extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final Widget? trailing;
  final bool pressed;

  const _Row({required this.icon, required this.title, this.trailing, this.pressed = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 42,
      padding: const .symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: pressed ? AppColors.accentSoft.adaptTo(context) : AppColors.secondaryBackground.adaptTo(context),
        borderRadius: .circular(AppRadius.s),
      ),
      child: Row(
        spacing: AppSpacing.s,
        children: [
          AppIcon(icon: icon, size: 18, color: AppColors.tint.adaptTo(context)),
          Expanded(child: Text(title, style: AppStyles.primaryText(context), maxLines: 1, overflow: .ellipsis)),
          ?trailing,
        ],
      ),
    );
  }
}

/// The finger: comes from the bottom right, touches [target] at [touchAt] (fraction of the loop)
class _Finger extends StatelessWidget {
  final double t;
  final Offset target;
  final double touchAt;

  const _Finger({required this.t, required this.target, this.touchAt = .32});

  @override
  Widget build(BuildContext context) {
    final travel = _phase(t, .08, touchAt - .04);
    final press = t > touchAt - .04 && t < touchAt + .06 ? math.sin(((t - (touchAt - .04)) / .1) * math.pi) : 0.0;
    final leave = _phase(t, .8, .95);
    final start = target + const Offset(70, 90);
    final position = Offset.lerp(start, target, travel)! + Offset(0, 40 * leave);
    return Positioned(
      left: position.dx - 15,
      top: position.dy - 15,
      child: IgnorePointer(
        child: Opacity(
          opacity: (travel * (1 - leave)).clamp(0, 1),
          child: Transform.scale(
            scale: 1 - .22 * press,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: .35 + .3 * press),
                border: .all(color: AppColors.white, width: 2.5),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .25), blurRadius: 10)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final double on;

  const _Switch({required this.on});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 24,
      padding: const .all(2),
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.quaternaryText.adaptTo(context), AppColors.accent, on),
        borderRadius: .circular(12),
      ),
      child: Align(
        alignment: Alignment(-1 + 2 * on, 0),
        child: Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white)),
      ),
    );
  }
}

/// A value that rolls from one to the next, like the picker's wheel
class _RollingValue extends StatelessWidget {
  final List<String> values;
  final double progress;

  const _RollingValue({required this.values, required this.progress});

  @override
  Widget build(BuildContext context) {
    final position = progress * (values.length - 1);
    final index = position.floor().clamp(0, values.length - 1);
    final next = math.min(index + 1, values.length - 1);
    final fraction = position - index;
    final style = AppStyles.strongText(context).copyWith(color: AppColors.tint.adaptTo(context));
    return SizedBox(
      width: 48,
      height: 24,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Transform.translate(offset: Offset(0, -22 * fraction), child: Opacity(opacity: 1 - fraction, child: Text(values[index], style: style))),
            if (next != index)
              Transform.translate(offset: Offset(0, 22 * (1 - fraction)), child: Opacity(opacity: fraction, child: Text(values[next], style: style))),
          ],
        ),
      ),
    );
  }
}

// #endregion

// #region -> The demos

class _PresetDemo extends StatelessWidget {
  final double t;

  const _PresetDemo({required this.t});

  @override
  Widget build(BuildContext context) {
    final open = _phase(t, .36, .5);
    final check = _phase(t, .66, .74);
    final options = ["Maturité · 1re année", "ECG · 1re année", "École de commerce"];
    return Opacity(
      opacity: _loopOpacity(t),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: .none,
          children: [
            Column(
              crossAxisAlignment: .stretch,
              spacing: 6,
              children: [
                _Row(icon: HugeIcons.strokeRoundedSchool, title: "Régler pour ma classe", pressed: t > .28 && t < .4),
                for (var index = 0; index < options.length; index++)
                  Opacity(
                    opacity: _phase(open, index * .2, .6 + index * .2),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _phase(open, index * .2, .6 + index * .2))),
                      child: _Row(
                        icon: HugeIcons.strokeRoundedBook02,
                        title: options[index],
                        pressed: index == 1 && t > .58 && t < .68,
                        trailing: index == 1
                            ? Transform.scale(
                                scale: check,
                                child: AppIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 20, color: AppColors.gradeGood.adaptTo(context)),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            _Finger(t: t, target: Offset(constraints.maxWidth * .45, 23), touchAt: .32),
            if (t > .5) _Finger(t: (t - .3).clamp(0, 1), target: Offset(constraints.maxWidth * .45, 23 + 52 * 2), touchAt: .32),
          ],
        ),
      ),
    );
  }
}

class _ValueDemo extends StatelessWidget {
  final double t;
  final List<List<dynamic>> icon;
  final String title;
  final List<String> values;

  const _ValueDemo({required this.t, required this.icon, required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    final roll = _phase(t, .42, .7);
    final sheet = _phase(t, .36, .44) * (1 - _phase(t, .76, .84));
    return Opacity(
      opacity: _loopOpacity(t),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: .none,
          children: [
            Column(
              crossAxisAlignment: .stretch,
              spacing: AppSpacing.m,
              children: [
                _Row(icon: icon, title: title, pressed: t > .28 && t < .4, trailing: _RollingValue(values: values, progress: roll)),
                // The wheel that opens to choose
                Opacity(
                  opacity: sheet,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - sheet)),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(AppRadius.s)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 30,
                            margin: const .symmetric(horizontal: AppSpacing.m),
                            decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(8)),
                          ),
                          // The wheel's values, the chosen one in the middle band (40 = (110 - 30) / 2)
                          Positioned.fill(
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  for (final (index, value) in [...values, "40", "44"].indexed)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 40 + 30.0 * index - 30 * roll * (values.length - 1),
                                      height: 30,
                                      child: Center(child: Text(value, style: AppStyles.primaryText(context))),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _Finger(t: t, target: Offset(constraints.maxWidth * .5, 23)),
          ],
        ),
      ),
    );
  }
}

class _NegativeDemo extends StatelessWidget {
  final double t;

  const _NegativeDemo({required this.t});

  @override
  Widget build(BuildContext context) {
    final on = _phase(t, .34, .42);
    final count = _phase(t, .5, .7);
    final negative = 1.5 * count;
    Widget grade(String name, String value, double gap) => Expanded(
      child: Container(
        padding: const .symmetric(vertical: 6),
        decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(10)),
        child: Column(
          children: [
            Text(name, style: AppStyles.caption(context)),
            Text(value, style: AppStyles.strongText(context).copyWith(color: AppColors.gradeLow.adaptTo(context))),
            Opacity(opacity: count, child: Text("−${gap.toString().replaceAll(".", ",")}", style: AppStyles.caption(context))),
          ],
        ),
      ),
    );
    return Opacity(
      opacity: _loopOpacity(t),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: .none,
          children: [
            Column(
              crossAxisAlignment: .stretch,
              spacing: 6,
              children: [
                _Row(icon: HugeIcons.strokeRoundedRemoveCircle, title: "Points négatifs max.", pressed: t > .28 && t < .4, trailing: _Switch(on: on)),
                Opacity(
                  opacity: on,
                  child: _Row(icon: HugeIcons.strokeRoundedRuler, title: "Limite", trailing: Text("2", style: AppStyles.strongText(context).copyWith(color: AppColors.tint.adaptTo(context)))),
                ),
                Row(spacing: AppSpacing.s, children: [grade("Allemand", "3,5", .5), grade("Physique", "3", 1), grade("Histoire", "5", 0)]),
                Opacity(
                  opacity: count,
                  child: Text(
                    "${negative.toStringAsFixed(1).replaceAll(".", ",")} point${negative > 1 ? "s" : ""} négatif${negative > 1 ? "s" : ""} sur 2 : c'est bon",
                    textAlign: .center,
                    style: AppStyles.footnote(context).copyWith(color: AppColors.gradeGood.adaptTo(context)),
                  ),
                ),
              ],
            ),
            _Finger(t: t, target: Offset(constraints.maxWidth - 34, 23)),
          ],
        ),
      ),
    );
  }
}

class _GroupDemo extends StatelessWidget {
  final double t;

  const _GroupDemo({required this.t});

  @override
  Widget build(BuildContext context) {
    final on = _phase(t, .34, .42);
    final subjects = ["Français", "Langues", "Maths", "Option sp."];
    return Opacity(
      opacity: _loopOpacity(t),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: .none,
          children: [
            Column(
              crossAxisAlignment: .stretch,
              spacing: AppSpacing.m,
              children: [
                _Row(icon: HugeIcons.strokeRoundedLayers01, title: "Groupe restreint", pressed: t > .28 && t < .4, trailing: _Switch(on: on)),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (var index = 0; index < subjects.length; index++)
                      Builder(
                        builder: (context) {
                          final appear = _phase(t, .46 + index * .06, .54 + index * .06);
                          return Opacity(
                            opacity: appear,
                            child: Transform.scale(
                              scale: .7 + .3 * appear,
                              child: Container(
                                padding: const .symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(color: AppColors.accentSoft.adaptTo(context), borderRadius: .circular(20)),
                                child: Text(subjects[index], style: AppStyles.footnote(context).copyWith(color: AppColors.tint.adaptTo(context))),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                Opacity(
                  opacity: _phase(t, .72, .8),
                  child: Text("16 points au moins", textAlign: .center, style: AppStyles.footnote(context).copyWith(color: AppColors.gradeGood.adaptTo(context))),
                ),
              ],
            ),
            _Finger(t: t, target: Offset(constraints.maxWidth - 34, 23)),
          ],
        ),
      ),
    );
  }
}

class _CompensationDemo extends StatelessWidget {
  final double t;

  const _CompensationDemo({required this.t});

  @override
  Widget build(BuildContext context) {
    final low = _phase(t, .15, .4);
    final high = _phase(t, .45, .7);
    // −0.5 counted twice, +1.5 above 4: 0.5 left
    final balance = -1.0 * low + 1.5 * high;
    final color = (balance >= 0 ? AppColors.gradeGood : AppColors.gradeLow).adaptTo(context);
    return Opacity(
      opacity: _loopOpacity(t),
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisAlignment: .center,
        spacing: AppSpacing.m,
        children: [
          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Opacity(opacity: .3 + .7 * low, child: Text("3,5 → −0,5 × 2", style: AppStyles.strongText(context).copyWith(color: AppColors.gradeLow.adaptTo(context)))),
              Opacity(opacity: .3 + .7 * high, child: Text("5,5 → +1,5", style: AppStyles.strongText(context).copyWith(color: AppColors.gradeGood.adaptTo(context)))),
            ],
          ),
          // A bar centred on zero
          SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final half = constraints.maxWidth / 2;
                final width = (balance.abs() / 1.5).clamp(0.0, 1.0) * half;
                return Stack(
                  children: [
                    Container(decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(6))),
                    Positioned(
                      left: balance >= 0 ? half : half - width,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: Container(decoration: BoxDecoration(color: color, borderRadius: .circular(6))),
                    ),
                    Positioned(left: half - 1, width: 2, top: 0, bottom: 0, child: Container(color: AppColors.secondaryText.adaptTo(context))),
                  ],
                );
              },
            ),
          ),
          Text(
            balance >= 0 ? "Compensé : +${balance.toStringAsFixed(1).replaceAll(".", ",")}" : "Encore ${(-balance).toStringAsFixed(1).replaceAll(".", ",")} à compenser",
            textAlign: .center,
            style: AppStyles.footnote(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// #endregion
