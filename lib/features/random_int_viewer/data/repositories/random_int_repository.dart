import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/repositories/random_int_repository.dart';

/// Fetches the number from the remote API when online, and generates it
/// locally when the device is offline or the API cannot be reached.
///
/// Connectivity alone is not trusted: a device can report a network
/// (Wi-Fi without internet, captive portal, VPN/bridge interfaces) and still
/// fail to reach the API. Only "cannot reach the host" falls back; a server
/// that answers with an error, garbage or too slowly is reported as a failure
/// rather than masked with a local number.
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
    if (!await _connectivityDataSource.isConnected()) {
      return _localDataSource.getRandomInt();
    }
    try {
      return await _remoteDataSource.getRandomInt();
    } on NoInternetException {
      return _localDataSource.getRandomInt();
    } on ConnectionTimeoutException {
      return _localDataSource.getRandomInt();
    }
  }
}
