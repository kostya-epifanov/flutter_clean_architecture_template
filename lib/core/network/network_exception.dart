/// Why an `ApiClient` request failed, at the transport level.
///
/// Data sources throw these; repositories translate them into domain failures.
sealed class NetworkException implements Exception {
  /// The underlying error, kept for logs.
  final Object? cause;

  const NetworkException([this.cause]);

  @override
  String toString() => cause == null ? '$runtimeType' : '$runtimeType: $cause';
}

/// The host could not be reached: no network, DNS failure, refused or timed-out connection.
final class HostUnreachableException extends NetworkException {
  const HostUnreachableException([super.cause]);
}

/// The server accepted the connection but sent or received data too slowly.
final class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException([super.cause]);
}

/// The server answered with a non-2xx status.
final class ServerException extends NetworkException {
  final int statusCode;

  const ServerException(this.statusCode, [super.cause]);

  @override
  String toString() => 'ServerException($statusCode)';
}

/// The response body could not be parsed.
final class ParseException extends NetworkException {
  const ParseException([super.cause]);
}

/// Anything else: a cancelled request, a bad certificate, an unexpected Dio error.
final class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException([super.cause]);
}
