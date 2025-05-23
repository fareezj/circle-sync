// ignore_for_file: must_be_immutable
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputWidget extends StatelessWidget {
  TextEditingController? controller;
  TextInputType? keyboardType;
  FocusNode? focusNode;
  List<TextInputFormatter>? inputFormatters;
  String? fieldTitle;
  String? initialValue;
  String? value;
  bool hasPrefix;
  bool isError;
  String? prefixValue;
  String? errorMessage;
  String? title;
  bool? isMandatory;
  String hintText;
  IconData? suffixIcon;
  bool isPassword;
  bool isObscure;
  VoidCallback? onSuffixIconClicked;
  String? prefixImage;
  VoidCallback? onSetObscure;
  Color borderColor;
  double borderWidth;
  int? maxLength;
  Widget? trailingWidget;
  int? maxLines;
  void Function(String)? onChanged;

  CustomInputWidget({
    super.key,
    this.controller,
    this.fieldTitle,
    this.initialValue,
    this.onChanged,
    this.focusNode,
    this.value,
    this.inputFormatters,
    this.keyboardType,
    this.hasPrefix = false,
    this.prefixValue = '',
    this.prefixImage,
    this.title,
    this.isMandatory,
    this.suffixIcon,
    this.isPassword = false,
    this.isObscure = false,
    this.isError = false,
    this.onSuffixIconClicked,
    this.onSetObscure,
    this.errorMessage,
    this.borderWidth = 1.5,
    this.maxLength,
    this.maxLines,
    this.trailingWidget,
    this.borderColor = AppColors.disabledBlue,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && isMandatory != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                      text: isMandatory! ? ' *' : '',
                      style: const TextStyle(color: Colors.red, fontSize: 20.0),
                      children: [
                        TextSpan(
                          text: '$title',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontFamily: 'Montserrat',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingWidget != null) ...[trailingWidget!],
            ],
          ),
          const SizedBox(height: 8.0),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              if (prefixImage != null) Image.asset(prefixImage!, scale: 4),
              Visibility(
                visible: hasPrefix,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        prefixValue!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                      child: VerticalDivider(
                        color: AppColors.disabledBlue,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  obscureText: isObscure,
                  maxLength: maxLength,
                  maxLines: maxLines ?? 1,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontFamily: 'Montserrat',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    counterText: '',
                    hintStyle: const TextStyle(
                      color: Colors.blueGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    suffixIcon: suffixIcon != null
                        ? GestureDetector(
                            onTap: onSuffixIconClicked,
                            child: Icon(suffixIcon),
                          )
                        : isPassword
                            ? isObscure
                                ? GestureDetector(
                                    onTap: onSetObscure,
                                    child: const Icon(Icons.visibility_rounded),
                                  )
                                : GestureDetector(
                                    onTap: onSetObscure,
                                    child: const Icon(
                                        Icons.visibility_off_rounded),
                                  )
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 5),
          TextWidgets.mainItalic(
            title: errorMessage ?? "",
            color: AppColors.errorRed,
            fontSize: 16.0,
          ),
        ],
      ],
    );
  }
}
