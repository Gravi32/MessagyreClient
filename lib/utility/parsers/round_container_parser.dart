import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class StacRoundContainerParser extends StacParser<StacRoundContainerModel> {
  @override
  String get type => 'round_container';

  @override
  StacRoundContainerModel getModel(Map<String, dynamic> json) {
    return StacRoundContainerModel.fromJson(json);
  }

  @override
  Widget parse(BuildContext context, StacRoundContainerModel model) {
    return RoundContainer(
      width: model.width ?? double.infinity,
      color: model.color != null ? AppColors.fromName(model.color) : null,
      child: Stac.fromJson(model.child, context) ?? const SizedBox(),
    );
  }
}

class StacRoundContainerModel {
  final Map<String, dynamic>? child;
  final double? width;
  final String? color;

  StacRoundContainerModel({this.child, this.width, this.color});

  factory StacRoundContainerModel.fromJson(Map<String, dynamic> json) {
    return StacRoundContainerModel(child: json['child'], width: (json['width'] as num?)?.toDouble(), color: json['color']);
  }
}
