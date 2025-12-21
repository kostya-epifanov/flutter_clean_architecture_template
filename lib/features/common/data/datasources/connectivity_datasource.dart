import 'package:connectivity_plus/connectivity_plus.dart';

abstract class IConnectivityDataSource {
  Future<bool> isConnected();
  Stream<ConnectivityResult> connectivity$();
}

class ConnectivityDataSource implements IConnectivityDataSource {
  final Connectivity _connectivity;

  const ConnectivityDataSource(this._connectivity);

  @override
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Stream<ConnectivityResult> connectivity$() {
    return _connectivity.onConnectivityChanged.map((results) {
      // Return the first non-none result, or none if all are none
      return results.firstWhere(
        (result) => result != ConnectivityResult.none,
        orElse: () => ConnectivityResult.none,
      );
    });
  }
}