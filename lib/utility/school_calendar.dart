import 'package:messagyre_client/utility/presets.dart';

/// The school year of the canton of Vaud (the gymnases follow the cantonal calendar, see vd.ch/vacances):
/// it ends on the Friday before the summer holidays (26 June 2026, 2 July 2027) and starts again on the
/// Monday after them, seven weeks later.
class SchoolCalendar {
  /// First day of the summer holidays (a Saturday), from presets.dart; for a year it doesn't know, the last
  /// Saturday of June (the usual start)
  static DateTime summerHolidaysStart(int year) {
    final known = vaudSchoolHolidays["Vacances d'été $year"];
    if (known != null) return known;
    var day = DateTime(year, 6, 30);
    while (day.weekday != DateTime.saturday) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
  }

  /// Last day of the school year ending in [year] (the Friday before the summer holidays)
  static DateTime yearEnd(int year) => summerHolidaysStart(year).subtract(const Duration(days: 1));

  /// First day of the school year starting in [year] (the Monday after the seven weeks of holidays)
  static DateTime yearStart(int year) => summerHolidaysStart(year).add(const Duration(days: 51));

  /// The year in which the school year containing [date] started
  static int startYearOf(DateTime date) => date.isBefore(yearStart(date.year)) ? date.year - 1 : date.year;

  /// "2025-2026"
  static String labelOf(int startYear) => "$startYear-${startYear + 1}";

  /// After the end of a school year, until six weeks into the next one: the time to offer archiving it
  static bool isArchivePeriod(DateTime now) {
    final end = yearEnd(now.year);
    return now.isAfter(end) && now.isBefore(yearStart(now.year).add(const Duration(days: 42)));
  }

  /// The school year that just ended (during [isArchivePeriod])
  static String endedYearLabel(DateTime now) => labelOf(now.year - 1);
}
