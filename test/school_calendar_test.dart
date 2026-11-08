import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/utility/school_calendar.dart';

void main() {
  test("the Vaud school year ends the Friday before the summer holidays (vd.ch)", () {
    expect(SchoolCalendar.yearEnd(2026), DateTime(2026, 6, 26));
    expect(SchoolCalendar.yearEnd(2027), DateTime(2027, 7, 2));
    expect(SchoolCalendar.yearEnd(2026).weekday, DateTime.friday);
    // A year missing from presets.dart still ends on a Friday at the end of June
    expect(SchoolCalendar.yearEnd(2040).weekday, DateTime.friday);
    expect(SchoolCalendar.yearEnd(2040).month, 6);
  });

  test("and starts again seven weeks later, on a Monday", () {
    expect(SchoolCalendar.yearStart(2026), DateTime(2026, 8, 17));
    expect(SchoolCalendar.yearStart(2027), DateTime(2027, 8, 23));
    expect(SchoolCalendar.startYearOf(DateTime(2026, 11, 8)), 2026);
    expect(SchoolCalendar.startYearOf(DateTime(2027, 3, 1)), 2026);
    expect(SchoolCalendar.labelOf(2025), "2025-2026");
  });

  test("archiving is offered from the end of the year until six weeks into the next one", () {
    expect(SchoolCalendar.isArchivePeriod(DateTime(2026, 6, 20)), isFalse);
    expect(SchoolCalendar.isArchivePeriod(DateTime(2026, 6, 27)), isTrue);
    expect(SchoolCalendar.isArchivePeriod(DateTime(2026, 9, 20)), isTrue);
    expect(SchoolCalendar.isArchivePeriod(DateTime(2026, 11, 8)), isFalse);
    expect(SchoolCalendar.endedYearLabel(DateTime(2026, 7, 10)), "2025-2026");
  });
}
