import 'dart:async';

import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/core/ui/request_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:clean_architecture_demo/features/connectivity/domain/usecases/watch_network_status_usecase.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'random_int_viewer_state.dart';

/// Shows a random number and refreshes it every [refreshInterval] or on [refresh].
///
/// The countdown stops while the app is in the background ([pause], [resume]): Android cuts
/// network access for background apps, so a refresh there would only produce a local number.
class RandomIntViewerCubit extends Cubit<RandomIntViewerState> {
  static const defaultRefreshInterval = Duration(seconds: 30);

  final WatchNetworkStatusUseCase _watchNetworkStatus;
  final GetRandomIntUseCase _getRandomInt;
  final Duration refreshInterval;
  final DateTime Function() _now;

  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _timer;

  /// When the countdown was paused; `null` while it runs.
  DateTime? _pausedAt;

  /// [now] is the clock used to measure pauses; tests replace it.
  RandomIntViewerCubit(
    this._watchNetworkStatus,
    this._getRandomInt, {
    this.refreshInterval = defaultRefreshInterval,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(RandomIntViewerState(secondsToRefresh: refreshInterval.inSeconds));

  /// Starts watching the network, the countdown and the first load. Call once.
  void start() {
    assert(_networkSubscription == null, 'start() called twice');
    _networkSubscription = _watchNetworkStatus().listen(
      (status) => emit(state.copyWith(networkStatus: status)),
    );
    _startCountdown();
    _load();
  }

  /// Loads a new number now; ignored while a request is in flight.
  void refresh() => _load();

  void pause() {
    if (_pausedAt != null || isClosed) return;
    _pausedAt = _now();
    _timer?.cancel();
  }

  /// Continues the countdown minus the time spent paused, or loads at once if the refresh
  /// fell due meanwhile.
  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null || isClosed) return;
    _pausedAt = null;
    _startCountdown();

    if (state.status == RequestStatus.loading) return;
    final secondsLeft = state.secondsToRefresh - _now().difference(pausedAt).inSeconds;
    if (secondsLeft > 0) {
      emit(state.copyWith(secondsToRefresh: secondsLeft));
    } else {
      _load();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (state.status == RequestStatus.loading) return;

    final secondsLeft = state.secondsToRefresh - 1;
    if (secondsLeft > 0) {
      emit(state.copyWith(secondsToRefresh: secondsLeft));
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (state.status == RequestStatus.loading) return;

    emit(state.copyWith(status: RequestStatus.loading));
    final result = await _getRandomInt();
    if (isClosed) return;
    // The new countdown starts now, so a pause that began during the request counts from here.
    if (_pausedAt != null) _pausedAt = _now();

    // A full interval follows a failure too, so a failing server is not hit every second.
    final secondsToRefresh = refreshInterval.inSeconds;
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: RequestStatus.success,
        number: value,
        secondsToRefresh: secondsToRefresh,
      ),
      Failure(:final error) => state.copyWith(
        status: RequestStatus.failure,
        failure: error,
        secondsToRefresh: secondsToRefresh,
      ),
    });
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _networkSubscription?.cancel();
    return super.close();
  }
}
