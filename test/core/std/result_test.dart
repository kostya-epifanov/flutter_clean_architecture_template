import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    final error = Exception('boom');

    group('fold', () {
      test('calls onSuccess with the value of a Success', () {
        const Result<int> result = Success(42);

        final folded = result.fold(
          onSuccess: (value) => 'value $value',
          onFailure: (error) => 'error $error',
        );

        expect(folded, 'value 42');
      });

      test('calls onFailure with the error of a Failure', () {
        final Result<int> result = Failure(error);

        final folded = result.fold(
          onSuccess: (value) => value,
          onFailure: (e) => identical(e, error) ? -1 : -2,
        );

        expect(folded, -1);
      });
    });

    test('isSuccess / isFailure reflect the variant', () {
      expect(const Success(1).isSuccess, isTrue);
      expect(const Success(1).isFailure, isFalse);
      expect(Failure<int>(error).isSuccess, isFalse);
      expect(Failure<int>(error).isFailure, isTrue);
    });

    group('equality', () {
      test('Success values are equal when their values are equal', () {
        expect(const Success(1), const Success(1));
        expect(const Success(1).hashCode, const Success(1).hashCode);
        expect(const Success(1), isNot(const Success(2)));
      });

      test('Failures are equal when their errors are equal, ignoring the stack trace', () {
        expect(Failure<int>(error, StackTrace.current), Failure<int>(error));
        expect(Failure<int>(error).hashCode, Failure<int>(error).hashCode);
        expect(Failure<int>(error), isNot(Failure<int>(Exception('other'))));
      });

      test('a Success never equals a Failure', () {
        expect(Success<Object>(error), isNot(Failure<Object>(error)));
      });
    });
  });
}
