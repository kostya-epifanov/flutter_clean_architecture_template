import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_clean_template/core/ui/request_status.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_clean_template/features/random_int_viewer/presentation/logic/random_int_viewer_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

const _failure = Failure<int>(NoInternetException());

void main() {
  late MockListenConnectivityUseCase listenConnectivity;
  late MockGetRandomIntUseCase getRandomInt;
  late StreamController<NetworkStatus> networkStatus;

  setUp(() {
    listenConnectivity = MockListenConnectivityUseCase();
    getRandomInt = MockGetRandomIntUseCase();
    networkStatus = StreamController<NetworkStatus>.broadcast();
    when(() => listenConnectivity()).thenAnswer((_) => networkStatus.stream);
  });

  tearDown(() => networkStatus.close());

  RandomIntViewerCubit buildCubit() => RandomIntViewerCubit(listenConnectivity, getRandomInt);

  void givenResults(List<Result<int>> results) {
    final queue = List.of(results);
    when(() => getRandomInt())
        .thenAnswer((_) async => queue.length > 1 ? queue.removeAt(0) : queue.single);
  }

  /// The next call to the use case stays in flight until the completer completes.
  ///
  /// Inside `fakeAsync`, call this within the fake zone: a completer delivers
  /// its result through the zone it was created in.
  Completer<Result<int>> givenPendingRequest() {
    final completer = Completer<Result<int>>();
    when(() => getRandomInt()).thenAnswer((_) => completer.future);
    return completer;
  }

  group('initial load', () {
    // The constructor emits `loading` synchronously, before bloc_test subscribes,
    // so the recorded states start with the outcome of the first request.
    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'emits the number and a full countdown on success',
      setUp: () => givenResults([const Success(42)]),
      build: buildCubit,
      expect: () => const [
        RandomIntViewerState(
          requestStatus: RequestStatus.success,
          number: 42,
          timerCounter: refreshIntervalSeconds,
        ),
      ],
      verify: (_) => verify(() => getRandomInt()).called(1),
    );

    blocTest<RandomIntViewerCubit, RandomIntViewerState>(
      'emits failure and keeps the previous number on error',
      setUp: () => givenResults([_failure]),
      build: buildCubit,
      expect: () => const [
        RandomIntViewerState(
          requestStatus: RequestStatus.failure,
          timerCounter: refreshIntervalSeconds,
        ),
      ],
    );

    test('starts in the loading state', () {
      givenPendingRequest();

      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state.requestStatus, RequestStatus.loading);
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
    expect: () => const [
      RandomIntViewerState(
        requestStatus: RequestStatus.loading,
        networkStatus: NetworkStatus.connected,
      ),
      RandomIntViewerState(
        requestStatus: RequestStatus.loading,
        networkStatus: NetworkStatus.disconnected,
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
        expect(cubit.state.timerCounter, refreshIntervalSeconds);

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 1);

        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 11);
      });
    });

    test('refreshes automatically when the countdown reaches zero', () {
      givenResults([const Success(5), const Success(77)]);

      runCubit((async, cubit) {
        async.elapse(const Duration(seconds: refreshIntervalSeconds - 1));
        expect(cubit.state.timerCounter, 1);
        verify(() => getRandomInt()).called(1);

        async.elapse(const Duration(seconds: 1));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.number, 77);
        expect(cubit.state.timerCounter, refreshIntervalSeconds);
      });
    });

    test('after a failure waits a full interval before retrying, not one second', () {
      givenResults([_failure]);

      runCubit((async, cubit) {
        expect(cubit.state.requestStatus, RequestStatus.failure);
        expect(cubit.state.timerCounter, refreshIntervalSeconds);

        async.elapse(const Duration(seconds: refreshIntervalSeconds - 1));
        verify(() => getRandomInt()).called(1);

        async.elapse(const Duration(seconds: 1));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.requestStatus, RequestStatus.failure);
        expect(cubit.state.timerCounter, refreshIntervalSeconds);
      });
    });

    test('pauses the countdown while a request is in flight', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = buildCubit();

        async.elapse(const Duration(seconds: 5));

        expect(cubit.state.requestStatus, RequestStatus.loading);
        expect(cubit.state.timerCounter, refreshIntervalSeconds);

        request.complete(const Success(3));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 1);
        cubit.close();
      });
    });
  });

  group('onTapGetRandomNumber', () {
    test('loads a new number immediately', () {
      givenResults([const Success(1), const Success(2)]);

      fakeAsync((async) {
        final cubit = buildCubit();
        async.flushMicrotasks();

        cubit.onTapGetRandomNumber();
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
          ..onTapGetRandomNumber()
          ..onTapGetRandomNumber();
        async.flushMicrotasks();
        verify(() => getRandomInt()).called(1);

        request.complete(const Success(9));
        async.flushMicrotasks();
        expect(cubit.state.number, 9);
        cubit.close();
      });
    });
  });

  group('pause and resume', () {
    final start = DateTime(2026);

    /// Runs [body] against a cubit whose clock follows fake time.
    void runCubit(void Function(FakeAsync async, RandomIntViewerCubit cubit) body) {
      fakeAsync((async) {
        final cubit = RandomIntViewerCubit(
          listenConnectivity,
          getRandomInt,
          now: () => start.add(async.elapsed),
        );
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
        expect(cubit.state.timerCounter, refreshIntervalSeconds);
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

        expect(cubit.state.timerCounter, refreshIntervalSeconds - 15);
        verify(() => getRandomInt()).called(1);

        async.elapse(const Duration(seconds: refreshIntervalSeconds - 15));
        verify(() => getRandomInt()).called(1);
        expect(cubit.state.number, 6);
      });
    });

    test('loads a new number at once when the refresh fell due while paused', () {
      givenResults([const Success(5), const Success(6)]);

      runCubit((async, cubit) {
        cubit.pause();
        async.elapse(const Duration(seconds: refreshIntervalSeconds + 15));
        cubit.resume();
        async.flushMicrotasks();

        verify(() => getRandomInt()).called(2);
        expect(cubit.state.number, 6);
        expect(cubit.state.timerCounter, refreshIntervalSeconds);
      });
    });

    test('counts the paused time from when a pending request completes', () {
      fakeAsync((async) {
        final request = givenPendingRequest();
        final cubit = RandomIntViewerCubit(
          listenConnectivity,
          getRandomInt,
          now: () => start.add(async.elapsed),
        );

        cubit.pause();
        async.elapse(const Duration(seconds: 20));
        request.complete(const Success(3));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        cubit.resume();

        expect(cubit.state.number, 3);
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 5);
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
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 3);
        expect(async.periodicTimerCount, 1);

        cubit.pause();
        async.elapse(const Duration(seconds: 10));
        cubit.pause(); // must not move the pause start
        cubit.resume();
        expect(cubit.state.timerCounter, refreshIntervalSeconds - 13);
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
      expect(cubit.state.requestStatus, RequestStatus.loading);
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
