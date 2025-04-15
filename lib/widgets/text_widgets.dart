import 'package:flutter/material.dart';

class TextWidgets {
  // OpenSans Regular
  static Text mainRegular({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16.0,
    double lineHeight = 1.5,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style: textStyle ??
          TextStyle(
            height: lineHeight,
            fontSize: fontSize,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.normal, // Regular weight
            fontFamily: 'NationalPark',
          ),
    );
  }

  // OpenSans SemiBold
  static Text mainSemiBold(
      {required String title,
      TextStyle? textStyle,
      Color? color,
      TextAlign textAlign = TextAlign.center,
      double fontSize = 16.0,
      double letterSpace = 1.0,
      TextDecoration textDecoration = TextDecoration.none}) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style: textStyle ??
          TextStyle(
            fontSize: fontSize,
            letterSpacing: letterSpace,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.w600, // SemiBold weight
            fontFamily: 'NationalPark',
            decoration: textDecoration,
          ),
    );
  }

  // OpenSans Bold
  static Text mainBold({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style: textStyle ??
          TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.bold, // Bold weight
            fontFamily: 'NationalPark',
          ),
    );
  }

  // OpenSans Italic
  static Text mainItalic({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style: textStyle ??
          TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black87,
            fontStyle: FontStyle.italic, // Italic style
            fontFamily: 'NationalPark',
          ),
    );
  }
}
