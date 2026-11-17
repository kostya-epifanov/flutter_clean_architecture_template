import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/repositories/connectivity_repository.dart';

class WatchNetworkStatusUseCase {
  final ConnectivityRepository _repository;

  const WatchNetworkStatusUseCase(this._repository);

  Stream<NetworkStatus> call() => _repository.watchStatus();
}
