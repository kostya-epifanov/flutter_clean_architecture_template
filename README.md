# Flutter Clean Architecture Demo

A small Flutter app I use to show how I structure a production codebase: layered Clean
Architecture, a composition root with GetIt, Cubit, typed errors from transport to UI,
per-environment configuration and tests for every layer.

<img src="docs/screenshot.png" alt="The app showing a random number" width="280">

The app shows a random number from [random.org](https://www.random.org), refreshes it every
30 seconds or on tap, and shows the network status. When the API host cannot be reached, the
number is generated on the device so the screen keeps working.

## Architecture

```
presentation ──▶ domain ◀── data
 Cubit, widgets   use cases,     repository implementations,
                  entities,      data sources, ApiClient (Dio)
                  failures,
                  repository interfaces
```

- **Domain** is plain Dart. It defines what can go wrong (`RandomIntFailure`) and returns
  `Result<int, RandomIntFailure>`, so no Dio or `connectivity_plus` type reaches the UI.
- **Data** implements the domain interfaces. Data sources throw `NetworkException`s; the
  repository decides what each one means: fall back to a local number or report a failure.
- **Presentation** depends on use cases only. The screen gets its cubit from a `BlocProvider`
  and knows nothing about GetIt.
- **`lib/injection.dart`** is the composition root and the only file that sees concrete classes.

```
RandomIntViewerScreen
  └─ RandomIntViewerCubit
       └─ GetRandomIntUseCase
            └─ RandomIntRepository ─────── Result<int, RandomIntFailure>
                 ├─ host reachable   → RandomIntRemoteDataSource → ApiClient → Dio
                 └─ host unreachable → RandomIntLocalDataSource
```

### Decisions

| Decision | Why |
|---|---|
| **Cubit** | The screen has two intents (refresh, pause/resume); events would be ceremony. |
| **`start()` instead of work in the constructor** | Creating a cubit has no side effects, so tests and DI can build it freely. |
| **Domain failures, not exceptions** | `RandomIntFailure` is an enum the UI switches over exhaustively to pick a message. Anything thrown anyway (a bug, a platform error) is reported to the `BlocObserver` and shown as a generic failure, so the screen never stays stuck loading. |
| **Fall back only when the host is unreachable** | No network, DNS failure or connect timeout gives a local number. A server that answers with an error, garbage or too slowly is reported instead of masked. |
| **Retries in `ApiClient`** | 5xx is retried with linear backoff, a slow server only once, an unreachable host never. Only idempotent methods are retried. |
| **The countdown timer runs only while the countdown is shown** | It stops during a request and in the background and restarts after, so every second on screen is a full second. |
| **Countdown pauses in the background** | Android cuts network access for background apps, so a refresh there would only produce a local number. |
| **`AppConfig` is an object** | Built once from `--dart-define`s in `main` and passed to the composition root, so config is testable and nothing reads globals. |

### Trade-offs

- **Thin use cases.** `GetRandomIntUseCase` and `WatchNetworkStatusUseCase` only delegate.
  I keep them so the presentation layer has one consistent entry point; in a codebase where
  most use cases stay this thin I would let cubits call repositories directly.
- **No interfaces for data sources.** They are internal to the data layer and mocktail mocks
  concrete classes, so an interface would only add a file. Interfaces exist where the
  dependency rule needs them: at the domain boundary.
- **GetIt as a service locator** is used only in the composition root and in `App`. Widgets
  and cubits receive their dependencies through constructors and `BlocProvider`.

### What I would add next

Routing (go_router) once there is a second screen, a local cache so the last number
survives restarts, localization, and flavors if the environments needed different app ids.

## Getting started

Requirements: Flutter **3.50+** (Dart 3.14).

```bash
flutter pub get
flutter run                                   # development
flutter run --dart-define=ENVIRONMENT=staging # development | staging | production
```

| Environment | Logging | Request timeout | Retries (5xx) | Retries (timeout) |
|---|---|---|---|---|
| development, staging | on  | 30 s | 3 | 1 |
| production           | off | 20 s | 2 | 1 |

The connect timeout is 10 s everywhere and is never retried. random.org has no staging host,
so every environment uses `https://www.random.org`. Single values can be overridden:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=ENABLE_LOGGING=true
```

`.vscode/launch.json` has a launch configuration per environment.

## Testing

```bash
flutter test
```

The suite needs no network, platform channels or real waiting: time is faked with
`fake_async` and HTTP is served by an in-memory Dio adapter.

| Layer | Covered |
|---|---|
| core | `ApiClient` retries, backoff, idempotency, error mapping; `AppConfig` per environment; `Result` |
| data | connectivity mapping and stream; repository fallback and exception → failure mapping; data sources |
| presentation | cubit countdown and its timing, refresh, failure back-off, pause/resume, unexpected errors, repeated `start()`, calls after `close()` |
| widgets | number and placeholder, countdown, network label, disabled button, failure SnackBar, background pause, safe area, large fonts, status bar |
| DI | the whole graph resolves |

Line coverage of `lib/` is about 93%. CI runs `dart format`, `flutter analyze --fatal-infos` and the tests on every push.

## Project structure

```
lib/
├── core/
│   ├── config/        # Environment, AppConfig
│   ├── logging/       # AppBlocObserver
│   ├── network/       # ApiClient, NetworkException
│   ├── theme/
│   ├── ui/            # RequestStatus
│   └── result.dart
├── features/
│   ├── connectivity/
│   │   ├── data/      # ConnectivityRepositoryImpl (connectivity_plus)
│   │   └── domain/    # NetworkStatus, ConnectivityRepository, WatchNetworkStatusUseCase
│   └── random_int_viewer/
│       ├── data/      # remote and local data sources, repository implementation
│       ├── domain/    # RandomIntRange, RandomIntFailure, repository, use case
│       └── presentation/
├── injection.dart     # composition root
├── app.dart
└── main.dart
test/                  # mirrors lib/
```

## License

[MIT](LICENSE)
