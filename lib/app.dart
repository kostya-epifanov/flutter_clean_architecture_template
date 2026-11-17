import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/random_int_viewer_screen.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RandomIntViewerScreen(),
    );
  }
}
