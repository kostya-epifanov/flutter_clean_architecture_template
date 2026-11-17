import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/usecases/get_random_int_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  test('returns the repository result', () async {
    final repository = MockRandomIntRepository();
    when(repository.getRandomInt)
        .thenAnswer((_) async => const Failure<int, RandomIntFailure>(RandomIntFailure.timeout));

    expect(
      await GetRandomIntUseCase(repository)(),
      const Failure<int, RandomIntFailure>(RandomIntFailure.timeout),
    );
  });
}
