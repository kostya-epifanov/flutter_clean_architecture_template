import 'dart:async';

import 'package:flutter_clean_template/core/di/locator.dart';
import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/ui/random_int_viewer_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

/// Longer than the counter animation, so the final number is on screen.
const _counterAnimation = Duration(milliseconds: 700);
const _snackBarText = 'Could not get a new number. Will retry shortly.';

void main() {
  late MockListenConnectivityUseCase listenConnectivity;
  late MockGetRandomIntUseCase getRandomInt;
  late StreamController<NetworkStatus> networkStatus;

  setUp(() {
    listenConnectivity = MockListenConnectivityUseCase();
    getRandomInt = MockGetRandomIntUseCase();
    networkStatus = StreamController<NetworkStatus>.broadcast();
    when(() => listenConnectivity()).thenAnswer((_) => networkStatus.stream);

    // The screen resolves its cubit from the service locator.
    locator.registerFactory(() => RandomIntViewerCubit(listenConnectivity, getRandomInt));
  });

  tearDown(() async {
    await locator.reset();
    await networkStatus.close();
  });

  void givenResults(List<Result<int>> results) {
    final queue = List.of(results);
    when(() => getRandomInt())
        .thenAnswer((_) async => queue.length > 1 ? queue.removeAt(0) : queue.single);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RandomIntViewerScreen()));
  }

  /// Rebuilds with the latest state, then lets the counter finish animating.
  Future<void> settleNumber(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_counterAnimation);
  }

  testWidgets('shows the loaded number and the refresh countdown', (tester) async {
    givenResults([const Success(42)]);

    await pumpScreen(tester);
    await settleNumber(tester);

    expect(find.text('42'), findsOneWidget);
    expect(find.text('[$refreshIntervalSeconds]'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('[${refreshIntervalSeconds - 1}]'), findsOneWidget);
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    final request = Completer<Result<int>>();
    when(() => getRandomInt()).thenAnswer((_) => request.future);

    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    request.complete(const Success(5));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
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

  testWidgets('shows a SnackBar when loading fails', (tester) async {
    givenResults([const Failure(NoInternetException())]);

    await pumpScreen(tester);
    await tester.pump(); // deliver the failure
    await tester.pump(); // build the SnackBar

    expect(find.text(_snackBarText), findsOneWidget);
    expect(find.text('0'), findsOneWidget, reason: 'no number has been loaded yet');
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
      givenResults([const Failure(NoInternetException())]);

      await pumpScreen(tester);
      await tester.pump(); // deliver the failure
      await tester.pumpAndSettle(); // finish the SnackBar entrance

      final snackBar = tester.getRect(find.byType(SnackBar));
      final button = tester.getRect(find.text('GET RANDOM NUMBER'));
      expect(snackBar.overlaps(button), isFalse);
    });
  });
}
