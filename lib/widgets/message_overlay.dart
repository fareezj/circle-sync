import 'dart:async';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageOverlay extends ConsumerStatefulWidget {
  final ProviderListenable<String?> messageProvider;
  final MessageType messageType;
  final Duration displayDuration;
  final EdgeInsets padding;

  const MessageOverlay({
    super.key,
    required this.messageProvider,
    required this.messageType,
    this.displayDuration = const Duration(seconds: 3),
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  ConsumerState<MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends ConsumerState<MessageOverlay> {
  double _opacity = 0.0;
  Timer? _timer;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Check initial state of the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialMessage = ref.read(widget.messageProvider);
      if (initialMessage != null && initialMessage.isNotEmpty) {
        setState(() {
          _message = initialMessage;
          _opacity = 1.0;
        });
        _startHideTimer();
      }
    });
  }

  void _startHideTimer() {
    _timer?.cancel();
    _timer = Timer(widget.displayDuration, () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });
        ref.read(globalMessageNotifier.notifier).clearMessage();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for updates from the provider
    ref.listen<String?>(widget.messageProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        setState(() {
          _message = next;
          _opacity = 1.0;
        });
        _startHideTimer();
      }
    });

    if (_message == null || _message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: widget.padding,
          child: GlobalMessage(
            title: _message!,
            messageType: widget.messageType,
          ),
        ),
      ),
    );
  }
}
