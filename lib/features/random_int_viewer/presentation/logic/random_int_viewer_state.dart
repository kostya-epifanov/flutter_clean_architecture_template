part of 'random_int_viewer_cubit.dart';

class RandomIntViewerState extends Equatable {
  final RequestStatus status;
  final NetworkStatus networkStatus;

  /// `null` until the first number is loaded.
  final RandomInt? number;

  final int secondsToRefresh;

  /// Why the last request failed; set only while [status] is [RequestStatus.failure].
  final RandomIntFailure? failure;

  const RandomIntViewerState({
    required this.secondsToRefresh,
    this.status = RequestStatus.initial,
    this.networkStatus = NetworkStatus.unknown,
    this.number,
    this.failure,
  });

  RandomIntViewerState copyWith({
    RequestStatus? status,
    NetworkStatus? networkStatus,
    RandomInt? number,
    int? secondsToRefresh,
    RandomIntFailure? failure,
  }) {
    final newStatus = status ?? this.status;
    return RandomIntViewerState(
      status: newStatus,
      networkStatus: networkStatus ?? this.networkStatus,
      number: number ?? this.number,
      secondsToRefresh: secondsToRefresh ?? this.secondsToRefresh,
      failure: newStatus == RequestStatus.failure ? failure ?? this.failure : null,
    );
  }

  @override
  List<Object?> get props => [status, networkStatus, number, secondsToRefresh, failure];
}
