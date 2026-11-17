import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/common/domain/repositories/connectivity_repository.dart';

class ConnectivityRepository implements IConnectivityRepository {
  final IConnectivityDataSource _connectivityDataSource;

  const ConnectivityRepository(this._connectivityDataSource);

  @override
  Stream<ConnectivityResult> connectivity$() {
    return _connectivityDataSource.connectivity$();
  }
}
