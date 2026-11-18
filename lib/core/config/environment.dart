enum Environment {
  development,
  staging,
  production;

  /// Parses the `ENVIRONMENT` dart-define; an empty name means development.
  ///
  /// An unknown name throws: a typo such as `prodution` must not quietly turn a release
  /// build into a development one with logging on.
  static Environment parse(String name) => switch (name.toLowerCase()) {
    'production' || 'prod' => Environment.production,
    'staging' || 'stg' => Environment.staging,
    'development' || 'dev' || '' => Environment.development,
    _ => throw ArgumentError.value(name, 'ENVIRONMENT', 'Unknown environment'),
  };
}
