import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/group_service.dart';
import 'package:messagyre_client/services/report_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group("The rules of a school and year", () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      GlobalsService().persistent = await SharedPreferences.getInstance();
    });
    setUp(() => GlobalsService().persistent.clear());

    test("are found from the class", () {
      expect(ReportPreset.forClass(SchoolClass.tryParse("1C3"))?.id, "C1");
      expect(ReportPreset.forClass(SchoolClass.tryParse("2Cci1"))?.id, "C2");
      expect(ReportPreset.forClass(SchoolClass.tryParse("3Mb11"))?.id, "M3");
      expect(ReportPreset.forClass(SchoolClass.tryParse("2EC1"))?.id, "EC");
      // The 4th year of the école de commerce is the internship: no bulletin to set
      expect(ReportPreset.forClass(SchoolClass.tryParse("4EC1")), isNull);
      expect(ReportPreset.forClass(null), isNull);
    });

    test("the 1st year of the ECG asks 36 points, 3 insufficient averages and 2 negative points at most", () async {
      await ReportPreset.byId("C1")!.apply();
      final persistent = GlobalsService().persistent;
      expect(persistent.getInt("MinTotalPoints"), 36);
      expect(persistent.getInt("MaxFailingSubjects"), 3);
      expect(persistent.getBool("UseMaxNegativePoints"), isTrue);
      expect(persistent.getDouble("MaxNegativePoints"), 2);
      expect(persistent.getBool("UseDoubleCompensation"), isFalse);
      expect(ReportPreset.current?.id, "C1");
    });

    test("the école de commerce counts its limits on the restricted group (the MP subjects)", () async {
      await ReportPreset.byId("EC")!.apply();
      final persistent = GlobalsService().persistent;
      expect(persistent.getBool("UseRestrictedGroup"), isTrue);
      expect(persistent.getBool("LimitsOnRestrictedGroup"), isTrue);
      expect(persistent.getInt("MaxFailingSubjects"), 2);
      // Automatic minimum: 4 points per subject with an average
      expect(persistent.getInt("MinTotalPoints"), 0);
    });

    test("the 3rd year of maturité uses double compensation and no negative points", () async {
      await ReportPreset.byId("M3")!.apply();
      final persistent = GlobalsService().persistent;
      expect(persistent.getBool("UseDoubleCompensation"), isTrue);
      expect(persistent.getBool("UseMaxNegativePoints"), isFalse);
      expect(persistent.getInt("MinTotalPoints"), 56);
    });
  });

  group("A group chat", () {
    test("is told apart from a class chat", () {
      expect(GroupService.isGroupChat("#g-k3h9x2m1qa"), isTrue);
      expect(GroupService.groupOfChat("#g-k3h9x2m1qa"), "g-k3h9x2m1qa");
      expect(ClassService.isClassChat("#g-k3h9x2m1qa"), isFalse);
      expect(ClassService.isClassChat("#1M05"), isTrue);
      expect(GroupService.isGroupChat("#1M05"), isFalse);
      expect(GroupService.isGroupChat("lea.martin"), isFalse);
    });

    test("keeps its members and admins through the phone's copy", () {
      const group = ChatGroup(
        id: "g-volley2026",
        name: "Volley",
        members: [GroupMember(username: "a", isAdmin: true), GroupMember(username: "b", displayName: "Béa")],
      );
      final copy = ChatGroup.fromJson(group.toJson())!;
      expect(copy.isAdmin("a"), isTrue);
      expect(copy.isAdmin("b"), isFalse);
      expect(copy.memberNamed("b")?.name, "Béa");
      expect(copy.chatId, "#g-volley2026");
    });
  });
}
