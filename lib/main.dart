import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Print configuration for debugging (only in dev/staging)
  AppConfig.printConfig();

  setupLocator();

  runApp(const App());
}
