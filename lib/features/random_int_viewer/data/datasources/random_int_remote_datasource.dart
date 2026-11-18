import 'package:clean_architecture_demo/core/network/api_client.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int_range.dart';

/// random.org plain-text integer API.
class RandomIntRemoteDataSource {
  final ApiClient _client;

  const RandomIntRemoteDataSource(this._client);

  /// Throws a `NetworkException` when the request fails, and a `ParseException` when the
  /// answer is not a number in `RandomIntRange`.
  Future<int> getRandomInt() {
    return _client.get(
      '/integers/',
      query: {
        'num': 1,
        'min': RandomIntRange.min,
        'max': RandomIntRange.max,
        'col': 1,
        'base': 10,
        'format': 'plain',
      },
      parser: _parse,
    );
  }

  static int _parse(Object? data) {
    final value = int.parse('$data'.trim());
    if (value < RandomIntRange.min || value > RandomIntRange.max) {
      throw FormatException('$value is outside ${RandomIntRange.min}..${RandomIntRange.max}');
    }
    return value;
  }
}
