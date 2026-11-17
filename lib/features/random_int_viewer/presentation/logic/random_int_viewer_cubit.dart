import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_clean_template/core/ui/request_status.dart';
import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:flutter_clean_template/features/common/domain/usecases/listen_connectivity_usecase.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';

part 'random_int_viewer_state.dart';

/// Seconds between automatic refreshes.
const int refreshIntervalSeconds = 30;

/// Loads a random number on start, then refreshes it every
/// [refreshIntervalSeconds] seconds or when the user asks for it.
///
/// The countdown stops while the app is in the background (see [pause] and
/// [resume]): Android cuts network access for background apps, so refreshing
/// there would only replace the number with a locally generated one.
class RandomIntViewerCubit extends Cubit<RandomIntViewerState> {
  final GetRandomIntUseCase _getRandomIntUseCase;
  final DateTime Function() _now;

  late final StreamSubscription<NetworkStatus> _networkSubscription;
  Timer? _timer;

  /// When the countdown was paused; `null` while it is running.
  DateTime? _pausedAt;

  /// [now] defaults to [DateTime.now] and can be replaced in tests.
  RandomIntViewerCubit(
    ListenConnectivityUseCase listenConnectivity,
    this._getRandomIntUseCase, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const RandomIntViewerState()) {
    _networkSubscription = listenConnectivity().listen(
      (status) => emit(state.copyWith(networkStatus: status)),
    );
    _startCountdown();
    _loadRandomNumber();
  }

  /// Fetches a new number now; ignored while a request is in flight.
  void onTapGetRandomNumber() => _loadRandomNumber();

  /// Stops the countdown, e.g. when the app goes to the background.
  void pause() {
    if (_pausedAt != null || isClosed) return;
    _pausedAt = _now();
    _timer?.cancel();
  }

  /// Restarts the countdown after [pause], counting the time spent paused.
  ///
  /// If the next refresh fell due while paused, the number is loaded at once.
  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null || isClosed) return;
    _pausedAt = null;
    _startCountdown();

    if (state.requestStatus == RequestStatus.loading) return;
    final secondsLeft = state.timerCounter - _now().difference(pausedAt).inSeconds;
    if (secondsLeft > 0) {
      emit(state.copyWith(timerCounter: secondsLeft));
    } else {
      _loadRandomNumber();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());
  }

  void _onTimerTick() {
    if (state.requestStatus == RequestStatus.loading) return;

    final secondsLeft = state.timerCounter - 1;
    if (secondsLeft > 0) {
      emit(state.copyWith(timerCounter: secondsLeft));
    } else {
      _loadRandomNumber();
    }
  }

  Future<void> _loadRandomNumber() async {
    if (state.requestStatus == RequestStatus.loading) return;

    emit(state.copyWith(requestStatus: RequestStatus.loading));
    final result = await _getRandomIntUseCase();
    if (isClosed) return;
    // The new countdown starts now, so time spent paused counts from here.
    if (_pausedAt != null) _pausedAt = _now();

    // Whatever the outcome, the next automatic attempt is a full interval
    // away, so a failing backend is not hammered every second.
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        requestStatus: RequestStatus.success,
        number: value,
        timerCounter: refreshIntervalSeconds,
      ),
      Failure() => state.copyWith(
        requestStatus: RequestStatus.failure,
        timerCounter: refreshIntervalSeconds,
      ),
    });
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _networkSubscription.cancel();
    return super.close();
  }
}
