import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/subjects.dart';

class CustomSubjectPicker extends StatefulWidget {
  final Subject initialSubject;
  final ValueChanged<Subject> onSubjectSelected;

  const CustomSubjectPicker({
    super.key,
    required this.initialSubject,
    required this.onSubjectSelected,
  });

  @override
  State<CustomSubjectPicker> createState() => _CustomSubjectPickerState();
}

class _CustomSubjectPickerState extends State<CustomSubjectPicker> {
  late Subject tempSubject;
  late FixedExtentScrollController controller;

  @override
  void initState() {
    super.initState();
    tempSubject = widget.initialSubject;
    controller = FixedExtentScrollController(initialItem: tempSubject.index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Annuler"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text("Branche", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Terminé",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
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
              itemExtent: 60,
              childCount: Subject.values.length,
              onSelectedItemChanged: (value) {
                tempSubject = Subject.values[value];
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Text(SubjectHelper.toFrench(Subject.values[index])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
