import 'package:clean_architecture_demo/core/network/network_exception.dart';
import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/repositories/random_int_repository_impl.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockConnectivityRepository connectivity;
  late MockRandomIntRemoteDataSource remote;
  late MockRandomIntLocalDataSource local;
  late RandomIntRepositoryImpl repository;

  setUp(() {
    connectivity = MockConnectivityRepository();
    remote = MockRandomIntRemoteDataSource();
    local = MockRandomIntLocalDataSource();
    repository = RandomIntRepositoryImpl(connectivity, remote, local);

    when(() => local.getRandomInt()).thenReturn(1);
    when(() => remote.getRandomInt()).thenAnswer((_) async => 99);
  });

  void givenNetwork(NetworkStatus status) {
    when(() => connectivity.currentStatus()).thenAnswer((_) async => status);
  }

  group('RandomIntRepositoryImpl', () {
    test('uses the API when online', () async {
      givenNetwork(NetworkStatus.connected);

      expect(
        await repository.getRandomInt(),
        const Success<RandomInt, RandomIntFailure>(RandomInt.remote(99)),
      );
      verifyNever(() => local.getRandomInt());
    });

    test('generates the number locally when offline, without calling the API', () async {
      givenNetwork(NetworkStatus.disconnected);

      expect(
        await repository.getRandomInt(),
        const Success<RandomInt, RandomIntFailure>(RandomInt.device(1)),
      );
      verifyNever(() => remote.getRandomInt());
    });

    test('falls back to a local number when the host is unreachable despite a network', () async {
      givenNetwork(NetworkStatus.connected);
      when(() => remote.getRandomInt()).thenThrow(const HostUnreachableException());

      expect(
        await repository.getRandomInt(),
        const Success<RandomInt, RandomIntFailure>(RandomInt.device(1)),
      );
    });

    group('reports a server that answers badly instead of masking it', () {
      final cases = <NetworkException, RandomIntFailure>{
        const RequestTimeoutException(): RandomIntFailure.timeout,
        const ServerException(503): RandomIntFailure.serverError,
        const ParseException(): RandomIntFailure.invalidResponse,
        const UnknownNetworkException(): RandomIntFailure.unknown,
      };

      for (final MapEntry(key: exception, value: failure) in cases.entries) {
        test('$exception -> ${failure.name}', () async {
          givenNetwork(NetworkStatus.connected);
          when(() => remote.getRandomInt()).thenThrow(exception);

          expect(await repository.getRandomInt(), Failure<RandomInt, RandomIntFailure>(failure));
          verifyNever(() => local.getRandomInt());
        });
      }
    });

    test('lets programming errors through', () async {
      givenNetwork(NetworkStatus.connected);
      when(() => remote.getRandomInt()).thenThrow(StateError('bug'));

      await expectLater(repository.getRandomInt(), throwsStateError);
    });
  });
}
