import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/core/network/http/http_client.dart';
import 'package:flutter_clean_template/core/network/http/http_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../../helpers/fake_http_client_adapter.dart';

const _url = 'https://api.test/numbers';

void main() {
  late FakeHttpClientAdapter adapter;

  HttpClient buildClient(
    List<FakeResponder> responders, {
    int maxRetries = 2,
    Duration retryDelay = Duration.zero,
  }) {
    adapter = FakeHttpClientAdapter(responders);
    return HttpClient(
      HttpInterceptor(Logger(level: Level.off)),
      dio: Dio()..httpClientAdapter = adapter,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  Future<int> getNumber(HttpClient client, {Map<String, dynamic>? query}) {
    return client.execute<int>(
      method: 'GET',
      url: _url,
      query: query,
      parser: (data) => int.parse(data.toString()),
    );
  }

  group('HttpClient.execute', () {
    test('returns the parsed body on success', () async {
      final client = buildClient([respond('42')]);

      expect(await getNumber(client), 42);
      expect(adapter.requests, hasLength(1));
    });

    test('sends the method and query parameters', () async {
      final client = buildClient([respond('1')]);

      await getNumber(client, query: {'min': 1, 'max': 100});

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), startsWith(_url));
      expect(request.uri.queryParameters, {'min': '1', 'max': '100'});
    });

    test('throws ParseException when the parser fails, without retrying', () async {
      final client = buildClient([respond('not a number')]);

      await expectLater(getNumber(client), throwsA(isA<ParseException>()));
      expect(adapter.requests, hasLength(1));
    });

    group('retries', () {
      test('retries a connection error and returns the next success', () async {
        final client = buildClient([throwDio(DioExceptionType.connectionError), respond('7')]);

        expect(await getNumber(client), 7);
        expect(adapter.requests, hasLength(2));
      });

      test('retries a 5xx response and returns the next success', () async {
        final client = buildClient([respond('unavailable', statusCode: 503), respond('7')]);

        expect(await getNumber(client), 7);
        expect(adapter.requests, hasLength(2));
      });

      test('gives up after maxRetries, sending maxRetries + 1 requests', () async {
        final client = buildClient([throwDio(DioExceptionType.connectionError)], maxRetries: 3);

        await expectLater(getNumber(client), throwsA(isA<NoInternetException>()));
        expect(adapter.requests, hasLength(4));
      });

      test('does not retry a 4xx response', () async {
        final client = buildClient([respond('not found', statusCode: 404)]);

        await expectLater(
          getNumber(client),
          throwsA(
            isA<ServerException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.message, 'message', 'not found'),
          ),
        );
        expect(adapter.requests, hasLength(1));
      });

      test('waits a linearly growing delay between attempts', () {
        fakeAsync((async) {
          final client = buildClient(
            [throwDio(DioExceptionType.connectionError)],
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
          expect(error, isA<NoInternetException>());
        });
      });
    });

    group('maps DioException types to NetworkExceptions', () {
      final expectations = <DioExceptionType, (String, Matcher)>{
        DioExceptionType.connectionTimeout: (
          'RequestTimeoutException',
          isA<RequestTimeoutException>(),
        ),
        DioExceptionType.sendTimeout: ('RequestTimeoutException', isA<RequestTimeoutException>()),
        DioExceptionType.receiveTimeout: (
          'RequestTimeoutException',
          isA<RequestTimeoutException>(),
        ),
        DioExceptionType.connectionError: ('NoInternetException', isA<NoInternetException>()),
        DioExceptionType.cancel: ('CancelledException', isA<CancelledException>()),
        DioExceptionType.badCertificate: (
          'UnknownNetworkException',
          isA<UnknownNetworkException>(),
        ),
        DioExceptionType.unknown: ('UnknownNetworkException', isA<UnknownNetworkException>()),
      };

      for (final MapEntry(key: type, value: (name, matcher)) in expectations.entries) {
        test('${type.name} -> $name', () async {
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
