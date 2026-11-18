import 'package:clean_architecture_demo/core/network/api_client.dart';
import 'package:clean_architecture_demo/core/network/network_exception.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  RandomIntRemoteDataSource buildDataSource(List<FakeResponder> responders) {
    adapter = FakeHttpClientAdapter(responders);
    final client = ApiClient(
      Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter,
      maxRetries: 0,
      maxTimeoutRetries: 0,
      retryDelay: Duration.zero,
    );
    return RandomIntRemoteDataSource(client);
  }

  group('RandomIntRemoteDataSource', () {
    test('requests one plain-text integer in 1..100 from random.org', () async {
      final dataSource = buildDataSource([respond('42\n')]);

      await dataSource.getRandomInt();

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/integers/');
      expect(uri.queryParameters, {
        'num': '1',
        'min': '1',
        'max': '100',
        'col': '1',
        'base': '10',
        'format': 'plain',
      });
    });

    test('parses the plain-text body, ignoring surrounding whitespace', () async {
      final dataSource = buildDataSource([respond(' 42\n')]);

      expect(await dataSource.getRandomInt(), 42);
    });

    test('throws ParseException for a non-numeric body', () async {
      final dataSource = buildDataSource([respond('<html>')]);

      await expectLater(dataSource.getRandomInt(), throwsA(isA<ParseException>()));
    });

    for (final body in ['0', '101', '-5']) {
      test('throws ParseException for $body, which is outside 1..100', () async {
        final dataSource = buildDataSource([respond(body)]);

        await expectLater(dataSource.getRandomInt(), throwsA(isA<ParseException>()));
      });
    }
  });
}
