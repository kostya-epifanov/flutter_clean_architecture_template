import 'package:clean_architecture_demo/core/result.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/failures/random_int_failure.dart';

abstract interface class RandomIntRepository {
  /// A number in `RandomIntRange`: from the API when it can be reached, generated on the
  /// device otherwise.
  Future<Result<RandomInt, RandomIntFailure>> getRandomInt();
}
