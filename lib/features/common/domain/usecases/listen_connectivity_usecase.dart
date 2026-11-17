import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_clean_template/features/common/domain/repositories/connectivity_repository.dart';

class ListenConnectivityUseCase {
  final IConnectivityRepository _connectivityRepository;

  const ListenConnectivityUseCase(this._connectivityRepository);

  Stream<NetworkStatus> call() {
    return _connectivityRepository.networkStatus$();
  }
}
