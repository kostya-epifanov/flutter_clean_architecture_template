import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/common/domain/repositories/connectivity_repository.dart';
import 'package:flutter_clean_template/features/common/domain/usecases/listen_connectivity_usecase.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/repositories/random_int_repository.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockConnectivityDataSource extends Mock implements IConnectivityDataSource {}

class MockConnectivityRepository extends Mock implements IConnectivityRepository {}

class MockRandomIntLocalDataSource extends Mock implements IRandomIntLocalDataSource {}

class MockRandomIntRemoteDataSource extends Mock implements IRandomIntRemoteDataSource {}

class MockRandomIntRepository extends Mock implements IRandomIntRepository {}

class MockListenConnectivityUseCase extends Mock implements ListenConnectivityUseCase {}

class MockGetRandomIntUseCase extends Mock implements GetRandomIntUseCase {}
