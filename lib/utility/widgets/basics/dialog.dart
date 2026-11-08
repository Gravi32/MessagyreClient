import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
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

  /// A failed request, explained in words (the server's raw answer only goes to the logs)
  factory Dialog.networkError(Response apiResponse) {
    debugPrint("[Request failed] ${apiResponse.statusCode} ${apiResponse.body}");
    return Dialog(title: AppStrings.errorTitle, content: AppStrings.errorFor(apiResponse), options: {AppStrings.close: () {}});
  }

  factory Dialog.error(Object e) {
    debugPrint("[Error] $e");
    return Dialog(title: AppStrings.errorTitle, content: AppStrings.genericError, options: {AppStrings.close: () {}});
  }

  factory Dialog.confirm({String? content, void Function()? onConfirm, bool isDestructive = false}) {
    return Dialog(
      title: AppStrings.confirmTitle,
      content: content,
      options: {AppStrings.cancel: () {}, AppStrings.confirm: () => onConfirm?.call()},
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
      options: {AppStrings.cancel: () {}, AppStrings.confirm: () => onConfirm?.call()},
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
        padding: .all(16).add(.only(top: 10)),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.xl),
          border: .all(color: AppColors.outline.adaptTo(context)),
          boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: .18), blurRadius: 40, offset: const Offset(0, 12))],
        ),
        child: Column(
          spacing: 12,
          mainAxisSize: .min,
          children: [
            // Title
            if (title != null) Text(title!, textAlign: .center, style: AppStyles.secondaryHeader(context).copyWith(fontSize: 21)),

            if ((content ?? field) != null)
              ConstrainedAspectRatio(
                maxAspectRatio: 1,
                child: content == null
                    ? Padding(padding: .only(top: 8), child: field!)
                    : Padding(
                        padding: .symmetric(horizontal: 10),
                        child: SingleChildScrollView(
                          // Content
                          child: CustomText(content!.trim(), textAlign: .center, style: AppStyles.primaryText(context).copyWith(height: 1.45, color: AppColors.secondaryText.adaptTo(context))),
                        ),
                      ),
              ),

            const SizedBox(),

            Flex(
              direction: optionsDirection,
              spacing: 8,
              children: (options ?? {AppStrings.ok: () => {}}).entries.map((option) {
                Widget button = Button(
                  text: option.key,
                  transparent: true,
                  color: option.key == AppStrings.cancel ? AppColors.tertiaryBackground.adaptTo(context) : (isDestructive ? AppColors.red : null),
                  onTap: () {
                    Navigator.of(context).pop();
                    option.value();
                  },
                );

                return optionsDirection == .horizontal ? Expanded(child: button) : button;
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
