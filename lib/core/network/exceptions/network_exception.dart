/// Base class for all network-related exceptions
abstract class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when there's no internet connection
class NoInternetException extends NetworkException {
  const NoInternetException()
    : super('No internet connection. Please check your network settings.');

  @override
  String toString() => 'NoInternetException: $message';
}

/// Thrown when the server could not be reached within the connect timeout.
///
/// Like [NoInternetException], it means the host is unreachable from this
/// network, as opposed to [RequestTimeoutException] where the server is
/// reachable but slow.
class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException() : super('Could not reach the server. Please try again.');

  @override
  String toString() => 'ConnectionTimeoutException: $message';
}

/// Thrown when a connected server takes too long to send or receive data
class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException() : super('Request timed out. Please try again.');

  @override
  String toString() => 'RequestTimeoutException: $message';
}

/// Thrown when server returns an error response
class ServerException extends NetworkException {
  const ServerException(int statusCode, super.message, {super.originalError})
    : super(statusCode: statusCode);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when response data cannot be parsed
class ParseException extends NetworkException {
  const ParseException({String message = 'Failed to parse response data', dynamic originalError})
    : super(message, originalError: originalError);

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
  }) : super(message, originalError: originalError);

  @override
  String toString() => 'UnknownNetworkException: $message';
}
