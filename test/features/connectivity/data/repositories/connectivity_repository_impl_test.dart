import 'dart:async';

import 'package:clean_architecture_demo/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityRepositoryImpl repository;

  setUp(() {
    connectivity = MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => changes.stream);
    repository = ConnectivityRepositoryImpl(connectivity);
  });

  // Not awaited: close() on a never-listened controller only completes once listened to.
  tearDown(() => unawaited(changes.close()));

  void givenCurrent(List<ConnectivityResult> results) {
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => results);
  }

  group('currentStatus', () {
    final cases = <List<ConnectivityResult>, NetworkStatus>{
      [ConnectivityResult.wifi]: NetworkStatus.connected,
      [ConnectivityResult.mobile]: NetworkStatus.connected,
      [ConnectivityResult.ethernet]: NetworkStatus.connected,
      [ConnectivityResult.vpn]: NetworkStatus.connected,
      [ConnectivityResult.none, ConnectivityResult.vpn]: NetworkStatus.connected,
      [ConnectivityResult.none]: NetworkStatus.disconnected,
      []: NetworkStatus.disconnected,
    };

    for (final MapEntry(key: results, value: expected) in cases.entries) {
      test('${results.map((r) => r.name).toList()} -> ${expected.name}', () async {
        givenCurrent(results);

        expect(await repository.currentStatus(), expected);
      });
    }
  });

  group('watchStatus', () {
    test('emits the current status first, then changes', () async {
      givenCurrent([ConnectivityResult.none]);

      final statuses = repository.watchStatus();
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

      final statuses = repository.watchStatus();
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
