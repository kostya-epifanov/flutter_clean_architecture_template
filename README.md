# Flutter Clean Architecture Template

A production-ready Flutter application template following Clean Architecture principles with
comprehensive configuration management.

## 🏗️ Architecture

This project follows Clean Architecture with clear separation of concerns:

- **Presentation Layer** - UI components and state management (Cubit/Bloc)
- **Domain Layer** - Business logic and use cases
- **Data Layer** - Data sources and repositories

## ✨ Features

- ✅ Clean Architecture structure
- ✅ Environment-specific configurations (Dev/Staging/Prod)
- ✅ Centralized API configuration
- ✅ HTTP client with retry logic
- ✅ Proper error handling
- ✅ Dependency injection with GetIt
- ✅ State management with flutter_bloc
- ✅ Network connectivity detection
- ✅ Comprehensive logging

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

1. Clone the repository

```bash
git clone https://github.com/kostya-epifanov/flutter_clean_architecture_template.git
cd flutter_clean_architecture_template
```

2. Install dependencies

```bash
flutter pub get
```

3. Run the app

```bash
flutter run
```

## 🔧 Configuration Management

This template includes a robust configuration management system supporting multiple environments.

### Quick Start

#### Run in Development

```bash
./scripts/run_dev.sh
# or
flutter run --dart-define=ENVIRONMENT=development
```

#### Run in Staging

```bash
./scripts/run_staging.sh
# or
flutter run --dart-define=ENVIRONMENT=staging
```

#### Run in Production

```bash
./scripts/run_prod.sh
# or
flutter run --dart-define=ENVIRONMENT=production --dart-define=ENABLE_LOGGING=false
```

### Using VS Code/Cursor

Press `F5` and select from pre-configured launch options:

- Development
- Development (Custom API)
- Staging
- Staging (Custom API)
- Production
- Production (Custom API)

### Environment Configurations

| Environment | API Base URL                   | Logging | Timeout | Max Retries |
|-------------|--------------------------------|---------|---------|-------------|
| Development | https://www.random.org         | ✅       | 30s     | 3           |
| Staging     | https://staging-api.random.org | ✅       | 30s     | 3           |
| Production  | https://www.random.org         | ❌       | 20s     | 2           |

### Custom Configuration

Override settings at runtime:

```bash
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=API_BASE_URL=https://my-api.com \
  --dart-define=ENABLE_LOGGING=true
```

📖 **Full Documentation**: See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for comprehensive
configuration guide.

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/          # Application configuration
│   │   ├── environment.dart
│   │   └── app_config.dart
│   ├── di/              # Dependency injection
│   ├── extensions/      # Dart extensions
│   ├── navigation/      # Navigation setup
│   ├── network/         # HTTP client & error handling
│   ├── std/             # Standard utilities
│   └── ui/              # Common UI components
├── features/
│   ├── common/          # Shared feature components
│   └── [feature_name]/
│       ├── data/        # Data sources & repositories
│       ├── domain/      # Use cases & entities
│       └── presentation/# UI & state management
├── app.dart
└── main.dart
```

## 🛠️ Development

### Adding a New Feature

1. Create feature folder structure:

```
lib/features/my_feature/
├── data/
│   ├── datasources/
│   └── repositories/
├── domain/
│   └── usecases/
└── presentation/
    ├── logic/
    └── ui/
```

2. Implement following Clean Architecture principles
3. Register dependencies in `lib/core/di/service_locator.dart`

### Using Configuration

Always use `AppConfig` for configuration values:

```dart
import 'package:flutter_clean_template/core/config/app_config.dart';

// Get API URL
final url = '${AppConfig.apiBaseUrl}/api/endpoint';

// Check environment
if (
AppConfig.environment.isDevelopment) {
// Development-specific code
}

// Access other configs
final timeout = AppConfig.httpTimeout;
final logging = AppConfig
.
enableLogging;
```

### HTTP Requests

Use the `HttpClient` wrapper for all network requests:

```dart

final result = await
_httpClient.execute<MyModel>
(
method: 'GET',
url: '${AppConfig.apiBaseUrl}/endpoint',
parser: (data) => MyModel.fromJson(data),
query: {'param': 'value'},
);
```

## 🧪 Testing

```bash
flutter test
```

## 📦 Building

### Development Build

```bash
flutter build apk --dart-define=ENVIRONMENT=development
```

### Production Build

```bash
./scripts/build_prod.sh
# or
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ENABLE_LOGGING=false
```

## 📚 Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - Comprehensive configuration management
  documentation

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Clean Architecture by Robert C. Martin
- Flutter community
