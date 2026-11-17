part of 'random_int_viewer_cubit.dart';

class RandomIntViewerState extends Equatable {
  final RequestStatus requestStatus;

  /// `null` until the first status arrives.
  final NetworkStatus? networkStatus;

  final int number;
  final int timerCounter;

  const RandomIntViewerState({
    this.requestStatus = RequestStatus.initial,
    this.networkStatus,
    this.number = 0,
    this.timerCounter = refreshIntervalSeconds,
  });

  RandomIntViewerState copyWith({
    RequestStatus? requestStatus,
    NetworkStatus? networkStatus,
    int? number,
    int? timerCounter,
  }) {
    return RandomIntViewerState(
      requestStatus: requestStatus ?? this.requestStatus,
      networkStatus: networkStatus ?? this.networkStatus,
      number: number ?? this.number,
      timerCounter: timerCounter ?? this.timerCounter,
    );
  }

  @override
  List<Object?> get props => [
        requestStatus,
        networkStatus,
        number,
        timerCounter,
      ];
}
