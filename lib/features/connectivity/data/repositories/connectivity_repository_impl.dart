import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final Connectivity _connectivity;

  const ConnectivityRepositoryImpl(this._connectivity);

  @override
  Future<NetworkStatus> currentStatus() async =>
      _toNetworkStatus(await _connectivity.checkConnectivity());

  @override
  Stream<NetworkStatus> watchStatus() => _currentThenChanges().map(_toNetworkStatus).distinct();

  Stream<List<ConnectivityResult>> _currentThenChanges() async* {
    yield await _connectivity.checkConnectivity();
    yield* _connectivity.onConnectivityChanged;
  }

  /// Connected when at least one interface (wifi, mobile, ethernet, vpn, ...) is up.
  static NetworkStatus _toNetworkStatus(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none)
      ? NetworkStatus.connected
      : NetworkStatus.disconnected;
}
