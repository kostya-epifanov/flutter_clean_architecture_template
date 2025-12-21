import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_clean_template/core/network/http/request_status.dart';
import 'package:flutter_clean_template/features/common/domain/listen_connectivity_usecase.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';

part 'random_int_viewer_state.dart';

const int _timerDuration = 30;

class RandomIntViewerCubit extends Cubit<RandomIntViewerState> {
  final ListenConnectivityUseCase _listenConnectivityUsecase;
  final GetRandomIntUseCase _getRandomIntUseCase;

  late Timer _timer;

  final List<StreamSubscription> _subscriptions = [];

  RandomIntViewerCubit(
    this._listenConnectivityUsecase,
    this._getRandomIntUseCase,
  ) : super(const RandomIntViewerState()) {
    _subscriptions.add(_listenConnectivityUsecase()
        .listen((event) => emit(state.copyWith(connectivityState: event))));

    _loadRandomNumber();

    _timer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (timer) => _onTimerTick(),
    );
  }

  @override
  Future<void> close() {
    _timer.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }

  Future<void> _onTimerTick() async {
    emit(state.copyWith(timerCounter: state.timerCounter - 1));
    if (state.timerCounter <= 0) {
      _loadRandomNumber();
    }
  }

  Future<void> _loadRandomNumber() async {
    emit(state.copyWith(requestStatus: const InProgress()));
    final result = await _getRandomIntUseCase();
    if (result.isError) {
      emit(state.copyWith(
        requestStatus: const Failed(),
        number: -1,
      ));
      return;
    }
    emit(state.copyWith(
      requestStatus: const Completed(),
      number: result.successResult,
      timerCounter: _timerDuration,
    ));
  }

  Future<void> onTapGetRandomNumber() async {
    _loadRandomNumber();
  }
}
