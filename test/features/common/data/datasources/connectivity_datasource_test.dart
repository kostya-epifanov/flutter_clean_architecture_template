import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_clean_template/features/common/data/datasources/connectivity_datasource.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityDataSource dataSource;

  setUp(() {
    connectivity = MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => changes.stream);
    dataSource = ConnectivityDataSource(connectivity);
  });

  // Not awaited: close() on a never-listened controller only completes once listened to.
  tearDown(() => unawaited(changes.close()));

  void givenCurrent(List<ConnectivityResult> results) {
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => results);
  }

  group('isConnected', () {
    final cases = <List<ConnectivityResult>, bool>{
      [ConnectivityResult.wifi]: true,
      [ConnectivityResult.mobile]: true,
      [ConnectivityResult.ethernet]: true,
      [ConnectivityResult.vpn]: true,
      [ConnectivityResult.none, ConnectivityResult.vpn]: true,
      [ConnectivityResult.none]: false,
      []: false,
    };

    for (final MapEntry(key: results, value: expected) in cases.entries) {
      test('${results.map((r) => r.name).toList()} -> $expected', () async {
        givenCurrent(results);

        expect(await dataSource.isConnected(), expected);
      });
    }
  });

  group('networkStatus\$', () {
    test('emits the current status first, then changes', () async {
      givenCurrent([ConnectivityResult.none]);

      final statuses = dataSource.networkStatus$();
      changes
        ..add([ConnectivityResult.wifi])
        ..add([ConnectivityResult.none]);
      unawaited(changes.close());

      await expectLater(
        statuses,
        emitsInOrder([
          NetworkStatus.disconnected,
          NetworkStatus.connected,
          NetworkStatus.disconnected,
          emitsDone,
        ]),
      );
    });

    test('collapses consecutive results that map to the same status', () async {
      givenCurrent([ConnectivityResult.wifi]);

      final statuses = dataSource.networkStatus$();
      changes
        ..add([ConnectivityResult.ethernet])
        ..add([ConnectivityResult.wifi, ConnectivityResult.vpn])
        ..add([ConnectivityResult.none])
        ..add([ConnectivityResult.none]);
      unawaited(changes.close());

      await expectLater(
        statuses,
        emitsInOrder([NetworkStatus.connected, NetworkStatus.disconnected, emitsDone]),
      );
    });
  });
}
