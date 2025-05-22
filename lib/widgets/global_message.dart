import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum MessageType { info, failed }

class GlobalMessage extends StatelessWidget {
  final String title;
  final MessageType messageType;
  const GlobalMessage(
      {super.key, required this.messageType, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          color: messageType == MessageType.info
              ? AppColors.backgroundSuccess
              : AppColors.backgroundError,
          borderRadius: BorderRadius.circular(8.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outlined,
            color: messageType == MessageType.info
                ? AppColors.successGreen
                : AppColors.errorRed,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontFamily: 'Montserrat',
                      fontSize: 14.0,
                    ),
                  ),
                  if (title.contains('2090'))
                    TextSpan(
                      text: '[Back to onboarding page]',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontFamily: 'Montserrat',
                        fontSize: 14.0,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context)
                              .pushReplacementNamed('/onboarding');
                        },
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
