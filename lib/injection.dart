import 'package:clean_architecture_demo/core/config/app_config.dart';
import 'package:clean_architecture_demo/core/network/api_client.dart';
import 'package:clean_architecture_demo/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/usecases/watch_network_status_usecase.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/repositories/random_int_repository_impl.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/repositories/random_int_repository.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Composition root: the only place that knows concrete implementations.
void configureDependencies(AppConfig config) {
  getIt
    // Core
    ..registerLazySingleton(() => ApiClient.fromConfig(config))
    // Connectivity
    ..registerLazySingleton<ConnectivityRepository>(
      () => ConnectivityRepositoryImpl(Connectivity()),
    )
    ..registerLazySingleton(() => WatchNetworkStatusUseCase(getIt()))
    // Random number
    ..registerLazySingleton(() => RandomIntRemoteDataSource(getIt()))
    ..registerLazySingleton(RandomIntLocalDataSource.new)
    ..registerLazySingleton<RandomIntRepository>(
      () => RandomIntRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(() => GetRandomIntUseCase(getIt()))
    ..registerFactory(() => RandomIntViewerCubit(getIt(), getIt()));
}
