import 'package:flutter/material.dart';
import 'package:flutter_clean_template/core/network/http/request_status.dart';
import 'package:flutter_clean_template/core/ui/dependent_stateless_widget.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';

class GetRandomNumberButton
    extends DependentStatelessWidget<RandomIntViewerCubit, RandomIntViewerState> {
  const GetRandomNumberButton({super.key});

  @override
  Widget builder(
    BuildContext context,
    RandomIntViewerCubit cubit,
    RandomIntViewerState state,
  ) {
    return TextButton(
      onPressed: cubit.onTapGetRandomNumber,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GET RANDOM NUMBER',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 4),
          _buildStatusWidget(state),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(RandomIntViewerState state) {
    return switch (state.requestStatus) {
      InProgress() => Container(
          width: 23,
          height: 16,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
      Completed() => Text(
          '[${state.timerCounter}]',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      NotStarted() || Failed() || Cancelled() => const SizedBox.shrink(),
    };
  }
}
