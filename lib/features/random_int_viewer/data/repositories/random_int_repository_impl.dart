import 'package:clean_architecture_demo/core/network/network_exception.dart';
import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/repositories/random_int_repository.dart';

/// Falls back to a local number only when the API host cannot be reached.
///
/// A reported network is not enough (Wi-Fi without internet, captive portal), so a failed
/// connection falls back too. A server that answers with an error, garbage or too slowly is
/// reported instead of masked.
class RandomIntRepositoryImpl implements RandomIntRepository {
  final ConnectivityRepository _connectivity;
  final RandomIntRemoteDataSource _remote;
  final RandomIntLocalDataSource _local;

  const RandomIntRepositoryImpl(this._connectivity, this._remote, this._local);

  @override
  Future<Result<int, RandomIntFailure>> getRandomInt() async {
    if (await _connectivity.currentStatus() == NetworkStatus.disconnected) {
      return Success(_local.getRandomInt());
    }
    try {
      return Success(await _remote.getRandomInt());
    } on NetworkException catch (e) {
      return switch (e) {
        HostUnreachableException() => Success(_local.getRandomInt()),
        RequestTimeoutException() => const Failure(RandomIntFailure.timeout),
        ServerException() => const Failure(RandomIntFailure.serverError),
        ParseException() => const Failure(RandomIntFailure.invalidResponse),
        UnknownNetworkException() => const Failure(RandomIntFailure.unknown),
      };
    }
  }
}
