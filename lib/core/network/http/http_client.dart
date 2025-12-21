import 'package:dio/dio.dart';
import 'package:flutter_clean_template/core/config/app_config.dart';
import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';

import 'http_interceptor.dart';

class HttpClient {
  final Dio _internalClient = Dio();
  final HttpInterceptor _interceptor;

  HttpClient(this._interceptor) {
    _internalClient.interceptors.add(_interceptor);

    // Configure timeouts
    _internalClient.options.connectTimeout = AppConfig.httpTimeout;
    _internalClient.options.receiveTimeout = AppConfig.httpTimeout;
    _internalClient.options.sendTimeout = AppConfig.httpTimeout;
  }

  /// Execute HTTP request with automatic retry logic and error handling
  Future<T> execute<T>({
    required String method,
    required String url,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
    int maxRetries = AppConfig.maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final response = await _internalClient.request(
          _prepareUrl(
            url: url,
            query: query,
          ),
          options: Options(
            method: method,
            headers: headers,
          ),
          data: body,
        );

        // Parse and return the response
        try {
          return parser(response.data);
        } catch (e) {
          throw ParseException(
            message: 'Failed to parse response: $e',
            originalError: e,
          );
        }
      } on DioException catch (e) {
        attempts++;

        // Check if we should retry
        final shouldRetry = _shouldRetry(e, attempts, maxRetries);

        if (!shouldRetry) {
          throw _handleDioException(e);
        }

        // Wait before retrying
        if (attempts < maxRetries) {
          await Future.delayed(AppConfig.retryDelay * attempts);
        }
      }
    }

    // This should never be reached, but just in case
    throw const UnknownNetworkException(
      message: 'Maximum retry attempts reached',
    );
  }

  /// Determine if the request should be retried
  bool _shouldRetry(DioException error, int attempts, int maxRetries) {
    if (attempts >= maxRetries) {
      return false;
    }

    // Retry on timeout and connection errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // Retry on 5xx server errors
        final statusCode = error.response?.statusCode ?? 0;
        return statusCode >= 500 && statusCode < 600;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Convert DioException to our custom NetworkException
  NetworkException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message = error.response?.data?.toString() ??
            error.response?.statusMessage ??
            'Server error occurred';
        return ServerException(
          statusCode,
          message,
          originalError: error,
        );

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

  static String _prepareUrl({
    required String url,
    Map<String, dynamic>? query,
  }) {
    String result = url;
    if (query != null && query.isNotEmpty) {
      final List<dynamic> queries = [];
      for (final entry in query.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is Iterable) {
          queries.add('$key=${value.join(',')}');
        } else {
          queries.add('$key=$value');
        }
      }
      result += '?${queries.join('&')}';
    }
    return result;
  }
}
