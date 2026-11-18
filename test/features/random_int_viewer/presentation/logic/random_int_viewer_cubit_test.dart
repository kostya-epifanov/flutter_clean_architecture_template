import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/core/ui/request_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

const _failure = Failure<int, RandomIntFailure>(RandomIntFailure.serverError);
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

  /// A started cubit, as the screen gets it.
  RandomIntViewerCubit buildCubit() =>
      RandomIntViewerCubit(watchNetworkStatus, getRandomInt)..start();

  void givenResults(List<Result<int, RandomIntFailure>> results) {
    final queue = List.of(results);
    when(() => getRandomInt())
        .thenAnswer((_) async => queue.length > 1 ? queue.removeAt(0) : queue.single);
  }

  /// The next call to the use case stays in flight until the completer completes.
  ///
  /// Inside `fakeAsync`, call this within the fake zone: a completer delivers
  /// its result through the zone it was created in.
  Completer<Result<int, RandomIntFailure>> givenPendingRequest() {
    final completer = Completer<Result<int, RandomIntFailure>>();
    when(() => getRandomInt()).thenAnswer((_) => completer.future);
    return completer;
  }

  group('start', () {
    test('does nothing until started', () {
      final cubit = RandomIntViewerCubit(watchNetworkStatus, getRandomInt);
      addTearDown(cubit.close);

      expect(cubit.state, RandomIntViewerState(secondsToRefresh: _interval));
      verifyNever(() => getRandomInt());
      verifyNever(() => watchNetworkStatus());
    });

    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'loads the number and starts a full countdown',
      setUp: () => givenResults([const Success(42)]),
      build: () => RandomIntViewerCubit(watchNetworkStatus, getRandomInt),
      act: (cubit) => cubit.start(),
      expect: () => [
        RandomIntViewerState(status: RequestStatus.loading, secondsToRefresh: _interval),
        RandomIntViewerState(
          status: RequestStatus.success,
          number: 42,
          secondsToRefresh: _interval,
        ),
      ],
      verify: (_) => verify(() => getRandomInt()).called(1),
    );

    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'reports the failure and keeps no number on error',
      setUp: () => givenResults([_failure]),
      build: () => RandomIntViewerCubit(watchNetworkStatus, getRandomInt),
      act: (cubit) => cubit.start(),
      expect: () => [
        RandomIntViewerState(status: RequestStatus.loading, secondsToRefresh: _interval),
        RandomIntViewerState(
          status: RequestStatus.failure,
          failure: RandomIntFailure.serverError,
          secondsToRefresh: _interval,
        ),
      ],
    );
  });

  test('a second start does not subscribe, load or tick twice', () {
    givenResults([const Success(1)]);

    fakeAsync((async) {
      final cubit = buildCubit()..start();
      async.flushMicrotasks();

      verify(() => watchNetworkStatus()).called(1);
      verify(() => getRandomInt()).called(1);
      expect(async.periodicTimerCount, 1);

      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.secondsToRefresh, _interval - 1);
      cubit.close();
    });
  });

  test('start after close does nothing', () async {
    final cubit = RandomIntViewerCubit(watchNetworkStatus, getRandomInt);
    await cubit.close();

    cubit.start();

    verifyNever(() => watchNetworkStatus());
    verifyNever(() => getRandomInt());
  });

  group('unexpected errors', () {
    final error = StateError('platform failure');

    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'a throwing request is reported and ends as an unknown failure, not stuck loading',
      setUp: () => when(() => getRandomInt()).thenThrow(error),
      build: () => RandomIntViewerCubit(watchNetworkStatus, getRandomInt),
      act: (cubit) => cubit.start(),
      expect: () => [
        RandomIntViewerState(status: RequestStatus.loading, secondsToRefresh: _interval),
        RandomIntViewerState(
          status: RequestStatus.failure,
          failure: RandomIntFailure.unknown,
          secondsToRefresh: _interval,
        ),
      ],
      errors: () => [error],
    );

    test('the countdown keeps running after a throwing request', () {
      final queue = <Future<Result<int, RandomIntFailure>> Function()>[
        () => Future.error(error),
        () async => const Success(7),
      ];
      when(() => getRandomInt()).thenAnswer((_) => queue.removeAt(0)());

      fakeAsync((async) {
        final cubit = buildCubit();
        async.flushMicrotasks();
        expect(cubit.state.status, RequestStatus.failure);

        async.elapse(Duration(seconds: _interval));
        expect(cubit.state.number, 7);
        cubit.close();
      });
    });

    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'a network status stream error is reported and later statuses still arrive',
      setUp: givenPendingRequest,
      build: () => RandomIntViewerCubit(watchNetworkStatus, getRandomInt),
      act: (cubit) async {
        cubit.start();
        networkStatus.addError(error);
        await pumpEventQueue();
        networkStatus.add(NetworkStatus.connected);
      },
      skip: 1, // loading
      expect: () => [
        RandomIntViewerState(
          status: RequestStatus.loading,
          networkStatus: NetworkStatus.connected,
          secondsToRefresh: _interval,
        ),
      ],
      errors: () => [error],
    );
  });

  test('clears the failure once the next request starts', () {
    givenResults([_failure, const Success(8)]);

    fakeAsync((async) {
      final cubit = buildCubit();
      async.flushMicrotasks();
      expect(cubit.state.failure, RandomIntFailure.serverError);

      cubit.refresh();
      expect(cubit.state.status, RequestStatus.loading);
      expect(cubit.state.failure, isNull);

      async.flushMicrotasks();
      expect(cubit.state.number, 8);
      expect(cubit.state.failure, isNull);
      cubit.close();
    });
  });

  blocTest<RandomIntViewerCubit, RandomIntViewerState>(
    'forwards network status changes',
    setUp: givenPendingRequest,
    build: buildCubit,
    act: (_) async {
      networkStatus.add(NetworkStatus.connected);
      await pumpEventQueue();
      networkStatus.add(NetworkStatus.disconnected);
    },
    expect: () => [
      RandomIntViewerState(
        status: RequestStatus.loading,
        networkStatus: NetworkStatus.connected,
        secondsToRefresh: _interval,
      ),
      RandomIntViewerState(
        status: RequestStatus.loading,
        networkStatus: NetworkStatus.disconnected,
        secondsToRefresh: _interval,
      ),
    ],
  );

  group('timing', () {
    /// Runs [body] in fake time against a fresh cubit and closes it afterwards.
    void runCubit(void Function(FakeAsync async, RandomIntViewerCubit cubit) body) {
      fakeAsync((async) {
        final cubit = buildCubit();
        async.flushMicrotasks(); // settle the initial request
        body(async, cubit);
        cubit.close();
        async.flushMicrotasks();
      });
    }

    test('counts down once per second after a successful load', () {
      givenResults([const Success(5)]);

      runCubit((async, cubit) {
        expect(cubit.state.secondsToRefresh, _interval);

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.secondsToRefresh, _interval - 1);

        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.secondsToRefresh, _interval - 11);
      });
    });

    test('refreshes automatically when the countdown reaches zero', () {
      givenResults([const Success(5), const Success(77)]);

      runCubit((async, cubit) {
        async.elapse(Duration(seconds: _interval - 1));
        expect(cubit.state.secondsToRefresh, 1);
        verify(() => getRandomInt()).called(1);

        async.elapse(const Duration(seconds: 1));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.number, 77);
        expect(cubit.state.secondsToRefresh, _interval);
      });
    });

    test('after a failure waits a full interval before retrying, not one second', () {
      givenResults([_failure]);

      runCubit((async, cubit) {
        expect(cubit.state.status, RequestStatus.failure);
        expect(cubit.state.secondsToRefresh, _interval);

        async.elapse(Duration(seconds: _interval - 1));
        verify(() => getRandomInt()).called(1);

        async.elapse(const Duration(seconds: 1));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.status, RequestStatus.failure);
        expect(cubit.state.secondsToRefresh, _interval);
      });
    });

    test('the first tick after a load comes a full second after the response', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = buildCubit();

        async.elapse(const Duration(milliseconds: 1500));
        request.complete(const Success(3));
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 999));
        expect(cubit.state.secondsToRefresh, _interval);
        async.elapse(const Duration(milliseconds: 1));
        expect(cubit.state.secondsToRefresh, _interval - 1);
        cubit.close();
      });
    });

    test('a manual refresh mid-second restarts the second', () {
      givenResults([const Success(1), const Success(2)]);

      runCubit((async, cubit) {
        async.elapse(const Duration(milliseconds: 1500));
        expect(cubit.state.secondsToRefresh, _interval - 1);

        cubit.refresh();
        async.flushMicrotasks();
        expect(cubit.state.secondsToRefresh, _interval);

        async.elapse(const Duration(milliseconds: 999));
        expect(cubit.state.secondsToRefresh, _interval);
        async.elapse(const Duration(milliseconds: 1));
        expect(cubit.state.secondsToRefresh, _interval - 1);
      });
    });

    test('no timer runs while a request is in flight', () {
      fakeAsync((async) {
        givenPendingRequest();
        final cubit = buildCubit();
        async.flushMicrotasks();

        expect(async.periodicTimerCount, 0);
        cubit.close();
      });
    });

    test('pauses the countdown while a request is in flight', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = buildCubit();

        async.elapse(const Duration(seconds: 5));

        expect(cubit.state.status, RequestStatus.loading);
        expect(cubit.state.secondsToRefresh, _interval);

        request.complete(const Success(3));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.secondsToRefresh, _interval - 1);
        cubit.close();
      });
    });
  });

  group('refresh', () {
    test('loads a new number immediately', () {
      givenResults([const Success(1), const Success(2)]);

      fakeAsync((async) {
        final cubit = buildCubit();
        async.flushMicrotasks();

        cubit.refresh();
        async.flushMicrotasks();

        expect(cubit.state.number, 2);
        verify(() => getRandomInt()).called(2);
        cubit.close();
      });
    });

    test('is ignored while a request is in flight', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = buildCubit();

        cubit
          ..refresh()
          ..refresh();
        async.flushMicrotasks();
        verify(() => getRandomInt()).called(1);

        request.complete(const Success(9));
        async.flushMicrotasks();
        expect(cubit.state.number, 9);
        cubit.close();
      });
    });
  });

  test('refresh after close neither throws nor requests', () async {
    givenResults([const Success(1)]);
    final cubit = buildCubit();
    await pumpEventQueue();
    await cubit.close();

    cubit.refresh();

    verify(() => getRandomInt()).called(1);
  });

  group('pause and resume', () {
    final start = DateTime(2026);

    /// Runs [body] against a cubit whose clock follows fake time.
    void runCubit(void Function(FakeAsync async, RandomIntViewerCubit cubit) body) {
      fakeAsync((async) {
        final cubit = RandomIntViewerCubit(
          watchNetworkStatus,
          getRandomInt,
          now: () => start.add(async.elapsed),
        )..start();
        async.flushMicrotasks(); // settle the initial request
        body(async, cubit);
        cubit.close();
        async.flushMicrotasks();
      });
    }

    test('neither counts down nor refreshes while paused', () {
      givenResults([const Success(5)]);

      runCubit((async, cubit) {
        cubit.pause();
        async.elapse(const Duration(minutes: 5));

        expect(async.periodicTimerCount, 0);
        expect(cubit.state.secondsToRefresh, _interval);
        verify(() => getRandomInt()).called(1);
      });
    });

    test('continues the countdown, minus the paused time, when resumed early', () {
      givenResults([const Success(5), const Success(6)]);

      runCubit((async, cubit) {
        async.elapse(const Duration(seconds: 10));
        cubit.pause();
        async.elapse(const Duration(seconds: 5));
        cubit.resume();

        expect(cubit.state.secondsToRefresh, _interval - 15);
        verify(() => getRandomInt()).called(1);

        async.elapse(Duration(seconds: _interval - 15));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.number, 6);
      });
    });

    test('loads a new number at once when the refresh fell due while paused', () {
      givenResults([const Success(5), const Success(6)]);

      runCubit((async, cubit) {
        cubit.pause();
        async.elapse(Duration(seconds: _interval + 15));
        cubit.resume();
        async.flushMicrotasks();

        verify(() => getRandomInt()).called(2);
        expect(cubit.state.number, 6);
        expect(cubit.state.secondsToRefresh, _interval);
      });
    });

    test('counts the paused time from when a pending request completes', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = RandomIntViewerCubit(
          watchNetworkStatus,
          getRandomInt,
          now: () => start.add(async.elapsed),
        )..start();

        cubit.pause();
        async.elapse(const Duration(seconds: 20));
        request.complete(const Success(3));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        cubit.resume();

        expect(cubit.state.number, 3);
        expect(cubit.state.secondsToRefresh, _interval - 5);
        verify(() => getRandomInt()).called(1);
        cubit.close();
        async.flushMicrotasks();
      });
    });

    test('ignores resume without pause, and a repeated pause', () {
      givenResults([const Success(5)]);

      runCubit((async, cubit) {
        async.elapse(const Duration(seconds: 3));
        cubit.resume();
        expect(cubit.state.secondsToRefresh, _interval - 3);
        expect(async.periodicTimerCount, 1);

        cubit.pause();
        async.elapse(const Duration(seconds: 10));
        cubit.pause(); // must not move the pause start
        cubit.resume();
        expect(cubit.state.secondsToRefresh, _interval - 13);
        expect(async.periodicTimerCount, 1);
      });
    });

    test('pause and resume after close do not throw', () async {
      givenResults([const Success(5)]);
      final cubit = buildCubit();
      await cubit.close();

      cubit
        ..pause()
        ..resume();
    });
  });

  group('close', () {
    test('does not emit or throw when a pending request completes afterwards', () async {
      final request = givenPendingRequest();
      final cubit = buildCubit();
      final states = <RandomIntViewerState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.close();
      request.complete(const Success(42));
      await pumpEventQueue();

      // An emit after close would throw a StateError and fail this test.
      expect(states, isEmpty);
      expect(cubit.state.status, RequestStatus.loading);
    });

    test('stops the countdown timer and the network subscription', () {
      givenResults([const Success(1)]);

      fakeAsync((async) {
        final cubit = buildCubit();
        async.flushMicrotasks();
        expect(networkStatus.hasListener, isTrue);

        cubit.close();
        async.flushMicrotasks();

        expect(networkStatus.hasListener, isFalse);
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
