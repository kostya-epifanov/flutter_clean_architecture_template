import 'package:material_ui/material_ui.dart';

/// Shows [target] as text, counting up or down to each new value.
///
/// When [target] changes mid-animation, counting continues from the value
/// currently on screen instead of jumping back.
class AnimatedCounterWidget extends StatelessWidget {
  final int target;
  final Duration duration;
  final TextStyle textStyle;

  const AnimatedCounterWidget({
    super.key,
    required this.target,
    required this.duration,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: duration,
      builder: (context, value, _) => Text(
        value.round().toString(),
        style: textStyle,
      ),
    );
  }
}
