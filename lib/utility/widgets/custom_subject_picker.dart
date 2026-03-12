import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/subjects.dart';

class CustomSubjectPicker extends StatefulWidget {
  final ValueChanged<Subject> onSubjectSelected;

  const CustomSubjectPicker({super.key, required this.onSubjectSelected});

  @override
  State<CustomSubjectPicker> createState() => _CustomSubjectPickerState();
}

class _CustomSubjectPickerState extends State<CustomSubjectPicker> {
  late Subject tempSubject;
  late FixedExtentScrollController controller;

  final sortedSubjects = SubjectHelper.sortedSubjects;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(color: AppColors.background.adaptTo(context), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        children: [
          Container(
            color: AppColors.background.adaptTo(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Annuler"), onPressed: () => Navigator.of(context).pop()),
                Text("Branche", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Terminé", style: TextStyle(fontWeight: FontWeight.w500)),
                  onPressed: () {
                    widget.onSubjectSelected(tempSubject);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker.builder(
              scrollController: controller,
              itemExtent: 40,
              childCount: sortedSubjects.length,
              onSelectedItemChanged: (value) {
                tempSubject = sortedSubjects[value];
              },
              itemBuilder: (context, index) {
                return Center(child: Text(SubjectHelper.toFrench(sortedSubjects[index])));
              },
            ),
          ),
        ],
      ),
    );
  }
}
