import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';

abstract class IConnectivityRepository {
  /// Emits the current status first, then every change.
  Stream<NetworkStatus> networkStatus$();
}
