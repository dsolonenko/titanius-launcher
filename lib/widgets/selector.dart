import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titanius/widgets/icons.dart';

class SelectorWidget extends HookConsumerWidget {
  final String text;
  const SelectorWidget({required this.text, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_left, size: toggleSize),
        Text(text),
        const Icon(Icons.arrow_right, size: toggleSize),
      ],
    );
  }
}
