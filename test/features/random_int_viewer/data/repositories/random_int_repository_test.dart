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

    test('propagates remote errors instead of silently falling back', () async {
      givenOnline(true);
      when(() => remote.getRandomInt()).thenThrow(const NoInternetException());

      await expectLater(repository.getRandomInt(), throwsA(isA<NoInternetException>()));
      verifyNever(() => local.getRandomInt());
    });
  });
}
