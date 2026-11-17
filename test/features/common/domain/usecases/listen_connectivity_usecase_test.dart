import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_clean_template/features/common/domain/usecases/listen_connectivity_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  test('call() returns the repository status stream', () {
    final repository = MockConnectivityRepository();
    when(() => repository.networkStatus$())
        .thenAnswer((_) => Stream.value(NetworkStatus.disconnected));

    expect(
      ListenConnectivityUseCase(repository)(),
      emitsInOrder([NetworkStatus.disconnected, emitsDone]),
    );
  });
}
