import 'package:clean_architecture_demo/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/usecases/watch_network_status_usecase.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/repositories/random_int_repository.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockConnectivityRepository extends Mock implements ConnectivityRepository {}

class MockRandomIntLocalDataSource extends Mock implements RandomIntLocalDataSource {}

class MockRandomIntRemoteDataSource extends Mock implements RandomIntRemoteDataSource {}

class MockRandomIntRepository extends Mock implements RandomIntRepository {}

class MockWatchNetworkStatusUseCase extends Mock implements WatchNetworkStatusUseCase {}

class MockGetRandomIntUseCase extends Mock implements GetRandomIntUseCase {}
