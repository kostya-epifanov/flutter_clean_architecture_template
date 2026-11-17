import 'package:dio/dio.dart';
import 'package:flutter_clean_template/core/config/app_config.dart';
import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';

import 'http_interceptor.dart';

/// Thin wrapper over [Dio] that adds retries and maps transport errors
/// to [NetworkException]s.
class HttpClient {
  final Dio _dio;
  final int _maxRetries;
  final Duration _retryDelay;

  /// [dio], [maxRetries] and [retryDelay] default to the app configuration
  /// and can be overridden in tests.
  HttpClient(
    HttpInterceptor interceptor, {
    Dio? dio,
    int? maxRetries,
    Duration? retryDelay,
  }) : _dio = dio ?? Dio(),
       _maxRetries = maxRetries ?? AppConfig.maxRetries,
       _retryDelay = retryDelay ?? AppConfig.retryDelay {
    _dio.options
      ..connectTimeout = AppConfig.httpTimeout
      ..receiveTimeout = AppConfig.httpTimeout
      ..sendTimeout = AppConfig.httpTimeout
      ..listFormat = ListFormat.csv;
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(interceptor);
    }
  }

  /// Performs the request and parses the body with [parser].
  ///
  /// Transient failures (timeouts, connection errors, 5xx) are retried up to
  /// `maxRetries` times with a linearly growing delay, so the request is sent
  /// at most `maxRetries + 1` times.
  Future<T> execute<T>({
    required String method,
    required String url,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final Response<dynamic> response;
      try {
        response = await _dio.request<dynamic>(
          url,
          queryParameters: query,
          data: body,
          options: Options(method: method, headers: headers),
        );
      } on DioException catch (e) {
        if (attempt < _maxRetries && _isRetryable(e)) {
          await Future<void>.delayed(_retryDelay * (attempt + 1));
          continue;
        }
        throw _mapDioException(e);
      }

      try {
        return parser(response.data);
      } catch (e) {
        throw ParseException(
          message: 'Failed to parse response: $e',
          originalError: e,
        );
      }
    }
  }

  static bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return statusCode >= 500 && statusCode < 600;
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  static NetworkException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message =
            error.response?.data?.toString() ??
            error.response?.statusMessage ??
            'Server error occurred';
        return ServerException(statusCode, message, originalError: error);

      case DioExceptionType.cancel:
        return const CancelledException();

      case DioExceptionType.badCertificate:
        return UnknownNetworkException(
          message: 'SSL certificate verification failed',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return UnknownNetworkException(
          message: error.message ?? 'An unexpected error occurred',
          originalError: error,
        );
    }
  }
}
