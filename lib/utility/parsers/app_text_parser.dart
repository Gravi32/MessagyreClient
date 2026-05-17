import 'package:flutter/widgets.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:stac/stac.dart';
import 'package:messagyre_client/configuration/app_styles.dart';

class StacAppTextParser extends StacParser<StacAppTextModel> {
  @override
  String get type => 'app_text';

  @override
  StacAppTextModel getModel(Map<String, dynamic> json) {
    return StacAppTextModel.fromJson(json);
  }

  @override
  Widget parse(BuildContext context, StacAppTextModel model) {
    TextStyle style;

    switch (model.style) {
      case 'header':
        style = AppStyles.header(context);
        break;
      case 'secondaryHeader':
        style = AppStyles.secondaryHeader(context);
        break;
      case 'secondaryText':
        style = AppStyles.secondaryText(context);
        break;
      case 'tertiaryText':
        style = AppStyles.tertiaryText(context);
        break;
      case 'footer':
        style = AppStyles.footer(context);
        break;
      case 'error':
        style = AppStyles.error(context);
        break;
      case 'primaryText':
      default:
        style = AppStyles.primaryText(context);
        break;
    }

    return Text(
      model.data,
      style: style.copyWith(color: model.color != null ? AppColors.fromName(model.color) : null, fontSize: model.fontSize),
      textAlign: model.textAlign,
    );
  }
}

class StacAppTextModel {
  final String data;
  final String? style;
  final String? color;
  final TextAlign? textAlign;
  final double? fontSize;

  StacAppTextModel({required this.data, this.style, this.textAlign, this.color, this.fontSize});

  factory StacAppTextModel.fromJson(Map<String, dynamic> json) {
    return StacAppTextModel(
      data: json['data'] ?? '',
      style: json['style'],
      textAlign: TextAlign.values.firstWhere((e) => e.name == json['textAlign'], orElse: () => TextAlign.start),
      color: json['color'],
      fontSize: (json['fontSize'] as num?)?.toDouble(),
    );
  }
}
