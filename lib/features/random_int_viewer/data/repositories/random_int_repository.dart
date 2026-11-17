import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/repositories/random_int_repository.dart';

/// Fetches the number from the remote API when online,
/// and falls back to a locally generated one otherwise.
class RandomIntRepository implements IRandomIntRepository {
  final IConnectivityDataSource _connectivityDataSource;
  final IRandomIntLocalDataSource _localDataSource;
  final IRandomIntRemoteDataSource _remoteDataSource;

  const RandomIntRepository(
    this._connectivityDataSource,
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<int> getRandomInt() async {
    if (await _connectivityDataSource.isConnected()) {
      return _remoteDataSource.getRandomInt();
    }
    return _localDataSource.getRandomInt();
  }
}
