import 'package:material_ui/material_ui.dart';

/// Shows [value], counting to each new value from the one currently on screen.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, required this.duration, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      builder: (context, current, _) => Text(current.round().toString(), style: style),
    );
  }
}
