import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/repositories/random_int_repository.dart';

class GetRandomIntUseCase {
  final RandomIntRepository _repository;

  const GetRandomIntUseCase(this._repository);

  Future<Result<RandomInt, RandomIntFailure>> call() => _repository.getRandomInt();
}
