import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_clean_template/core/di/locator.dart';

/// Base [State] that resolves its cubit from the service locator and
/// provides it to the subtree, rebuilding on every state change.
abstract class InjectableState<T extends StatefulWidget, G extends BlocBase<S>, S>
    extends State<T> {
  @protected
  final G cubit = locator.get<G>();

  Widget builder(BuildContext context, S state);

  void listener(BuildContext context, S state) {}

  bool buildWhen(S previous, S current) => true;

  bool listenWhen(S previous, S current) => true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<G>(
      create: (_) => cubit,
      lazy: false,
      child: BlocConsumer<G, S>(
        buildWhen: buildWhen,
        listenWhen: listenWhen,
        builder: builder,
        listener: listener,
      ),
    );
  }
}
