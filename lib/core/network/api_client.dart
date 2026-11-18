import 'dart:developer';
import 'dart:math' show min;

import 'package:clean_architecture_demo/core/config/app_config.dart';
import 'package:clean_architecture_demo/core/network/network_exception.dart';
import 'package:dio/dio.dart';

/// Wraps [Dio]: retries transient failures of idempotent requests and turns every Dio
/// error into a [NetworkException].
class ApiClient {
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};

  final Dio _dio;
  final int _maxRetries;
  final int _maxTimeoutRetries;
  final Duration _retryDelay;

  ApiClient(
    this._dio, {
    required this._maxRetries,
    required this._maxTimeoutRetries,
    required this._retryDelay,
  });

  factory ApiClient.fromConfig(AppConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        sendTimeout: config.requestTimeout,
        receiveTimeout: config.requestTimeout,
      ),
    );
    if (config.enableLogging) {
      dio.interceptors.add(
        // Method, URL, status and errors only: headers and bodies can carry tokens or
        // personal data, and logs end up in places that are not meant to hold them.
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          logPrint: (message) => log('$message', name: 'http'),
        ),
      );
    }
    return ApiClient(
      dio,
      maxRetries: config.maxRetries,
      maxTimeoutRetries: config.maxTimeoutRetries,
      retryDelay: config.retryDelay,
    );
  }

  Future<T> get<T>(
    String path, {
    required T Function(Object? data) parser,
    Map<String, Object?>? query,
  }) {
    return request(path, method: 'GET', parser: parser, query: query);
  }

  /// Sends the request and parses the response body with [parser].
  ///
  /// Idempotent requests are retried with a linearly growing delay: 5xx responses up to
  /// `maxRetries` times, send/receive timeouts up to `maxTimeoutRetries` times. An
  /// unreachable host is never retried, so callers can fall back at once.
  Future<T> request<T>(
    String path, {
    required String method,
    required T Function(Object? data) parser,
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final canRetry = _idempotentMethods.contains(method.toUpperCase());
    for (var attempt = 0; ; attempt++) {
      final Response<Object?> response;
      try {
        response = await _dio.request<Object?>(
          path,
          queryParameters: query,
          data: body,
          options: Options(method: method),
        );
      } on DioException catch (e) {
        if (canRetry && attempt < _retryLimit(e)) {
          await Future<void>.delayed(_retryDelay * (attempt + 1));
          continue;
        }
        throw _toNetworkException(e);
      }

      // A malformed body surfaces as a FormatException or a TypeError from a cast. Any other
      // error is a bug in the parser and propagates as is.
      try {
        return parser(response.data);
      } on FormatException catch (e) {
        throw ParseException(e);
      } on TypeError catch (e) {
        throw ParseException(e);
      }
    }
  }

  int _retryLimit(DioException error) => switch (error.type) {
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => min(_maxTimeoutRetries, _maxRetries),
    DioExceptionType.badResponse => _isServerError(error.response?.statusCode) ? _maxRetries : 0,
    _ => 0,
  };

  static bool _isServerError(int? statusCode) =>
      statusCode != null && statusCode >= 500 && statusCode < 600;

  static NetworkException _toNetworkException(DioException error) => switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout => HostUnreachableException(error),
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => RequestTimeoutException(error),
    DioExceptionType.badResponse => ServerException(error.response?.statusCode ?? 0, error),
    DioExceptionType.cancel ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => UnknownNetworkException(error),
  };
}
