import 'package:flutter/material.dart';

import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';

class GamepadPrompt {
  final List<GamepadButton> buttons;
  final String prompt;

  const GamepadPrompt(this.buttons, this.prompt);
}

typedef GamepadPrompts = List<GamepadPrompt>;

class PromptBar extends StatelessWidget {
  final String text;
  final GamepadPrompts navigations;
  final GamepadPrompts actions;
  final Color? backgroundColor;

  const PromptBar({
    super.key,
    this.text = "",
    this.navigations = const [],
    this.actions = const [],
    this.backgroundColor,
  });

  String get _signature {
    final prompts = [...navigations, ...actions];
    return '$text|${prompts.map((p) => '${p.buttons.map((b) => b.name).join(",")}:${p.prompt}').join(';')}';
  }

  @override
  Widget build(BuildContext context) {
    final prompts = [...navigations, ...actions];
    final promptsRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < prompts.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          GamepadPromptWidget(
            buttons: prompts[i].buttons,
            prompt: prompts[i].prompt,
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (text.isNotEmpty) ...[
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          InfiniteMarquee(
            contentKey: _signature,
            child: promptsRow,
          ),
        ],
      ),
    );
  }
}

class InfiniteMarquee extends StatefulWidget {
  final Object contentKey;
  final Widget child;
  final double blankSpace;
  final double velocity;

  const InfiniteMarquee({
    super.key,
    required this.contentKey,
    required this.child,
    this.blankSpace = 36.0,
    this.velocity = 35.0,
  });

  @override
  State<InfiniteMarquee> createState() => _InfiniteMarqueeState();
}

class _InfiniteMarqueeState extends State<InfiniteMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _childKey = GlobalKey();
  double? _contentWidth;
  double _availableWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  void _onAnimationTick() {
    if (!_scrollController.hasClients) return;
    final cycleDistance = (_contentWidth ?? 0) + widget.blankSpace;
    if (cycleDistance <= 0) return;
    final targetOffset = _animationController.value * cycleDistance;
    _scrollController.jumpTo(targetOffset);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animationController.reset();
      _startLoop();
    }
  }

  void _startLoop() {
    if (!mounted) return;
    final overflows = _contentWidth != null && _contentWidth! > _availableWidth;
    if (!overflows) {
      _animationController.stop();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      return;
    }

    final cycleDistance = (_contentWidth ?? 0) + widget.blankSpace;
    final durationMs = (cycleDistance / widget.velocity * 1000).round();
    if (durationMs <= 0) return;

    _animationController.duration = Duration(milliseconds: durationMs);
    _animationController.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant InfiniteMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      _animationController.stop();
      _contentWidth = null;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.removeStatusListener(_onAnimationStatus);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _measureAndStart() {
    if (!mounted) return;
    final renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final width = renderBox.size.width;
      if (_contentWidth != width) {
        setState(() {
          _contentWidth = width;
        });
      }
      if (!_animationController.isAnimating) {
        _startLoop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _availableWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());

        final overflows = _contentWidth != null && _contentWidth! > _availableWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: _availableWidth),
            child: Row(
              mainAxisAlignment:
                  overflows ? MainAxisAlignment.start : MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(
                  key: _childKey,
                  child: widget.child,
                ),
                if (overflows) ...[
                  SizedBox(width: widget.blankSpace),
                  widget.child,
                  SizedBox(width: widget.blankSpace),
                  widget.child,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
