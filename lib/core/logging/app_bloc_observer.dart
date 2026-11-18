import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs errors that cubits report with `addError`. A crash reporter would hook in here.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} failed', name: 'bloc', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
