import 'package:flutter/material.dart';
import 'package:flutter_clean_template/core/di/locator.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/random_int_viewer_screen.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: setupLocator(),
      builder: (BuildContext context, snapshot) {
        return const AppInternal();
      },
    );
  }
}

class AppInternal extends StatelessWidget {
  const AppInternal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      home: const RandomIntViewerScreen(),
      builder: (context, child) {
        if (!isLocatorInitialized) {
          return Container();
        }
        return child ?? Container();
      },
    );
  }
}
