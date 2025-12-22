/// Enum representing different application environments
enum Environment {
  development,
  staging,
  production;

  /// Get current environment from compile-time constant
  static Environment get current {
    const env = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );

    return switch (env.toLowerCase()) {
      'production' || 'prod' => Environment.production,
      'staging' || 'stg' => Environment.staging,
      _ => Environment.development,
    };
  }

  /// Check if running in development
  bool get isDevelopment => this == Environment.development;

  /// Check if running in staging
  bool get isStaging => this == Environment.staging;

  /// Check if running in production
  bool get isProduction => this == Environment.production;
}
