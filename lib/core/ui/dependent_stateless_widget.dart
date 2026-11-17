import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DependentStatelessWidget<G extends BlocBase<S>, S> extends StatelessWidget {
  const DependentStatelessWidget({super.key});

  bool buildWhen(S previous, S current) => true;

  bool listenWhen(S previous, S current) => true;

  Widget builder(BuildContext context, G cubit, S state);

  void listener(
    BuildContext context,
    G cubit,
    S state,
  ) {}

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<G>();

    final consumer = BlocConsumer<G, S>(
      buildWhen: buildWhen,
      listenWhen: listenWhen,
      builder: (context, state) => builder(context, cubit, state),
      listener: (context, state) => listener(context, cubit, state),
    );

    return consumer;
  }
}
