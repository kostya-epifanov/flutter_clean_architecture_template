import 'package:flutter_clean_template/features/common/data/repositories/connectivity_repository.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  test('networkStatus\$ forwards the data source stream', () {
    final dataSource = MockConnectivityDataSource();
    when(
      () => dataSource.networkStatus$(),
    ).thenAnswer((_) => Stream.fromIterable([NetworkStatus.connected, NetworkStatus.disconnected]));

    expect(
      ConnectivityRepository(dataSource).networkStatus$(),
      emitsInOrder([NetworkStatus.connected, NetworkStatus.disconnected, emitsDone]),
    );
  });
}
