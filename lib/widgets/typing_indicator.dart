import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;

  const TypingIndicator({super.key, required this.isTyping});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;

  late AnimationController _dotsAnimation;
  List<Interval> _dotIntervals = [];

  final List<Interval> _dotLoadingIntervals = [
    const Interval(0.0, 0.4),
    const Interval(0.2, 0.6),
    const Interval(0.4, 0.8),
  ];

  @override
  void initState() {
    super.initState();

    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _dotsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _updateDotIntervals();

    _setAppearanceAnimation();
  }

  void _setAppearanceAnimation() {
    if (widget.isTyping) {
      _appearanceController.forward();
    } else {
      _appearanceController.reverse();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTyping != oldWidget.isTyping) {
      _setAppearanceAnimation();
    }
  }

  void _updateDotIntervals() {
    _dotIntervals = _dotLoadingIntervals;
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _dotsAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearanceController,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _indicatorSpaceAnimation,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        final scale =
            1.0 - _dotIntervals[index].transform(_dotsAnimation.value) * 0.4;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 7.0,
            height: 7.0,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        );
      },
    );
  }
}
