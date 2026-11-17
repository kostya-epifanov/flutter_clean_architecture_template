import 'package:connectivity_plus/connectivity_plus.dart';

abstract class IConnectivityRepository {
  Stream<ConnectivityResult> connectivity$();
}
