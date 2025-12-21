/// Represents the status of a network request
sealed class RequestStatus {
  const RequestStatus();

  /// Check if request has not started
  bool get isNotStarted => this is NotStarted;

  /// Check if request is in progress
  bool get isInProgress => this is InProgress;

  /// Check if request completed successfully
  bool get isCompleted => this is Completed;

  /// Check if request was cancelled
  bool get isCancelled => this is Cancelled;

  /// Check if request failed
  bool get isFailed => this is Failed;
}

/// Request has not started yet
class NotStarted extends RequestStatus {
  const NotStarted();

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotStarted;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RequestStatus.notStarted()';
}

/// Request is currently in progress
class InProgress extends RequestStatus {
  const InProgress();

  @override
  bool operator ==(Object other) => identical(this, other) || other is InProgress;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RequestStatus.inProgress()';
}

/// Request completed successfully
class Completed extends RequestStatus {
  const Completed();

  @override
  bool operator ==(Object other) => identical(this, other) || other is Completed;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RequestStatus.completed()';
}

/// Request was cancelled
class Cancelled extends RequestStatus {
  const Cancelled();

  @override
  bool operator ==(Object other) => identical(this, other) || other is Cancelled;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RequestStatus.cancelled()';
}

/// Request failed
class Failed extends RequestStatus {
  const Failed();

  @override
  bool operator ==(Object other) => identical(this, other) || other is Failed;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RequestStatus.failed()';
}
