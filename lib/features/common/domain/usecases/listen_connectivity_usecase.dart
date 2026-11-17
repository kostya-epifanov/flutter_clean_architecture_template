import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/features/common/domain/repositories/connectivity_repository.dart';

class ListenConnectivityUseCase {
  final IConnectivityRepository _connectivityRepository;

  const ListenConnectivityUseCase(this._connectivityRepository);

  Stream<ConnectivityResult> call() {
    return _connectivityRepository.connectivity$();
  }
}
