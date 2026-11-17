/// Why a number could not be loaded.
///
/// An unreachable host is not a failure: the repository generates the number locally.
enum RandomIntFailure {
  /// The server answered with an error status.
  serverError,

  /// The server accepted the connection but answered too slowly.
  timeout,

  /// The server's answer was not a number.
  invalidResponse,

  unknown,
}
