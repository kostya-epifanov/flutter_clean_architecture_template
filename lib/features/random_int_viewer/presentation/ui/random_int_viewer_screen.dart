import 'package:material_ui/material_ui.dart';
import 'package:flutter_clean_template/core/ui/injectable_state.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/animated_counter_widget.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/connectivity_label.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/widgets/get_random_number_button.dart';

class RandomIntViewerScreen extends StatefulWidget {
  const RandomIntViewerScreen({super.key});

  @override
  State<RandomIntViewerScreen> createState() => _RandomIntViewerScreenState();
}

class _RandomIntViewerScreenState
    extends InjectableState<RandomIntViewerScreen, RandomIntViewerCubit, RandomIntViewerState> {
  @override
  Widget builder(
    BuildContext context,
    RandomIntViewerState state,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildNumberWidget(state),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ConnectivityLabel(state.connectivityState),
                    const GetRandomNumberButton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberWidget(RandomIntViewerState state) {
    return AnimatedCounterWidget(
      target: state.number,
      duration: const Duration(milliseconds: 600),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 96,
      ),
    );
  }
}
