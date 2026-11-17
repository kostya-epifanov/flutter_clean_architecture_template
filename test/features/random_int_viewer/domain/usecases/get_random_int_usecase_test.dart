import 'package:flutter_clean_template/core/network/exceptions/network_exception.dart';
import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_clean_template/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockRandomIntRepository repository;
  late GetRandomIntUseCase useCase;

  setUp(() {
    repository = MockRandomIntRepository();
    useCase = GetRandomIntUseCase(repository);
  });

  group('GetRandomIntUseCase', () {
    test('wraps the repository value in a Success', () async {
      when(() => repository.getRandomInt()).thenAnswer((_) async => 42);

      expect(await useCase(), const Success(42));
    });

    test('wraps a thrown Exception in a Failure with its stack trace', () async {
      const error = RequestTimeoutException();
      when(() => repository.getRandomInt()).thenThrow(error);

      final result = await useCase();

      expect(result, const Failure<int>(error));
      expect((result as Failure<int>).stackTrace, isNotNull);
    });

    test('does not swallow Errors (programming bugs)', () async {
      when(() => repository.getRandomInt()).thenThrow(StateError('bug'));

      await expectLater(useCase(), throwsStateError);
    });
  });
}
