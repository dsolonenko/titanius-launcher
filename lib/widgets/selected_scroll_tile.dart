import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SelectedScrollTile extends HookWidget {
  final bool isSelected;
  final Widget child;
  final double alignment;

  const SelectedScrollTile({
    super.key,
    required this.isSelected,
    required this.child,
    this.alignment = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      if (isSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Scrollable.ensureVisible(
              context,
              alignment: alignment,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
            );
          }
        });
      }
      return null;
    }, [isSelected]);

    return child;
  }
}
