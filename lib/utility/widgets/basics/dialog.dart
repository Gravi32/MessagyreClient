import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
import 'package:messagyre_client/utility/workarounds/constrained_aspect_ratio.dart';

class Dialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Map<String, void Function()>? options;
  final Widget? field;
  final Axis optionsDirection;
  final bool isDestructive;
  final bool obscureText;

  const Dialog({
    super.key,
    this.options,
    this.title,
    this.content,
    this.field,
    this.optionsDirection = .vertical,
    this.isDestructive = false,
    this.obscureText = false,
  });

  factory Dialog.networkError(Response apiResponse) {
    return Dialog(
      title: "Erreur ${apiResponse.statusCode}!",
      content: "Une erreur est survenue ! Veuillez reéssayer.\n\n${apiResponse.body}",
      options: {"Fermer": () {}},
    );
  }

  factory Dialog.error(Object e) {
    return Dialog(title: "Oups !", content: "Une erreur est survenue :\n\n\"${e.toString()}\"", options: {"Fermer": () {}});
  }

  factory Dialog.confirm({String? content, void Function()? onConfirm, bool isDestructive = false}) {
    return Dialog(
      title: "Confirmer l'action",
      content: content,
      options: {"Annuler": () {}, "Confirmer": () => onConfirm?.call()},
      optionsDirection: .horizontal,
      isDestructive: isDestructive,
    );
  }

  factory Dialog.entry({
    String? title,
    String placeholder = "Valeur",
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isDestructive = false,
    int? maxLines,
    void Function()? onConfirm,
  }) {
    return Dialog(
      title: title,
      field: Field(keyboardType: keyboardType, controller: controller, placeholder: placeholder, maxLines: maxLines, isPassword: obscureText),
      options: {"Annuler": () {}, "Confirmer": () => onConfirm?.call()},
      optionsDirection: .horizontal,
      isDestructive: isDestructive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: .all(40),
        padding: .all(16).add(.only(top: 8)),
        decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(40)),
        child: Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            if (title != null) Text(title!, style: AppStyles.header(context)),

            if ((content ?? field) != null)
              ConstrainedAspectRatio(
                maxAspectRatio: 1,
                child: content == null
                    ? Padding(padding: .only(top: 8), child: field!)
                    : Padding(
                        padding: .symmetric(horizontal: 10),
                        child: SingleChildScrollView(
                          // Content
                          child: CustomText(
                            content!.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w400, height: 1.5),
                          ),
                        ),
                      ),
              ),

            const SizedBox(),

            Flex(
              direction: optionsDirection,
              spacing: 8,
              children: (options ?? {"OK": () => {}}).entries.map((option) {
                Widget button = Button(
                  text: option.key,
                  transparent: true,
                  color: option.key == "Annuler" ? AppColors.secondaryButton.adaptTo(context) : (isDestructive ? AppColors.red : null),
                  padding: .symmetric(vertical: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    option.value();
                  },
                );

                return optionsDirection == Axis.horizontal ? Expanded(child: button) : button;
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
