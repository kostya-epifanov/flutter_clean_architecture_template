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
class RandomIntViewerCubit extends Cubit<RandomIntViewerState> {
  final GetRandomIntUseCase _getRandomIntUseCase;

  late final StreamSubscription<NetworkStatus> _networkSubscription;
  late final Timer _timer;

  RandomIntViewerCubit(
    ListenConnectivityUseCase listenConnectivity,
    this._getRandomIntUseCase,
  ) : super(const RandomIntViewerState()) {
    _networkSubscription = listenConnectivity().listen(
      (status) => emit(state.copyWith(networkStatus: status)),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());
    _loadRandomNumber();
  }

  /// Fetches a new number now; ignored while a request is in flight.
  void onTapGetRandomNumber() => _loadRandomNumber();

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
    _timer.cancel();
    await _networkSubscription.cancel();
    return super.close();
  }
}
