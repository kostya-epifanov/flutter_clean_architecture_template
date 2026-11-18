import 'package:clean_architecture_demo/core/ui/request_status.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/ui/widgets/animated_counter.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/ui/widgets/connectivity_label.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/ui/widgets/get_random_number_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Expects a [RandomIntViewerCubit] above it in the tree.
class RandomIntViewerScreen extends StatefulWidget {
  const RandomIntViewerScreen({super.key});

  @override
  State<RandomIntViewerScreen> createState() => _RandomIntViewerScreenState();
}

class _RandomIntViewerScreenState extends State<RandomIntViewerScreen> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<RandomIntViewerCubit>();
    _lifecycleListener = AppLifecycleListener(onHide: cubit.pause, onShow: cubit.resume);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Without an AppBar nothing picks the status bar style, and dark icons vanish on this background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<RandomIntViewerCubit, RandomIntViewerState>(
        listenWhen: (previous, current) =>
            previous.status != current.status && current.status == RequestStatus.failure,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(_failureMessage(state.failure!)))),
        child: const Scaffold(
          body: Center(child: _Number()),
          // The bottom bar slot keeps the row above the gesture area and below SnackBars.
          bottomNavigationBar: _BottomBar(),
        ),
      ),
    );
  }

  static String _failureMessage(RandomIntFailure failure) => switch (failure) {
    RandomIntFailure.serverError => 'The server returned an error. Will retry shortly.',
    RandomIntFailure.timeout => 'The server is not responding. Will retry shortly.',
    RandomIntFailure.invalidResponse => 'The server sent an unexpected answer. Will retry shortly.',
    RandomIntFailure.unknown => 'Could not get a new number. Will retry shortly.',
  };
}

class _Number extends StatelessWidget {
  const _Number();

  @override
  Widget build(BuildContext context) {
    final number = context.select((RandomIntViewerCubit cubit) => cubit.state.number);
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.displayLarge!.copyWith(fontSize: 96);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (number == null)
            Text('–', style: style, semanticsLabel: 'No number yet')
          else
            // Announces the final number once, not every frame of the counting animation.
            Semantics(
              liveRegion: true,
              label: number.isFromDevice
                  ? '${number.value}, generated on the device'
                  : '${number.value}',
              excludeSemantics: true,
              child: AnimatedCounter(
                value: number.value,
                duration: const Duration(milliseconds: 600),
                style: style,
              ),
            ),
          // Keeps its space while hidden, so the number does not jump when it appears. The
          // number's own label already tells screen readers where it came from.
          Visibility(
            visible: number?.isFromDevice ?? false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: ExcludeSemantics(
              child: Text(
                'Offline: generated on the device',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final networkStatus = context.select((RandomIntViewerCubit cubit) => cubit.state.networkStatus);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Wraps instead of overflowing at large font sizes.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [ConnectivityLabel(networkStatus), const GetRandomNumberButton()],
        ),
      ),
    );
  }
}
