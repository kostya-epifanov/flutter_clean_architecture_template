import 'package:clean_architecture_demo/core/config/app_config.dart';
import 'package:clean_architecture_demo/core/config/environment.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:clean_architecture_demo/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(getIt.reset);

  test('resolves the whole graph down to the cubit', () async {
    configureDependencies(AppConfig.forEnvironment(Environment.production));

    final cubit = getIt<RandomIntViewerCubit>();

    expect(cubit, isA<RandomIntViewerCubit>());
    expect(getIt<RandomIntViewerCubit>(), isNot(same(cubit)), reason: 'one cubit per screen');
    await cubit.close();
  });
}
