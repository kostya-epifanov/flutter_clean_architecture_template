import 'package:clean_architecture_demo/core/network/api_client.dart';
import 'package:clean_architecture_demo/core/network/network_exception.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_client_adapter.dart';

const _path = '/numbers';

void main() {
  late FakeHttpClientAdapter adapter;

  ApiClient buildClient(
    List<FakeResponder> responders, {
    int maxRetries = 2,
    int maxTimeoutRetries = 1,
    Duration retryDelay = Duration.zero,
  }) {
    adapter = FakeHttpClientAdapter(responders);
    return ApiClient(
      Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter,
      maxRetries: maxRetries,
      maxTimeoutRetries: maxTimeoutRetries,
      retryDelay: retryDelay,
    );
  }

  int parseInt(Object? data) => int.parse('$data');

  Future<int> getNumber(ApiClient client, {Map<String, Object?>? query}) =>
      client.get(_path, query: query, parser: parseInt);

  group('ApiClient', () {
    test('returns the parsed body on success', () async {
      final client = buildClient([respond('42')]);

      expect(await getNumber(client), 42);
      expect(adapter.requests, hasLength(1));
    });

    test('sends the method, base URL, path and query parameters', () async {
      final client = buildClient([respond('1')]);

      await getNumber(client, query: {'min': 1, 'max': 100});

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), startsWith('https://api.test$_path'));
      expect(request.uri.queryParameters, {'min': '1', 'max': '100'});
    });

    test('throws ParseException when the parser fails, without retrying', () async {
      final client = buildClient([respond('not a number')]);

      await expectLater(getNumber(client), throwsA(isA<ParseException>()));
      expect(adapter.requests, hasLength(1));
    });

    group('retries', () {
      test('retries a timeout and returns the next success', () async {
        final client = buildClient([throwDio(DioExceptionType.receiveTimeout), respond('7')]);

        expect(await getNumber(client), 7);
        expect(adapter.requests, hasLength(2));
      });

      for (final type in [DioExceptionType.connectionTimeout, DioExceptionType.connectionError]) {
        test('does not retry a ${type.name}, so callers can fall back at once', () async {
          final client = buildClient([throwDio(type), respond('7')]);

          await expectLater(getNumber(client), throwsA(isA<HostUnreachableException>()));
          expect(adapter.requests, hasLength(1));
        });
      }

      test('retries a 5xx response and returns the next success', () async {
        final client = buildClient([respond('unavailable', statusCode: 503), respond('7')]);

        expect(await getNumber(client), 7);
        expect(adapter.requests, hasLength(2));
      });

      test('gives up on a 5xx after maxRetries, sending maxRetries + 1 requests', () async {
        final client = buildClient([respond('down', statusCode: 503)], maxRetries: 3);

        await expectLater(getNumber(client), throwsA(isA<ServerException>()));
        expect(adapter.requests, hasLength(4));
      });

      for (final type in [DioExceptionType.receiveTimeout, DioExceptionType.sendTimeout]) {
        test('retries a ${type.name} only maxTimeoutRetries times', () async {
          final client = buildClient([throwDio(type)], maxRetries: 3, maxTimeoutRetries: 1);

          await expectLater(getNumber(client), throwsA(isA<RequestTimeoutException>()));
          expect(adapter.requests, hasLength(2));
        });
      }

      test('never retries a timeout more than maxRetries times', () async {
        final client = buildClient(
          [throwDio(DioExceptionType.receiveTimeout)],
          maxRetries: 1,
          maxTimeoutRetries: 5,
        );

        await expectLater(getNumber(client), throwsA(isA<RequestTimeoutException>()));
        expect(adapter.requests, hasLength(2));
      });

      test('does not retry a 4xx response', () async {
        final client = buildClient([respond('not found', statusCode: 404)]);

        await expectLater(
          getNumber(client),
          throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404)),
        );
        expect(adapter.requests, hasLength(1));
      });

      test('does not retry a non-idempotent request', () async {
        final client = buildClient([respond('down', statusCode: 503), respond('7')]);

        await expectLater(
          client.request(_path, method: 'POST', body: {'n': 1}, parser: parseInt),
          throwsA(isA<ServerException>()),
        );
        expect(adapter.requests, hasLength(1));
      });

      test('waits a linearly growing delay between attempts', () {
        fakeAsync((async) {
          final client = buildClient(
            [respond('down', statusCode: 503)],
            maxRetries: 2,
            retryDelay: const Duration(seconds: 1),
          );
          Object? error;
          getNumber(client).catchError((Object e) {
            error = e;
            return 0;
          });

          async.elapse(Duration.zero); // let Dio dispatch the first request
          expect(adapter.requests, hasLength(1));

          async.elapse(const Duration(seconds: 1)); // 1 x retryDelay
          expect(adapter.requests, hasLength(2));

          async.elapse(const Duration(milliseconds: 1999));
          expect(adapter.requests, hasLength(2), reason: 'second wait is 2 x retryDelay');

          async.elapse(const Duration(milliseconds: 1));
          expect(adapter.requests, hasLength(3));
          expect(error, isA<ServerException>());
        });
      });
    });

    group('maps DioException types to NetworkExceptions', () {
      final expectations = <DioExceptionType, Matcher>{
        DioExceptionType.connectionTimeout: isA<HostUnreachableException>(),
        DioExceptionType.connectionError: isA<HostUnreachableException>(),
        DioExceptionType.sendTimeout: isA<RequestTimeoutException>(),
        DioExceptionType.receiveTimeout: isA<RequestTimeoutException>(),
        DioExceptionType.cancel: isA<UnknownNetworkException>(),
        DioExceptionType.badCertificate: isA<UnknownNetworkException>(),
        DioExceptionType.unknown: isA<UnknownNetworkException>(),
      };

      for (final MapEntry(key: type, value: matcher) in expectations.entries) {
        test(type.name, () async {
          final client = buildClient([throwDio(type)], maxRetries: 0);

          await expectLater(getNumber(client), throwsA(matcher));
        });
      }

      test('badResponse -> ServerException with the status code', () async {
        final client = buildClient([respond('down', statusCode: 500)], maxRetries: 0);

        await expectLater(
          getNumber(client),
          throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500)),
        );
      });
    });
  });
}
