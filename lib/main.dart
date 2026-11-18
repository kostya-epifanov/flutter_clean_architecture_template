import 'dart:developer';

import 'package:clean_architecture_demo/app.dart';
import 'package:clean_architecture_demo/core/config/app_config.dart';
import 'package:clean_architecture_demo/core/logging/app_bloc_observer.dart';
import 'package:clean_architecture_demo/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final config = AppConfig.fromDartDefines();
  if (config.enableLogging) log('$config', name: 'config');

  Bloc.observer = const AppBlocObserver();
  configureDependencies(config);
  runApp(const App());
}
