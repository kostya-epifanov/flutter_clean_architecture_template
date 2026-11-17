import 'package:clean_architecture_demo/core/theme/app_theme.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/ui/random_int_viewer_screen.dart';
import 'package:clean_architecture_demo/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Number',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => getIt<RandomIntViewerCubit>()..start(),
        child: const RandomIntViewerScreen(),
      ),
    );
  }
}
