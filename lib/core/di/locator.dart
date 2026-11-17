import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/core/network/http/http_client.dart';
import 'package:flutter_clean_template/core/network/http/http_interceptor.dart';
import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/common/data/repositories/connectivity_repository.dart';
import 'package:flutter_clean_template/features/common/domain/repositories/connectivity_repository.dart';
import 'package:flutter_clean_template/features/common/domain/usecases/listen_connectivity_usecase.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/repositories/random_int_repository.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/repositories/random_int_repository.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final GetIt locator = GetIt.instance;

/// Registers all app dependencies. Must be called once before [runApp].
void setupLocator() {
  _setupServices();
  _setupDataSources();
  _setupRepositories();
  _setupUseCases();
  _setupCubits();
}

void _setupServices() {
  locator.registerLazySingleton(() => Logger());
  locator.registerLazySingleton(() => Connectivity());
  locator.registerLazySingleton(() => HttpInterceptor(locator()));
  locator.registerLazySingleton(() => HttpClient(locator()));
}

void _setupDataSources() {
  locator.registerLazySingleton<IConnectivityDataSource>(() => ConnectivityDataSource(locator()));
  locator.registerLazySingleton<IRandomIntRemoteDataSource>(
    () => RandomIntRemoteDataSource(locator()),
  );
  locator.registerLazySingleton<IRandomIntLocalDataSource>(() => RandomIntLocalDataSource());
}

void _setupRepositories() {
  locator.registerLazySingleton<IConnectivityRepository>(() => ConnectivityRepository(locator()));
  locator.registerLazySingleton<IRandomIntRepository>(
    () => RandomIntRepository(locator(), locator(), locator()),
  );
}

void _setupUseCases() {
  locator.registerLazySingleton(() => ListenConnectivityUseCase(locator()));
  locator.registerLazySingleton(() => GetRandomIntUseCase(locator()));
}

void _setupCubits() {
  locator.registerFactory(() => RandomIntViewerCubit(locator(), locator()));
}
