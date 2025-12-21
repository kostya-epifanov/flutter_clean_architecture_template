part of 'random_int_viewer_cubit.dart';

class RandomIntViewerState extends Equatable {
  final RequestStatus requestStatus;
  final ConnectivityResult connectivityState;
  final int number;
  final int timerCounter;

  const RandomIntViewerState({
    this.requestStatus = const NotStarted(),
    this.connectivityState = ConnectivityResult.none,
    this.number = 0,
    this.timerCounter = _timerDuration,
  });

  RandomIntViewerState copyWith({
    RequestStatus? requestStatus,
    ConnectivityResult? connectivityState,
    int? number,
    int? timerCounter,
  }) {
    return RandomIntViewerState(
      requestStatus: requestStatus ?? this.requestStatus,
      connectivityState: connectivityState ?? this.connectivityState,
      number: number ?? this.number,
      timerCounter: timerCounter ?? this.timerCounter,
    );
  }

  @override
  List<Object> get props => [
        requestStatus,
        connectivityState,
        number,
        timerCounter,
      ];
}
