import 'package:flutter_clean_template/core/std/result.dart';
import 'package:flutter_clean_template/features/random_int_viewer/data/repositories/random_int_repository.dart';

class GetRandomIntUseCase {
  final IRandomIntRepository repository;

  GetRandomIntUseCase(this.repository);

  Future<Result<int>> call() async {
    try {
      final value = await repository.getRandomInt();
      return Success(value);
    } on Exception catch (e, stackTrace) {
      return Failure(e, stackTrace);
    }
  }
}