enum Environment {
  development,
  staging,
  production;

  /// Parses the `ENVIRONMENT` dart-define; an unknown or empty name means development.
  static Environment parse(String name) => switch (name.toLowerCase()) {
    'production' || 'prod' => Environment.production,
    'staging' || 'stg' => Environment.staging,
    _ => Environment.development,
  };
}
