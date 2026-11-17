import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';

abstract interface class ConnectivityRepository {
  Future<NetworkStatus> currentStatus();

  /// Emits the current status first, then every change.
  Stream<NetworkStatus> watchStatus();
}
