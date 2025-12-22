import 'environment.dart';

/// Application-wide configuration constants
class AppConfig {
  AppConfig._();

  /// Current environment
  static Environment get environment => Environment.current;

  /// Environment-specific configurations
  static const Map<Environment, _EnvironmentConfig> _configs = {
    Environment.development: _EnvironmentConfig(
      apiBaseUrl: 'https://www.random.org',
      enableLogging: true,
      httpTimeout: Duration(seconds: 30),
      maxRetries: 3,
    ),
    Environment.staging: _EnvironmentConfig(
      apiBaseUrl: 'https://staging-api.random.org',
      enableLogging: true,
      httpTimeout: Duration(seconds: 30),
      maxRetries: 3,
    ),
    Environment.production: _EnvironmentConfig(
      apiBaseUrl: 'https://www.random.org',
      enableLogging: false,
      httpTimeout: Duration(seconds: 20),
      maxRetries: 2,
    ),
  };

  /// Get current environment configuration
  static _EnvironmentConfig get _currentConfig =>
      _configs[environment] ?? _configs[Environment.development]!;

  // ============================================================================
  // Public Configuration Accessors
  // ============================================================================

  /// Base URL for API endpoints
  /// Can be overridden at compile time with --dart-define=API_BASE_URL=<url>
  static String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: '',
      ).isEmpty
          ? _currentConfig.apiBaseUrl
          : const String.fromEnvironment('API_BASE_URL');

  /// Enable/disable debug logging
  static bool get enableLogging => const bool.hasEnvironment('ENABLE_LOGGING')
      ? const bool.fromEnvironment('ENABLE_LOGGING')
      : _currentConfig.enableLogging;

  /// HTTP request timeout duration
  static Duration get httpTimeout => _currentConfig.httpTimeout;

  /// Number of retry attempts for failed requests
  static int get maxRetries => _currentConfig.maxRetries;

  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);

  /// API endpoints
  static const String randomIntEndpoint = '/integers/';

  // ============================================================================
  // Debug Information
  // ============================================================================

  /// Print current configuration (for debugging)
  static void printConfig() {
    if (!enableLogging) return;

    print('==========================================');
    print('App Configuration');
    print('==========================================');
    print('Environment: ${environment.name}');
    print('API Base URL: $apiBaseUrl');
    print('Enable Logging: $enableLogging');
    print('HTTP Timeout: ${httpTimeout.inSeconds}s');
    print('Max Retries: $maxRetries');
    print('==========================================');
  }
}

/// Internal class to hold environment-specific configuration
class _EnvironmentConfig {
  final String apiBaseUrl;
  final bool enableLogging;
  final Duration httpTimeout;
  final int maxRetries;

  const _EnvironmentConfig({
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.httpTimeout,
    required this.maxRetries,
  });
}
