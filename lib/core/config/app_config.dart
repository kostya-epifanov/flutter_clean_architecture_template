import 'package:flutter/foundation.dart';

import 'environment.dart';

/// Application-wide configuration constants
class AppConfig {
  AppConfig._();

  /// Current environment
  static Environment get environment => Environment.current;

  /// Environment-specific configurations.
  ///
  /// random.org has no separate staging host, so staging uses the public API
  /// too; in a real project it would point at the staging backend (or be
  /// overridden with `--dart-define=API_BASE_URL=...`).
  static _EnvironmentConfig get _currentConfig => switch (environment) {
    Environment.development => const _EnvironmentConfig(
      apiBaseUrl: 'https://www.random.org',
      enableLogging: true,
      httpTimeout: Duration(seconds: 30),
      maxRetries: 3,
    ),
    Environment.staging => const _EnvironmentConfig(
      apiBaseUrl: 'https://www.random.org',
      enableLogging: true,
      httpTimeout: Duration(seconds: 30),
      maxRetries: 3,
    ),
    Environment.production => const _EnvironmentConfig(
      apiBaseUrl: 'https://www.random.org',
      enableLogging: false,
      httpTimeout: Duration(seconds: 20),
      maxRetries: 2,
    ),
  };

  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  // ============================================================================
  // Public Configuration Accessors
  // ============================================================================

  /// Base URL for API endpoints
  /// Can be overridden at compile time with `--dart-define=API_BASE_URL=<url>`
  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : _currentConfig.apiBaseUrl;

  /// Enable/disable debug logging
  static bool get enableLogging => const bool.hasEnvironment('ENABLE_LOGGING')
      ? const bool.fromEnvironment('ENABLE_LOGGING')
      : _currentConfig.enableLogging;

  /// How long to wait for the server to send or receive data
  static Duration get httpTimeout => _currentConfig.httpTimeout;

  /// How long to wait for a connection to the server. Kept short so that a
  /// network without internet access falls back to local data quickly.
  static const Duration connectTimeout = Duration(seconds: 10);

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

    debugPrint(
      'App configuration: '
      'environment=${environment.name}, '
      'apiBaseUrl=$apiBaseUrl, '
      'enableLogging=$enableLogging, '
      'connectTimeout=${connectTimeout.inSeconds}s, '
      'httpTimeout=${httpTimeout.inSeconds}s, '
      'maxRetries=$maxRetries',
    );
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
