import 'package:clean_architecture_demo/core/config/environment.dart';

/// Settings that differ between environments. Built once in `main` and passed to the
/// composition root, so nothing else reads compile-time constants.
class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;

  /// How long to wait for a connection. Kept short: an unreachable host falls back to a
  /// local number, so waiting longer only delays the user.
  final Duration connectTimeout;

  /// How long a connected server may take to send or receive data.
  final Duration requestTimeout;

  /// Retries for 5xx responses.
  final int maxRetries;

  /// Retries for send/receive timeouts. Lower than [maxRetries] because every attempt can
  /// take a full [requestTimeout].
  final int maxTimeoutRetries;

  /// Base delay between retries; the n-th retry waits n times as long.
  final Duration retryDelay;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.requestTimeout,
    required this.maxRetries,
    this.connectTimeout = const Duration(seconds: 10),
    this.maxTimeoutRetries = 1,
    this.retryDelay = const Duration(seconds: 2),
  });

  /// Defaults for [environment], with optional overrides.
  factory AppConfig.forEnvironment(
    Environment environment, {
    String? apiBaseUrl,
    bool? enableLogging,
  }) {
    final isProduction = environment == Environment.production;
    return AppConfig(
      environment: environment,
      // random.org has no staging host; a real backend would have one per environment.
      apiBaseUrl: apiBaseUrl ?? 'https://www.random.org',
      enableLogging: enableLogging ?? !isProduction,
      requestTimeout: Duration(seconds: isProduction ? 20 : 30),
      maxRetries: isProduction ? 2 : 3,
    );
  }

  /// Reads `--dart-define`s: `ENVIRONMENT` picks the defaults, `API_BASE_URL` and
  /// `ENABLE_LOGGING` override them.
  factory AppConfig.fromDartDefines() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    return AppConfig.forEnvironment(
      Environment.parse(const String.fromEnvironment('ENVIRONMENT')),
      apiBaseUrl: apiBaseUrl.isEmpty ? null : apiBaseUrl,
      enableLogging: const bool.hasEnvironment('ENABLE_LOGGING')
          ? const bool.fromEnvironment('ENABLE_LOGGING')
          : null,
    );
  }

  @override
  String toString() =>
      'AppConfig(${environment.name}, $apiBaseUrl, logging: $enableLogging, '
      'connect: ${connectTimeout.inSeconds}s, request: ${requestTimeout.inSeconds}s, '
      'retries: $maxRetries, timeout retries: $maxTimeoutRetries)';
}
