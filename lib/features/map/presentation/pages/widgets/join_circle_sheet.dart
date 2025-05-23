import 'package:circle_sync/features/circles/presentation/providers/circle_providers.dart';
import 'package:circle_sync/features/map/presentation/routers/circle_navigation_router.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinCircleSheet extends ConsumerStatefulWidget {
  final JoinCircleArgs args;
  const JoinCircleSheet({super.key, required this.args});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _JoinCircleSheetState();
}

class _JoinCircleSheetState extends ConsumerState<JoinCircleSheet> {
  // six controllers & focus nodes
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _controllers[i].addListener(() {
        final text = _controllers[i].text;
        if (text.length == 1 && i < 5) {
          _focusNodes[i + 1].requestFocus();
        }
        // if user deletes, focus stays
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  Widget _buildBox(int i) {
    return Container(
      width: 48,
      height: 60,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, letterSpacing: 2),
        maxLength: 1,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _submit() async {
    final code = _controllers.map((c) => c.text).join();
    await ref.read(circleNotifierProvider.notifier).joinCircle(code, () {
      widget.args.onJoinedCircle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.args.showBack)
            IconButton(
                onPressed: () {
                  circleSheetNavKey.currentState!.pop();
                },
                icon: Icon(Icons.chevron_left)),
          // ── header row ───────────────────────────────────────────
          Center(
            child: Text(
              'Join a Circle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // invisible spacer to balance the close icon
          SizedBox(width: 48),

          SizedBox(height: 24),

          // ── title ────────────────────────────────────────────────
          Text(
            'Enter the invite code',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 24),

          // ── code boxes (3 + dash + 3) ────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 4; i++) ...[
              _buildBox(i),
            ],
          ]),

          SizedBox(height: 16),

          // ── helper text ───────────────────────────────────────────
          Text(
            'Ask the Circle creator for their code',
            style: TextStyle(color: Colors.grey[600]),
          ),

          SizedBox(height: 24),

          // ── submit button ─────────────────────────────────────────
          ConfirmButton(onClick: () => _submit(), title: 'Submit')
        ]),
      ),
    );
  }
}
