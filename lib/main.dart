import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print configuration for debugging (only in dev/staging)
  AppConfig.printConfig();

  runApp(const App());
}
