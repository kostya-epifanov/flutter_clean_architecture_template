import 'dart:async';

import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/core/theme/app_theme.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/ui/random_int_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

/// Longer than the counter animation, so the final number is on screen.
const _counterAnimation = Duration(milliseconds: 700);
const _failure = Failure<int, RandomIntFailure>(RandomIntFailure.timeout);
const _failureText = 'The server is not responding. Will retry shortly.';
final _interval = RandomIntViewerCubit.defaultRefreshInterval.inSeconds;

void main() {
  late MockWatchNetworkStatusUseCase watchNetworkStatus;
  late MockGetRandomIntUseCase getRandomInt;
  late StreamController<NetworkStatus> networkStatus;

  setUp(() {
    watchNetworkStatus = MockWatchNetworkStatusUseCase();
    getRandomInt = MockGetRandomIntUseCase();
    networkStatus = StreamController<NetworkStatus>.broadcast();
    when(() => watchNetworkStatus()).thenAnswer((_) => networkStatus.stream);
  });

  tearDown(() => networkStatus.close());

  void givenResults(List<Result<int, RandomIntFailure>> results) {
    final queue = List.of(results);
    when(() => getRandomInt())
        .thenAnswer((_) async => queue.length > 1 ? queue.removeAt(0) : queue.single);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider(
          create: (_) => RandomIntViewerCubit(watchNetworkStatus, getRandomInt)..start(),
          child: const RandomIntViewerScreen(),
        ),
      ),
    );
  }

  /// Rebuilds with the latest state, then lets the counter finish animating.
  Future<void> settleNumber(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_counterAnimation);
  }

  TextButton button(WidgetTester tester) => tester.widget<TextButton>(find.byType(TextButton));

  testWidgets('shows the loaded number and the refresh countdown', (tester) async {
    givenResults([const Success(42)]);

    await pumpScreen(tester);
    await settleNumber(tester);

    expect(find.text('42'), findsOneWidget);
    expect(find.text('[$_interval]'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('[${_interval - 1}]'), findsOneWidget);
  });

  testWidgets('shows a placeholder and a disabled button while the first number loads', (
    tester,
  ) async {
    final request = Completer<Result<int, RandomIntFailure>>();
    when(() => getRandomInt()).thenAnswer((_) => request.future);

    await pumpScreen(tester);

    expect(find.text('–'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(button(tester).onPressed, isNull);

    request.complete(const Success(5));
    await settleNumber(tester);
    expect(find.text('5'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(button(tester).onPressed, isNotNull);
  });

  testWidgets('connectivity label goes from CHECKING to the reported status', (tester) async {
    givenResults([const Success(1)]);

    await pumpScreen(tester);
    expect(find.text('CHECKING'), findsOneWidget);

    networkStatus.add(NetworkStatus.connected);
    await tester.pump();
    expect(find.text('CONNECTED'), findsOneWidget);

    networkStatus.add(NetworkStatus.disconnected);
    await tester.pump();
    expect(find.text('DISCONNECTED'), findsOneWidget);
    expect(find.text('CONNECTED'), findsNothing);
  });

  testWidgets('tapping the button loads a new number', (tester) async {
    givenResults([const Success(10), const Success(20)]);

    await pumpScreen(tester);
    await settleNumber(tester);
    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.text('GET RANDOM NUMBER'));
    await settleNumber(tester);

    verify(() => getRandomInt()).called(2);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('explains the failure in a SnackBar and keeps the placeholder', (tester) async {
    givenResults([_failure]);

    await pumpScreen(tester);
    await tester.pump(); // deliver the failure
    await tester.pump(); // build the SnackBar

    expect(find.text(_failureText), findsOneWidget);
    expect(find.text('–'), findsOneWidget, reason: 'no number has been loaded yet');
  });

  testWidgets('asks for light status bar icons on the dark background', (tester) async {
    givenResults([const Success(1)]);

    await pumpScreen(tester);
    await tester.pump();

    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
  });

  testWidgets('stops refreshing while the app is hidden and resumes when shown', (tester) async {
    givenResults([const Success(1), const Success(2)]);
    await pumpScreen(tester);
    await settleNumber(tester);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(Duration(seconds: _interval + 5));
    verify(() => getRandomInt()).called(1);
    expect(find.text('[$_interval]'), findsOneWidget);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('[${_interval - 1}]'), findsOneWidget);
  });

  group('bottom bar', () {
    const gestureInset = 48.0;

    testWidgets('stays above the system gesture area', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: gestureInset * 3); // physical px, dpr 3
      tester.view.viewPadding = const FakeViewPadding(bottom: gestureInset * 3);
      addTearDown(tester.view.reset);
      givenResults([const Success(1)]);

      await pumpScreen(tester);
      await settleNumber(tester);

      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      for (final label in ['CHECKING', 'GET RANDOM NUMBER']) {
        expect(
          tester.getRect(find.text(label)).bottom,
          lessThanOrEqualTo(screenHeight - gestureInset),
          reason: '$label must not overlap the gesture area',
        );
      }
    });

    testWidgets('is not covered by the error SnackBar', (tester) async {
      givenResults([_failure]);

      await pumpScreen(tester);
      await tester.pump(); // deliver the failure
      await tester.pumpAndSettle(); // finish the SnackBar entrance

      final snackBar = tester.getRect(find.byType(SnackBar));
      final button = tester.getRect(find.text('GET RANDOM NUMBER'));
      expect(snackBar.overlaps(button), isFalse);
    });

    // Android 14+ lets users scale fonts up to 200%.
    for (final scale in [1.6, 2.0]) {
      testWidgets('does not overflow on a narrow phone at ${scale}x font size', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920); // 360 x 640 logical at dpr 3
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        givenResults([const Success(1)]);

        await pumpScreen(tester);
        networkStatus.add(NetworkStatus.disconnected); // the longest label
        await settleNumber(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('DISCONNECTED'), findsOneWidget);
        expect(find.text('GET RANDOM NUMBER'), findsOneWidget);
      });
    }
  });
}
