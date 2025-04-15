import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CirclesPage extends ConsumerStatefulWidget {
  const CirclesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CirclesPageState();
}

class _CirclesPageState extends ConsumerState<CirclesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextWidgets.mainBold(title: 'Your Circles', fontSize: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
