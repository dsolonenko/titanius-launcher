import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectorWidget extends HookConsumerWidget {
  final String text;
  const SelectorWidget({required this.text, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_left, size: 40),
        Text(text),
        const Icon(Icons.arrow_right, size: 40),
      ],
    );
  }
}
