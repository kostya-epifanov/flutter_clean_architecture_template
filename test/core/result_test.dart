import 'package:clean_architecture_demo/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result equality', () {
    test('Successes are equal when their values are equal', () {
      expect(const Success<int, String>(1), const Success<int, String>(1));
      expect(const Success<int, String>(1).hashCode, const Success<int, String>(1).hashCode);
      expect(const Success<int, String>(1), isNot(const Success<int, String>(2)));
    });

    test('Failures are equal when their errors are equal', () {
      expect(const Failure<int, String>('a'), const Failure<int, String>('a'));
      expect(const Failure<int, String>('a').hashCode, const Failure<int, String>('a').hashCode);
      expect(const Failure<int, String>('a'), isNot(const Failure<int, String>('b')));
    });

    test('a Success never equals a Failure', () {
      expect(const Success<String, String>('x'), isNot(const Failure<String, String>('x')));
    });
  });
}
