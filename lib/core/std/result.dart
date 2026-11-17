/// Outcome of an operation that either succeeds with a [T] value
/// or fails with an [Exception].
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Exception error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T> extends Result<T> {
  final Exception error;
  final StackTrace? stackTrace;

  const Failure(this.error, [this.stackTrace]);

  @override
  bool operator ==(Object other) => other is Failure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
