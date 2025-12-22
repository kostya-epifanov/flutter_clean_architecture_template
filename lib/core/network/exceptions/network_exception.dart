/// Base class for all network-related exceptions
abstract class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when there's no internet connection
class NoInternetException extends NetworkException {
  const NoInternetException()
      : super(
          'No internet connection. Please check your network settings.',
        );

  @override
  String toString() => 'NoInternetException: $message';
}

/// Thrown when a request times out
class TimeoutException extends NetworkException {
  const TimeoutException() : super('Request timed out. Please try again.');

  @override
  String toString() => 'TimeoutException: $message';
}

/// Thrown when server returns an error response
class ServerException extends NetworkException {
  const ServerException(
    int statusCode,
    String message, {
    dynamic originalError,
  }) : super(
          message,
          statusCode: statusCode,
          originalError: originalError,
        );

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when response data cannot be parsed
class ParseException extends NetworkException {
  const ParseException({
    String message = 'Failed to parse response data',
    dynamic originalError,
  }) : super(
          message,
          originalError: originalError,
        );

  @override
  String toString() => 'ParseException: $message';
}

/// Thrown when request is cancelled
class CancelledException extends NetworkException {
  const CancelledException() : super('Request was cancelled');

  @override
  String toString() => 'CancelledException: $message';
}

/// Thrown for unknown/unexpected errors
class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException({
    String message = 'An unexpected error occurred',
    dynamic originalError,
  }) : super(
          message,
          originalError: originalError,
        );

  @override
  String toString() => 'UnknownNetworkException: $message';
}
