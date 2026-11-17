import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/repositories/random_int_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockConnectivityDataSource connectivity;
  late MockRandomIntLocalDataSource local;
  late MockRandomIntRemoteDataSource remote;
  late RandomIntRepository repository;

  setUp(() {
    connectivity = MockConnectivityDataSource();
    local = MockRandomIntLocalDataSource();
    remote = MockRandomIntRemoteDataSource();
    repository = RandomIntRepository(connectivity, local, remote);

    when(() => local.getRandomInt()).thenAnswer((_) async => 1);
    when(() => remote.getRandomInt()).thenAnswer((_) async => 99);
  });

  void givenOnline(bool online) {
    when(() => connectivity.isConnected()).thenAnswer((_) async => online);
  }

  group('RandomIntRepository', () {
    test('uses the remote data source when online', () async {
      givenOnline(true);

      expect(await repository.getRandomInt(), 99);
      verifyNever(() => local.getRandomInt());
    });

    test('falls back to the local data source when offline', () async {
      givenOnline(false);

      expect(await repository.getRandomInt(), 1);
      verifyNever(() => remote.getRandomInt());
    });

    test('falls back to local when the API is unreachable despite a reported network', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const NoInternetException());

      expect(await repository.getRandomInt(), 1);
    });

    test('falls back to local when connecting to the API times out', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const ConnectionTimeoutException());

      expect(await repository.getRandomInt(), 1);
    });

    test('propagates a slow server instead of masking it', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const RequestTimeoutException());

      await expectLater(repository.getRandomInt(), throwsA(isA<RequestTimeoutException>()));
      verifyNever(() => local.getRandomInt());
    });

    test('propagates server errors instead of masking them', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const ServerException(503, 'unavailable'));

      await expectLater(repository.getRandomInt(), throwsA(isA<ServerException>()));
      verifyNever(() => local.getRandomInt());
    });

    test('propagates parse errors instead of masking them', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const ParseException());

      await expectLater(repository.getRandomInt(), throwsA(isA<ParseException>()));
      verifyNever(() => local.getRandomInt());
    });
  });
}
