import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

Color textColor(BuildContext context) {
  if (NeumorphicTheme.isUsingDark(context)) {
    return Colors.white;
  } else {
    return Colors.black;
  }
}
