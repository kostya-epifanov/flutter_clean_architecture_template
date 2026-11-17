import 'package:flutter/services.dart';
import 'package:flutter_clean_template/core/ui/injectable_state.dart';
import 'package:flutter_clean_template/core/ui/request_status.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/animated_counter_widget.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/connectivity_label.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/get_random_number_button.dart';
import 'package:material_ui/material_ui.dart';

class RandomIntViewerScreen extends StatefulWidget {
  const RandomIntViewerScreen({super.key});

  @override
  State<RandomIntViewerScreen> createState() => _RandomIntViewerScreenState();
}

class _RandomIntViewerScreenState
    extends InjectableState<RandomIntViewerScreen, RandomIntViewerCubit, RandomIntViewerState> {
  @override
  bool listenWhen(RandomIntViewerState previous, RandomIntViewerState current) =>
      previous.requestStatus != current.requestStatus &&
      current.requestStatus == RequestStatus.failure;

  @override
  void listener(BuildContext context, RandomIntViewerState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not get a new number. Will retry shortly.')),
    );
  }

  @override
  Widget builder(BuildContext context, RandomIntViewerState state) {
    // The screen has no AppBar to pick a status bar style, and the default
    // dark icons are unreadable on the dark background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _buildScaffold(state),
    );
  }

  Widget _buildScaffold(RandomIntViewerState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Center(child: _buildNumberWidget(state)),
      // In the bottom bar slot the row stays above the system gesture area
      // (the app draws edge-to-edge on Android 15+), and SnackBars appear
      // above it instead of covering the status and the button.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // A Wrap rather than a Row: with large system fonts the button
          // moves to a second line instead of overflowing.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [ConnectivityLabel(state.networkStatus), const GetRandomNumberButton()],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberWidget(RandomIntViewerState state) {
    return AnimatedCounterWidget(
      target: state.number,
      duration: const Duration(milliseconds: 600),
      textStyle: const TextStyle(color: Colors.white, fontSize: 96),
    );
  }
}
