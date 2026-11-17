import 'package:clean_architecture_demo/core/config/app_config.dart';
import 'package:clean_architecture_demo/core/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Environment.parse', () {
    final cases = {
      'production': Environment.production,
      'PROD': Environment.production,
      'staging': Environment.staging,
      'stg': Environment.staging,
      'development': Environment.development,
      '': Environment.development,
      'typo': Environment.development,
    };

    for (final MapEntry(key: name, value: expected) in cases.entries) {
      test("'$name' -> ${expected.name}", () => expect(Environment.parse(name), expected));
    }
  });

  group('AppConfig.forEnvironment', () {
    test('production disables logging and shortens timeouts and retries', () {
      final config = AppConfig.forEnvironment(Environment.production);

      expect(config.enableLogging, isFalse);
      expect(config.requestTimeout, const Duration(seconds: 20));
      expect(config.maxRetries, 2);
    });

    for (final environment in [Environment.development, Environment.staging]) {
      test('${environment.name} enables logging', () {
        final config = AppConfig.forEnvironment(environment);

        expect(config.enableLogging, isTrue);
        expect(config.requestTimeout, const Duration(seconds: 30));
        expect(config.maxRetries, 3);
      });
    }

    test('every environment fails fast on connect and retries a timeout once', () {
      for (final environment in Environment.values) {
        final config = AppConfig.forEnvironment(environment);

        expect(config.connectTimeout, const Duration(seconds: 10));
        expect(config.maxTimeoutRetries, 1);
      }
    });

    test('overrides take precedence over the defaults', () {
      final config = AppConfig.forEnvironment(
        Environment.production,
        apiBaseUrl: 'http://localhost:3000',
        enableLogging: true,
      );

      expect(config.apiBaseUrl, 'http://localhost:3000');
      expect(config.enableLogging, isTrue);
    });
  });
}
