import 'package:flutter/material.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';

enum ResponseTypeEnum { success, error, warning, info }

void showSnackBar(
  BuildContext context,
  String message, {
  ResponseTypeEnum type = ResponseTypeEnum.info,
}) {
  final color = type == ResponseTypeEnum.success
      ? context.churchColors.success
      : type == ResponseTypeEnum.error
      ? context.churchColors.error
      : type == ResponseTypeEnum.warning
      ? context.churchColors.warning
      : context.churchColors.info;

  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
}
