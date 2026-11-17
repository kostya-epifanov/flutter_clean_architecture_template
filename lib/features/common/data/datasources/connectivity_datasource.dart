import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';

abstract class IConnectivityDataSource {
  Future<bool> isConnected();

  /// Emits the current status first, then every change.
  Stream<NetworkStatus> networkStatus$();
}

class ConnectivityDataSource implements IConnectivityDataSource {
  final Connectivity _connectivity;

  const ConnectivityDataSource(this._connectivity);

  @override
  Future<bool> isConnected() async {
    return _toNetworkStatus(await _connectivity.checkConnectivity()) ==
        NetworkStatus.connected;
  }

  @override
  Stream<NetworkStatus> networkStatus$() {
    return _currentThenChanges().map(_toNetworkStatus).distinct();
  }

  Stream<List<ConnectivityResult>> _currentThenChanges() async* {
    yield await _connectivity.checkConnectivity();
    yield* _connectivity.onConnectivityChanged;
  }

  /// Connected when at least one interface (wifi, ethernet, vpn, ...) is up.
  static NetworkStatus _toNetworkStatus(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none)
        ? NetworkStatus.connected
        : NetworkStatus.disconnected;
  }
}
