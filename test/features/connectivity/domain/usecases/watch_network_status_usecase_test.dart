import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/usecases/watch_network_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  test('returns the repository status stream', () {
    final repository = MockConnectivityRepository();
    when(repository.watchStatus).thenAnswer((_) => Stream.value(NetworkStatus.disconnected));

    expect(
      WatchNetworkStatusUseCase(repository)(),
      emitsInOrder([NetworkStatus.disconnected, emitsDone]),
    );
  });
}
