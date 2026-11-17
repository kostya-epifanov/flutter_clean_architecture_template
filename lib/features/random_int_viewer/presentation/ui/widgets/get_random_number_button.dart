import 'package:clean_architecture_demo/core/ui/request_status.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Loads a new number on tap and shows the seconds until the next automatic refresh.
class GetRandomNumberButton extends StatelessWidget {
  const GetRandomNumberButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RandomIntViewerCubit>();
    final state = cubit.state;
    final isLoading = state.status == RequestStatus.loading;

    return TextButton(
      onPressed: isLoading ? null : cubit.refresh,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(child: Text('GET RANDOM NUMBER', overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          switch (state.status) {
            RequestStatus.loading => const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            RequestStatus.success || RequestStatus.failure => Text('[${state.secondsToRefresh}]'),
            RequestStatus.initial => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}
