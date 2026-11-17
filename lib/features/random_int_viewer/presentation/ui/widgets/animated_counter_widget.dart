import 'package:material_ui/material_ui.dart';

class AnimatedCounterWidget extends StatefulWidget {
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
  AnimatedCounterWidgetState createState() => AnimatedCounterWidgetState();
}

class AnimatedCounterWidgetState extends State<AnimatedCounterWidget>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  int start = 0;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      start = oldWidget.target;
      _initAnimation();
    }
  }

  void _initAnimation() {
    _controller?.dispose();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: start.toDouble(),
      end: widget.target.toDouble(),
    ).animate(_controller!)
      ..addListener(() => setState(() {}));
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _animation!.value.toStringAsFixed(0),
      style: widget.textStyle,
    );
  }
}
