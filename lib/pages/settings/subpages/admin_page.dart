import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
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

/// Someone who was online in the chosen period
class _ActiveUser {
  final String username;
  final String? displayName;
  final String? classOrRole;
  final String? pictureUrl;

  /// The version of the app they last used ("4.105.1015"), null when it never told it
  final String? appVersion;
  final DateTime lastSeen;

  /// In how many hours of the period they were online
  final int hours;
  _ActiveUser(this.username, this.displayName, this.classOrRole, this.pictureUrl, this.appVersion, this.lastSeen, this.hours);
}

/// A class this school year, with its delegates (to name them by hand)
class _AdminClass {
  final String name;
  final List<String> members;
  final String? delegate;
  final String? viceDelegate;
  _AdminClass(this.name, this.members, this.delegate, this.viceDelegate);
}

class _Stats {
  final List<_OnlineUser> online;
  final List<({DateTime time, int users})> series;
  final int activeUsers;
  final int totalAccounts;
  final List<_ActiveUser> users;
  _Stats(this.online, this.series, this.activeUsers, this.totalAccounts, this.users);

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
        [
          // A server older than this page has no list: empty
          for (final user in (json["Users"] as List?) ?? const [])
            _ActiveUser(
              user["Username"].toString(),
              user["DisplayName"]?.toString(),
              user["ClassOrRole"]?.toString(),
              user["ProfilePictureURL"]?.toString(),
              (user["AppVersion"] as String?)?.trim().isNotEmpty == true ? user["AppVersion"] as String : null,
              DateTime.tryParse(user["LastSeen"]?.toString() ?? "")?.toLocal() ?? DateTime.now(),
              (user["Hours"] as num?)?.toInt() ?? 0,
            ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

/// What an account put in the app (GET /admin/usage, from the Analytics table: the app sends its counts at every start)
class _Usage {
  final String username;
  final String? displayName;
  final String? classOrRole;
  final int grades, assignments, chats, messages, onlineSeconds;
  _Usage(this.username, this.displayName, this.classOrRole, this.grades, this.assignments, this.chats, this.messages, this.onlineSeconds);

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static _Usage? fromJson(Object? json) {
    if (json is! Map || json["Username"] == null) return null;
    return _Usage(
      json["Username"].toString(),
      json["DisplayName"]?.toString(),
      json["ClassOrRole"]?.toString(),
      _int(json["Grades"]),
      _int(json["Assignments"]),
      _int(json["Chats"]),
      _int(json["Messages"]),
      _int(json["OnlineSeconds"]),
    );
  }

  int valueOf(String key) => switch (key) {
    "Grades" => grades,
    "Assignments" => assignments,
    "Messages" => messages,
    "Chats" => chats,
    _ => onlineSeconds,
  };
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

  /// Show every active user of the period, not only the first ones
  bool showAllUsers = false;

  /// How many active users are on each version, the newest first (unknown: apps that never told it, last)
  static List<(String?, int)> versionCounts(List<_ActiveUser> users) {
    final counts = <String?, int>{};
    for (final user in users) {
      counts[user.appVersion] = (counts[user.appVersion] ?? 0) + 1;
    }
    List<int> parts(String version) => [for (final part in version.split(RegExp(r'[.+]'))) int.tryParse(part) ?? 0];
    int compare(String? a, String? b) {
      if (a == null || b == null) return a == b ? 0 : (a == null ? 1 : -1);
      final (left, right) = (parts(a), parts(b));
      for (var index = 0; index < left.length && index < right.length; index++) {
        if (left[index] != right[index]) return right[index].compareTo(left[index]);
      }
      return right.length.compareTo(left.length);
    }

    return [for (final version in counts.keys.toList()..sort(compare)) (version, counts[version]!)];
  }

  List<_AdminClass>? classes;
  String? classesError;

  /// How the server's reading of the school's list of classes went (GET /admin/catalog)
  Map? catalogStatus;
  String? catalogError;
  bool isRefreshingCatalog = false;

  Future<void> loadCatalogStatus({bool refresh = false}) async {
    if (refresh) setState(() => isRefreshingCatalog = true);
    final response = refresh ? await network.post("/admin/catalog/refresh", {}) : await network.get("/admin/catalog");
    if (!mounted) return;
    final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
    setState(() {
      isRefreshingCatalog = false;
      catalogStatus = data is Map ? data : catalogStatus;
      catalogError = data is Map ? null : AppStrings.errorFor(response);
    });
  }

  Widget buildCatalogStatus() {
    final status = catalogStatus;
    String when(Object? value) {
      final time = DateTime.tryParse(value?.toString() ?? "")?.toLocal();
      return time == null ? "jamais" : "${lastSeenLabel(time)}${time.isSameDayAs(DateTime.now()) ? "" : " à ${DateFormat("HH:mm").format(time)}"}";
    }

    final problem = status?["Error"]?.toString();
    return ListSection(
      title: "Liste des classes",
      margin: const EdgeInsets.only(top: AppSpacing.section),
      footer: catalogError ??
          (problem != null
              ? "Problème à la dernière lecture : $problem. La liste précédente reste utilisée."
              : "Lue automatiquement toutes les 6 heures sur le site du Gymnase (Maîtrises de classe) : les classes de la nouvelle année arrivent toutes seules."),
      children: [
        if (status != null) ...[
          ListTile.simple(
            context,
            title: "Classes",
            buildChevron: false,
            trailing: Text("${status["Classes"]} · ${status["FromSchool"] == true ? "site du Gymnase" : "copie de l'app"}", style: AppStyles.subheadline(context)),
          ),
          ListTile.simple(context, title: "Dernière lecture", buildChevron: false, trailing: Text(when(status["CheckedAt"]), style: AppStyles.subheadline(context))),
          ListTile.simple(context, title: "Dernier changement", buildChevron: false, trailing: Text(when(status["ChangedAt"]), style: AppStyles.subheadline(context))),
        ],
        ListTile.simple(
          context,
          title: "Lire maintenant",
          icon: AppIcons.retry,
          buildChevron: false,
          isLoading: isRefreshingCatalog,
          onTap: isRefreshingCatalog ? null : () => loadCatalogStatus(refresh: true),
        ),
      ],
    );
  }

  /// The people reported in the global chat (GET /admin/global)
  List<Map>? reported;
  String? reportedError;

  Future<void> loadReported() async {
    final response = await network.get("/admin/global");
    if (!mounted) return;
    final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
    setState(() {
      reported = data is List ? data.whereType<Map>().toList() : reported;
      reportedError = data is List ? null : AppStrings.errorFor(response);
    });
  }

  Future<void> pardon(String username) async {
    final response = await network.post("/admin/global/pardon", {"Username": username});
    if (!mounted) return;
    if (response.statusCode != 200) {
      showCupertinoDialog(context: context, builder: (_) => Dialog.networkError(response));
      return;
    }
    loadReported();
  }

  Widget buildReported() {
    final rows = reported ?? const [];
    return ListSection(
      title: "Conversation générale",
      margin: const EdgeInsets.only(top: AppSpacing.section),
      footer: reportedError ??
          (rows.isEmpty
              ? "Personne n'a été signalé."
              : "Signalée par 3 personnes, une personne ne peut plus écrire pendant 3 jours ; par 5, elle est exclue. Touchez pour lui pardonner (signalements effacés)."),
      children: [
        for (final row in rows)
          ListTile(
            buildChevron: false,
            onTap: () => showCupertinoDialog(
              context: context,
              builder: (_) => Dialog.confirm(
                content: "Pardonner à *${row["Username"]}* ? Ses signalements sont effacés et ses sanctions levées.",
                onConfirm: () => pardon(row["Username"].toString()),
              ),
            ),
            child: Row(
              spacing: AppSpacing.m,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row["DisplayName"]?.toString() ?? Account.getDefaultDisplayName(row["Username"].toString()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.strongText(context),
                      ),
                      Text(
                        [
                          row["Username"].toString(),
                          if (row["Banned"] == true) "exclu",
                          if (row["Banned"] != true && DateTime.tryParse(row["MutedUntil"]?.toString() ?? "")?.isAfter(DateTime.now()) == true)
                            "sans écrire jusqu'au ${DateFormat("d MMM HH:mm", "fr_CH").format(DateTime.parse(row["MutedUntil"].toString()).toLocal())}",
                        ].join(" · "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.footnote(context),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${row["Reports"]} signalement${(row["Reports"] as num? ?? 0) > 1 ? "s" : ""}",
                  style: AppStyles.subheadline(context).copyWith(color: row["Banned"] == true ? AppColors.red : null),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<_Usage>? usage;
  String? usageError;
  String usageSort = "Grades";
  bool showAllUsage = false;

  Future<void> loadUsage() async {
    final response = await network.get("/admin/usage");
    if (!mounted) return;
    final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
    setState(() {
      if (data is List) {
        usage = [for (final item in data) ?_Usage.fromJson(item)];
        usageError = null;
      } else {
        usageError = AppStrings.errorFor(response);
      }
    });
  }

  /// "2 h 05", "12 min", "40 s"
  static String durationLabel(int seconds) {
    if (seconds >= 3600) return "${seconds ~/ 3600} h ${((seconds % 3600) ~/ 60).toString().padLeft(2, "0")}";
    if (seconds >= 60) return "${seconds ~/ 60} min";
    return "$seconds s";
  }

  Widget buildUsage() {
    final rows = usage;
    if (rows == null) {
      return ListSection(
        title: "Utilisation",
        margin: const EdgeInsets.only(top: AppSpacing.section),
        footer: usageError,
        children: [if (usageError == null) const ListTile(buildChevron: false, child: Center(child: GymnaseLoader(size: 18)))],
      );
    }

    String plural(int count, String one, String many) => "$count ${count == 1 ? one : many}";
    ListTile total(String title, int sum, int accounts) => ListTile.simple(
      context,
      title: title,
      buildChevron: false,
      trailing: Text("$sum · ${plural(accounts, "compte", "comptes")}", style: AppStyles.subheadline(context)),
    );
    int sumOf(int Function(_Usage) value) => rows.fold(0, (sum, row) => sum + value(row));
    int accountsWith(int Function(_Usage) value) => rows.where((row) => value(row) > 0).length;

    final sorted = rows.where((row) => row.valueOf(usageSort) > 0).toList()..sort((a, b) => b.valueOf(usageSort).compareTo(a.valueOf(usageSort)));
    final shown = showAllUsage ? sorted : sorted.take(30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSection(
          title: "Utilisation",
          margin: const EdgeInsets.only(top: AppSpacing.section),
          footer: "Au total, et combien de comptes en ont au moins un. Envoyé par l'app à chaque démarrage (les versions avant la 4.108 seulement en ouvrant les pages).",
          children: [
            total("Notes", sumOf((row) => row.grades), accountsWith((row) => row.grades)),
            total("Devoirs", sumOf((row) => row.assignments), accountsWith((row) => row.assignments)),
            total("Conversations", sumOf((row) => row.chats), accountsWith((row) => row.chats)),
            total("Messages", sumOf((row) => row.messages), accountsWith((row) => row.messages)),
            ListTile.simple(
              context,
              title: "Temps en ligne",
              buildChevron: false,
              trailing: Text(durationLabel(sumOf((row) => row.onlineSeconds)), style: AppStyles.subheadline(context)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        SegmentedControl<String>(
          options: const {"Notes": "Grades", "Devoirs": "Assignments", "Messages": "Messages", "Temps": "Online"},
          onTap: (value) => setState(() {
            usageSort = value;
            showAllUsage = false;
          }),
        ),
        ListSection(
          margin: const EdgeInsets.only(top: AppSpacing.m),
          footer: sorted.isEmpty ? "Personne pour l'instant." : "Les comptes qui en ont, du plus au moins.",
          children: [
            for (final row in shown)
              ListTile(
                buildChevron: false,
                child: Row(
                  spacing: AppSpacing.m,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.displayName ?? Account.getDefaultDisplayName(row.username), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.strongText(context)),
                          Text(
                            [
                              row.username,
                              ?row.classOrRole,
                              plural(row.grades, "note", "notes"),
                              plural(row.assignments, "devoir", "devoirs"),
                              plural(row.messages, "message", "messages"),
                              durationLabel(row.onlineSeconds),
                            ].join(" · "),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.footnote(context),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      usageSort == "Online" ? durationLabel(row.onlineSeconds) : row.valueOf(usageSort).toString(),
                      style: AppStyles.strongText(context).copyWith(color: AppColors.tint.adaptTo(context)),
                    ),
                  ],
                ),
              ),
            if (!showAllUsage && sorted.length > 30)
              ListTile.simple(
                context,
                title: "Afficher les ${sorted.length - 30} autres",
                icon: AppIcons.chevronDown,
                buildChevron: false,
                onTap: () => setState(() => showAllUsage = true),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> loadClasses() async {
    final response = await network.get("/admin/classes");
    if (!mounted) return;
    final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
    setState(() {
      if (data is List) {
        classes = [
          for (final item in data.whereType<Map>())
            _AdminClass(
              item["Class"].toString(),
              [for (final member in (item["Members"] as List? ?? const [])) member.toString()],
              item["Delegate"]?.toString(),
              item["ViceDelegate"]?.toString(),
            ),
        ];
        classesError = null;
      } else {
        classesError = AppStrings.errorFor(response);
      }
    });
  }

  /// Names a delegate by hand (or gives the choice back to the votes)
  Future<void> editDelegates(_AdminClass schoolClass) async {
    final role = await ActionSheet.show<String>(
      context,
      title: "Classe ${schoolClass.name}",
      message: "Délégué·e : ${schoolClass.delegate ?? "personne"}\nVice : ${schoolClass.viceDelegate ?? "personne"}",
      actions: const [
        SheetAction("Nommer le délégué", icon: AppIcons.edit, value: "Delegate"),
        SheetAction("Nommer le vice", icon: AppIcons.edit, value: "Vice"),
      ],
    );
    if (role == null || !mounted) return;

    final username = await ActionSheet.show<String>(
      context,
      title: role == "Delegate" ? "Délégué·e de la ${schoolClass.name}" : "Vice de la ${schoolClass.name}",
      actions: [
        const SheetAction("Selon les votes de la classe", icon: AppIcons.members, value: ""),
        for (final member in schoolClass.members) SheetAction(member, icon: AppIcons.profile, value: member),
      ],
    );
    if (username == null || !mounted) return;

    final response = await network.post("/admin/classes/delegate", {"Class": schoolClass.name, "Role": role, "Username": username.isEmpty ? null : username});
    if (!mounted) return;
    if (response.statusCode != 200) {
      showCupertinoDialog(context: context, builder: (_) => Dialog.networkError(response));
      return;
    }
    loadClasses();
  }

  /// "à 14:05" today, "hier", "3 nov." before
  String lastSeenLabel(DateTime time) {
    final now = DateTime.now();
    if (time.isSameDayAs(now)) return "à ${DateFormat("HH:mm").format(time)}";
    if (time.isSameDayAs(now.subtract(const Duration(days: 1)))) return "hier";
    return DateFormat("d MMM", "fr_CH").format(time);
  }

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
    loadClasses();
    loadUsage();
    loadCatalogStatus();
    loadReported();
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
          if (current == null && error == null) const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: GymnaseLoader(size: 22))),
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
            ListSection(
              title: "Actifs $shortRangeName (${current.users.length})",
              margin: const EdgeInsets.only(top: AppSpacing.section),
              footer: current.users.isEmpty
                  ? "Personne n'a utilisé l'application $shortRangeName."
                  : "Du plus récent au plus ancien, avec le nombre d'heures où ils étaient en ligne.",
              children: [
                for (final user in showAllUsers ? current.users : current.users.take(30))
                  ListTile(
                    buildChevron: false,
                    child: Row(
                      spacing: AppSpacing.m,
                      children: [
                        SizedBox.square(
                          dimension: AppSizes.avatarSmall,
                          child: ProfilePictureDisplay(accountUsername: user.username, pictureURL: user.pictureUrl, includeBadge: false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? Account.getDefaultDisplayName(user.username),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.strongText(context),
                              ),
                              Text(
                                [user.username, ?user.classOrRole].join(" · "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.footnote(context),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(lastSeenLabel(user.lastSeen), style: AppStyles.subheadline(context)),
                            Text([if (user.appVersion != null) "v${user.appVersion}", "${user.hours} h"].join(" · "), style: AppStyles.footnote(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (!showAllUsers && current.users.length > 30)
                  ListTile.simple(
                    context,
                    title: "Afficher les ${current.users.length - 30} autres",
                    icon: AppIcons.chevronDown,
                    buildChevron: false,
                    onTap: () => setState(() => showAllUsers = true),
                  ),
              ],
            ),
            if (current.users.isNotEmpty)
              ListSection(
                title: "Versions de l'app $shortRangeName",
                margin: const EdgeInsets.only(top: AppSpacing.section),
                footer: "La dernière version utilisée par chaque personne active, de la plus récente à la plus ancienne.",
                children: [
                  for (final (version, count) in versionCounts(current.users))
                    ListTile.simple(
                      context,
                      title: version == null ? "Inconnue" : "v$version",
                      buildChevron: false,
                      trailing: Text(count == 1 ? "1 personne" : "$count personnes", style: AppStyles.subheadline(context)),
                    ),
                ],
              ),
            buildUsage(),
            buildCatalogStatus(),
            buildReported(),
            ListSection(
              title: "Délégués des classes",
              margin: const EdgeInsets.only(top: AppSpacing.section),
              footer: classesError ??
                  ((classes?.isEmpty ?? false)
                      ? "Aucune classe choisie cette année."
                      : "Élus par les votes de chaque classe. Touchez une classe pour nommer quelqu'un à la main."),
              children: [
                for (final schoolClass in classes ?? const <_AdminClass>[])
                  ListTile(
                    onTap: () => editDelegates(schoolClass),
                    leading: ClassAvatar(className: schoolClass.name, size: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${schoolClass.name} · ${schoolClass.members.length} membres", style: AppStyles.strongText(context)),
                        Text(
                          "Délégué·e : ${schoolClass.delegate ?? "—"} · Vice : ${schoolClass.viceDelegate ?? "—"}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.footnote(context),
                        ),
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
