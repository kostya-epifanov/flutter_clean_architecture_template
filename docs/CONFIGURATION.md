# Configuration Management Guide

This document describes how to manage application configurations across different environments.

## Table of Contents

- [Overview](#overview)
- [Environment Setup](#environment-setup)
- [Running the App](#running-the-app)
- [Configuration Structure](#configuration-structure)
- [Custom Configurations](#custom-configurations)
- [Build & Release](#build--release)

## Overview

The application uses a centralized configuration system that supports multiple environments:

- **Development** - Local development with verbose logging
- **Staging** - Pre-production environment for testing
- **Production** - Live production environment

Configuration is managed through:

- `lib/core/config/environment.dart` - Environment enum
- `lib/core/config/app_config.dart` - Centralized configuration
- `.vscode/launch.json` - IDE launch configurations

## Environment Setup

### Default Behavior

If no environment is specified, the app runs in **development** mode with default settings:

```bash
flutter run
```

### Available Environments

| Environment | API Base URL                   | Logging  | Timeout | Max Retries |
|-------------|--------------------------------|----------|---------|-------------|
| Development | https://www.random.org         | Enabled  | 30s     | 3           |
| Staging     | https://staging-api.random.org | Enabled  | 30s     | 3           |
| Production  | https://www.random.org         | Disabled | 20s     | 2           |

## Running the App

### Using VS Code/Cursor IDE

Press `F5` or click "Run and Debug", then select one of the pre-configured launch options:

- **Development** - Standard dev mode
- **Development (Custom API)** - Dev mode with local API
- **Staging** - Staging environment
- **Staging (Custom API)** - Staging with custom API
- **Production** - Production environment
- **Production (Custom API)** - Production with custom API

### Using Command Line

#### Development

```bash
flutter run --dart-define=ENVIRONMENT=development
```

#### Staging

```bash
flutter run --dart-define=ENVIRONMENT=staging
```

#### Production

```bash
flutter run --dart-define=ENVIRONMENT=production --dart-define=ENABLE_LOGGING=false
```

## Configuration Structure

### Environment Configuration

Each environment has its own configuration in `app_config.dart`:

```dart
static const Map<Environment, _EnvironmentConfig> _configs = {
  Environment.development: _EnvironmentConfig(
    apiBaseUrl: 'https://www.random.org',
    enableLogging: true,
    httpTimeout: Duration(seconds: 30),
    maxRetries: 3,
  ),
  // ... other environments
};
```

### Accessing Configuration

Use `AppConfig` static accessors throughout the app:

```dart
import 'package:flutter_clean_template/core/config/app_config.dart';

// Get API base URL
final baseUrl = AppConfig.apiBaseUrl;

// Get endpoint
final endpoint = AppConfig.randomIntEndpoint;

// Check environment
if (
AppConfig.environment.isDevelopment) {
// Development-specific code
}
```

## Custom Configurations

### Override API Base URL

Override the API URL at runtime using `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

### Override Logging

```bash
flutter run --dart-define=ENABLE_LOGGING=true
```

### Multiple Overrides

```bash
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=API_BASE_URL=https://my-staging-api.com \
  --dart-define=ENABLE_LOGGING=true
```

## Build & Release

### Development Build

```bash
flutter build apk --dart-define=ENVIRONMENT=development
flutter build ios --dart-define=ENVIRONMENT=development
```

### Staging Build

```bash
flutter build apk --dart-define=ENVIRONMENT=staging
flutter build ios --dart-define=ENVIRONMENT=staging
```

### Production Build

```bash
# Android
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ENABLE_LOGGING=false

# iOS
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ENABLE_LOGGING=false
```

### Production with Custom API

```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.myapp.com \
  --dart-define=ENABLE_LOGGING=false
```

## Adding New Configuration Values

### 1. Add to Environment Config

In `app_config.dart`, add the new value to `_EnvironmentConfig`:

```dart
class _EnvironmentConfig {
  final String apiBaseUrl;
  final bool enableLogging;
  final String newConfigValue; // Add here

  const _EnvironmentConfig({
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.newConfigValue, // Add here
  });
}
```

### 2. Update Environment Configurations

```dart
static const Map<Environment, _EnvironmentConfig> _configs = {
  Environment.development: _EnvironmentConfig(
    // ... existing configs
    newConfigValue: 'dev-value',
  ),
  Environment.staging: _EnvironmentConfig(
    // ... existing configs
    newConfigValue: 'staging-value',
  ),
  Environment.production: _EnvironmentConfig(
    // ... existing configs
    newConfigValue: 'prod-value',
  ),
};
```

### 3. Add Public Accessor

```dart
static String get newConfigValue => _currentConfig.newConfigValue;
```

### 4. (Optional) Add Runtime Override

```dart
static String get newConfigValue => const String.fromEnvironment(
      'NEW_CONFIG_VALUE',
      defaultValue: '',
    ).isEmpty
    ? _currentConfig.newConfigValue
    : const String.fromEnvironment('NEW_CONFIG_VALUE');
```

## Best Practices

1. **Never hardcode URLs** - Always use `AppConfig.apiBaseUrl` + endpoint
2. **Environment-specific logic** - Use `AppConfig.environment` checks
3. **Sensitive data** - Use `--dart-define` for secrets, never commit them
4. **Debug config** - Call `AppConfig.printConfig()` in `main()` during development
5. **Production logging** - Always disable in production builds
6. **Testing** - Create mock configs for unit tests

## Troubleshooting

### Config not updating?

Hot reload doesn't pick up `--dart-define` changes. Use hot restart (Shift + R) or stop and rerun
the app.

### Wrong environment?

Check the console output at app startup. `AppConfig.printConfig()` displays current configuration.

### API URL not working?

Verify the URL format in `app_config.dart` and ensure endpoints start with `/`.

## Examples

### DataSource Implementation

```dart
class MyRemoteDataSource {
  final HttpClient _httpClient;

  Future<Data> fetchData() async {
    // Construct URL using config
    final url = '${AppConfig.apiBaseUrl}/api/endpoint';
    
    return await _httpClient.execute(
      method: 'GET',
      url: url,
      parser: (data) => Data.fromJson(data),
    );
  }
}
```

### Environment-Specific Features

```dart
void initializeApp() {
  if (AppConfig.environment.isDevelopment) {
    // Enable debug tools
    enableDebugMode();
  }
  
  if (AppConfig.environment.isProduction) {
    // Enable crash reporting
    initializeCrashReporting();
  }
}
```

