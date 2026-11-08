import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

/// Accounts that see the admin page (the server checks it too: GET /admin/stats)
const adminUsernames = {"pietro.gravina", "test.1", "test.2", "support.messagyre"};

class _OnlineUser {
  final String username;
  final String? displayName;
  final DateTime? since;
  _OnlineUser(this.username, this.displayName, this.since);
}

class _Stats {
  final List<_OnlineUser> online;
  final List<({DateTime time, int users})> series;
  final int activeUsers;
  final int totalAccounts;
  _Stats(this.online, this.series, this.activeUsers, this.totalAccounts);

  static _Stats? tryParse(dynamic json) {
    if (json is! Map) return null;
    try {
      return _Stats(
        [
          for (final user in json["Online"] as List)
            _OnlineUser(user["Username"], user["DisplayName"], DateTime.tryParse(user["Since"]?.toString() ?? "")?.toLocal()),
        ],
        [for (final point in json["Series"] as List) (time: DateTime.parse(point["Time"]).toLocal(), users: (point["Users"] as num).toInt())],
        (json["ActiveUsers"] as num).toInt(),
        (json["TotalAccounts"] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Who is connected now and how many people used the app: for the developer and the test accounts only
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final network = NetworkService();

  String range = "day";
  _Stats? stats;
  String? error;
  Timer? refreshTimer;

  Future<void> load() async {
    final response = await network.get("/admin/stats?Range=$range");
    if (!mounted) return;
    setState(() {
      final parsed = response.statusCode == 200 ? _Stats.tryParse(tryJsonDecode(response.body)) : null;
      if (parsed != null) stats = parsed;
      error = parsed == null ? AppStrings.errorFor(response) : null;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
    refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => load());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  /// One of the three figures at the top: same width and height for all three (labels of two short lines)
  Widget buildFigure(String value, String label) {
    return Expanded(
      child: RoundContainer(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, maxLines: 1, style: AppStyles.largeTitle(context).copyWith(color: AppColors.tint.adaptTo(context))),
            ),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.footnote(context)),
          ],
        ),
      ),
    );
  }

  String bucketLabel(DateTime time) => switch (range) {
    "day" => DateFormat("HH", "fr_CH").format(time),
    "week" => DateFormat("EEE", "fr_CH").format(time).replaceAll(".", ""),
    _ => DateFormat("d", "fr_CH").format(time),
  };

  Widget buildChart(List<({DateTime time, int users})> series) {
    final maxUsers = series.fold(0, (highest, point) => max(highest, point.users));
    final top = max(4, (maxUsers * 1.2).ceil()).toDouble();
    final labelEvery = switch (range) { "day" => 3, "week" => 1, _ => 5 };
    final textColor = AppColors.tertiaryText.adaptTo(context);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: top,
          minY: 0,
          alignment: BarChartAlignment.spaceBetween,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: max(1, (top / 4).ceilToDouble()),
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.separator.adaptTo(context), strokeWidth: .5),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: max(1, (top / 4).ceilToDouble()),
                getTitlesWidget: (value, meta) => SideTitleWidget(meta: meta, child: Text(value.toInt().toString(), style: AppStyles.caption(context).copyWith(color: textColor))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final lastIndex = series.length - 1;
                  // The last bucket always has its label: a regular one too close to it is left out (they overlapped)
                  final isShown = index == lastIndex || (index % labelEvery == 0 && lastIndex - index >= min(labelEvery, 3));
                  if (index < 0 || index > lastIndex || !isShown) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta), // the first and last labels stay inside the chart
                    child: Text(bucketLabel(series[index].time), style: AppStyles.caption(context).copyWith(color: textColor)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.tertiaryBackground.adaptTo(context),
              getTooltipItem: (group, _, rod, _) {
                final time = series[group.x].time;
                final when = range == "day" ? "${DateFormat("HH:00").format(time)}–${DateFormat("HH:00").format(time.add(const Duration(hours: 1)))}" : formatDate(time);
                return BarTooltipItem("$when\n${rod.toY.toInt()} utilisateur${rod.toY == 1 ? "" : "s"}", AppStyles.footnote(context).copyWith(color: AppColors.text.adaptTo(context)));
              },
            ),
          ),
          barGroups: [
            for (final (index, point) in series.indexed)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: point.users.toDouble(),
                    width: range == "month" ? 6 : (range == "week" ? 22 : 8),
                    gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color.fromRGBO(99, 25, 104, 1), Color.fromRGBO(190, 30, 200, 1)]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = stats;
    final rangeName = switch (range) { "day" => "dernières 24 h", "week" => "7 derniers jours", _ => "30 derniers jours" };
    final shortRangeName = switch (range) { "day" => "sur 24 h", "week" => "sur 7 jours", _ => "sur 30 jours" };

    return Page(
      topBar: TopBar.tab(context, title: "Administration"),
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Text(error!, textAlign: TextAlign.center, style: AppStyles.error(context)),
            ),
          if (current == null && error == null) const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CupertinoActivityIndicator()),
          if (current != null) ...[
            Row(
              spacing: AppSpacing.s,
              children: [
                buildFigure(current.online.length.toString(), "en ligne\nmaintenant"),
                buildFigure(current.activeUsers.toString(), "actifs\n$shortRangeName"),
                buildFigure(current.totalAccounts.toString(), "comptes\nau total"),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            SegmentedControl<String>(
              options: const {"Aujourd'hui": "day", "Semaine": "week", "Mois": "month"},
              onTap: (value) {
                setState(() => range = value);
                load();
              },
            ),
            const SizedBox(height: AppSpacing.l),
            Text("Utilisateurs actifs", style: AppStyles.secondaryHeader(context)),
            Text(range == "day" ? "Par heure, sur les dernières 24 heures" : "Par jour, sur les $rangeName", style: AppStyles.footnote(context)),
            const SizedBox(height: AppSpacing.m),
            buildChart(current.series),
            ListSection(
              title: "En ligne maintenant",
              margin: const EdgeInsets.only(top: AppSpacing.section),
              footer: current.online.isEmpty ? "Personne n'est connecté en ce moment." : "Mis à jour toutes les 15 secondes.",
              children: [
                for (final user in current.online)
                  ListTile(
                    buildChevron: false,
                    child: Row(
                      spacing: AppSpacing.m,
                      children: [
                        SizedBox.square(
                          dimension: AppSizes.avatarSmall,
                          child: ProfilePictureDisplay(accountUsername: user.username, includeBadge: false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName ?? Account.getDefaultDisplayName(user.username), style: AppStyles.strongText(context)),
                              Text(user.username, style: AppStyles.footnote(context)),
                            ],
                          ),
                        ),
                        if (user.since != null) Text("depuis ${DateFormat("HH:mm").format(user.since!)}", style: AppStyles.subheadline(context)),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.l),
              child: Text("Activité enregistrée depuis le 8 novembre 2026.", textAlign: TextAlign.center, style: AppStyles.footnote(context)),
            ),
          ],
          const BottomSpacing(),
        ],
      ),
    );
  }
}
