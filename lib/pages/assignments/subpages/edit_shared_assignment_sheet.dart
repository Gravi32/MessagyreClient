import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';

/// Changes an assignment shared with the class (its author, or the class's delegates). Pops true once saved.
class EditSharedAssignmentSheet extends StatefulWidget {
  final SharedAssignment assignment;
  const EditSharedAssignmentSheet({super.key, required this.assignment});

  @override
  State<EditSharedAssignmentSheet> createState() => _EditSharedAssignmentSheetState();
}

class _EditSharedAssignmentSheetState extends State<EditSharedAssignmentSheet> {
  late AssignmentType type = widget.assignment.type;
  late final titleController = TextEditingController(text: widget.assignment.title);
  late final contentController = TextEditingController(text: widget.assignment.content);
  late DateTime dueDate = widget.assignment.dueDate.toLocal().dateOnly();

  bool isSaving = false;
  String? error;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (type == AssignmentType.test && title.isEmpty) return setState(() => error = "Donnez un titre au test.");
    if (type == AssignmentType.assignment && content.isEmpty) return setState(() => error = "Écrivez ce qu'il faut faire.");

    setState(() {
      isSaving = true;
      error = null;
    });
    final response = await NetworkService().post("/shared/assignments/edit", {
      "ID": widget.assignment.id,
      "Title": title.isEmpty ? null : title,
      "Content": content.isEmpty && type == AssignmentType.leave ? "Congé" : content,
      "DueDate": dueDate.toUtc().toIso8601String(),
      "Type": type.name,
    });
    if (!mounted) return;
    setState(() => isSaving = false);

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      setState(
        () => error = response.statusCode == 403
            ? "Seuls son auteur, le délégué et le vice-délégué de la classe peuvent modifier ce devoir."
            : response.statusCode == 404
            ? "Ce devoir n'existe plus : il a peut-être été supprimé."
            : AppStrings.errorFor(response),
      );
    }
  }

  void pickDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CustomDatePicker(initialDate: dueDate, onDateSelected: (date) => setState(() => dueDate = date.dateOnly())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ModalPopup(
        topBar: TopBar.form(
          context,
          title: "Devoir partagé",
          trailing: isSaving ? const GymnaseLoader(size: 22) : Button.icon(context, icon: AppIcons.done, onTap: save),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s,
          children: [
            SegmentedControl<AssignmentType>(
              defaultIndex: AssignmentType.values.indexOf(type),
              options: const {"Devoir": AssignmentType.assignment, "Test": AssignmentType.test, "Congé": AssignmentType.leave},
              onTap: (value) => setState(() => type = value),
            ),
            if (type == AssignmentType.test) Field(controller: titleController, placeholder: "Titre du test"),
            Field(
              controller: contentController,
              placeholder: type == AssignmentType.test ? "Chapitres, pages, remarques… (facultatif)" : "Ce qu'il faut faire…",
              minLines: 2,
              maxLines: 6,
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
              minimumSize: Size.zero,
              color: AppColors.tertiaryBackground.adaptTo(context),
              borderRadius: BorderRadius.circular(AppRadius.m),
              onPressed: pickDate,
              child: Row(
                spacing: AppSpacing.s,
                children: [
                  AppIcon(icon: AppIcons.date, size: 18, color: AppColors.secondaryText.adaptTo(context)),
                  Expanded(child: Text("Pour ${formatDate(dueDate, includeArticle: true)}", style: AppStyles.primaryText(context))),
                  AppIcon(icon: AppIcons.chevronRight, size: 16, color: AppColors.quaternaryText.adaptTo(context)),
                ],
              ),
            ),
            if (error != null) Text(error!, style: AppStyles.error(context)),
          ],
        ),
      ),
    );
  }
}
