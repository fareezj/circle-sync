import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingIndicator extends ConsumerWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color.fromARGB(87, 41, 40, 40),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.blueBorder,
        ),
      ),
    );
  }
}
