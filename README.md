# Flutter Clean Architecture Demo

A small Flutter app built to show how I structure a production codebase: layered
Clean Architecture, dependency injection, Cubit state management, typed error handling,
environment configuration and a test suite that covers every layer.

**What the app does.** It shows a random number from [random.org](https://www.random.org),
refreshes it every 30 seconds (or on tap) and displays the live network status. When the
device is offline or the API host cannot be reached, the number is generated locally, so the
screen keeps working. The countdown pauses while the app is in the background.

## Architecture

```
presentation ──▶ domain ◀── data
 Cubit, widgets   use cases,     repository implementations,
                  entities,      data sources, HTTP
                  repository
                  contracts
```

- **Domain** is plain Dart: use cases, entities (`NetworkStatus`, `RandomIntRange`) and
  repository contracts (`IRandomIntRepository`, `IConnectivityRepository`). It imports
  nothing from `data/` or `presentation/` and no third-party packages.
- **Data** implements the contracts. `connectivity_plus` and Dio never leave this layer.
- **Presentation** talks to the domain only through use cases.
- **`core/di/locator.dart`** is the single composition root that wires everything with GetIt.

Request flow when a number is loaded:

```
RandomIntViewerScreen
  └─ RandomIntViewerCubit
       └─ GetRandomIntUseCase ─────────────── returns Result<int>
            └─ IRandomIntRepository
                 ├─ online  → RandomIntRemoteDataSource → HttpClient (Dio)
                 └─ offline → RandomIntLocalDataSource
```

### Key decisions

| Decision | Why |
|---|---|
| **Cubit** (flutter_bloc) | The screen has a couple of intents; events would add ceremony without value. |
| **GetIt** + `InjectableState` | One place for wiring; the screen resolves its cubit and `BlocProvider` owns its lifecycle. |
| **`Result<T>` sealed type** | Use cases never throw; the cubit handles `Success`/`Failure` with an exhaustive `switch`. |
| **`HttpClient` wrapper over Dio** | Retries 5xx with linear backoff and a slow server (read timeout) only once, fails fast when the host is unreachable and maps `DioException` to typed `NetworkException`s. |
| **Fallback only when the host is unreachable** | No network, DNS failure or connect timeout → local number. A server that answers with an error, garbage or too slowly is shown as an error instead of being masked. |
| **Lifecycle-aware countdown** | Android cuts network access for background apps, so the cubit pauses while the app is hidden and catches up on return. |
| **`NetworkStatus` domain entity** | Keeps `ConnectivityResult` out of domain/UI; the stream emits the current status first, then changes. |
| **Compile-time environments** | `--dart-define` selects dev/staging/prod without flavors or extra files. |

## Getting started

Requirements: Flutter **3.50+** (Dart 3.14).

```bash
flutter pub get
flutter run            # development environment by default
```

## Configuration

The environment is chosen at compile time:

```bash
flutter run --dart-define=ENVIRONMENT=staging      # development | staging | production
```

| Environment | Logging | HTTP timeout | Retries (5xx) | Retries (timeout) |
|---|---|---|---|---|
| development | on  | 30 s | 3 | 1 |
| staging     | on  | 30 s | 3 | 1 |
| production  | off | 20 s | 2 | 1 |

The connect timeout is 10 s in every environment and is never retried: the app falls back to
a local number instead.

random.org has no staging host, so every environment uses `https://www.random.org`; in a real
project staging would point at its own backend. Individual values can be overridden:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=ENABLE_LOGGING=true
```

`.vscode/launch.json` contains a launch configuration for each environment.
All values live in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart).

## Testing

```bash
flutter test
flutter test --coverage    # writes coverage/lcov.info
```

The suite runs in a few seconds, without network access, platform channels or wall-clock waits.

| Layer | What is covered | Tools |
|---|---|---|
| core | `Result`; `HttpClient` retries, backoff, error mapping, parsing | in-memory Dio `HttpClientAdapter`, `fake_async` |
| data / domain | connectivity mapping and stream, repository online/offline choice, data sources, use cases | `mocktail` |
| presentation | cubit countdown, auto-refresh, failure back-off, ignored taps while loading, pause/resume, close safety | `bloc_test`, `fake_async` |
| widget | number, countdown, network label, tap to refresh, error SnackBar, background pause, safe area, large fonts, status bar style | `flutter_test`, GetIt with mocked use cases |

Line coverage of `lib/` is about 78%; DI wiring and config variants are the main gaps.

## Project structure

```
lib/
├── core/
│   ├── config/        # environments and AppConfig
│   ├── di/            # GetIt composition root
│   ├── network/       # HttpClient (Dio), interceptor, NetworkException hierarchy
│   ├── std/           # Result<T>
│   └── ui/            # InjectableState, DependentStatelessWidget, RequestStatus
├── features/
│   ├── common/                      # connectivity, shared by features
│   │   ├── data/
│   │   └── domain/   (entities, repositories, usecases)
│   └── random_int_viewer/
│       ├── data/     (datasources, repositories)
│       ├── domain/   (entities, repositories, usecases)
│       └── presentation/ (logic: cubit + state, ui: screen + widgets)
├── app.dart
└── main.dart
test/                  # mirrors lib/
```

## License

[MIT](LICENSE)
