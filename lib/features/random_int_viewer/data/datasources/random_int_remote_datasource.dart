import 'package:clean_architecture_demo/core/network/api_client.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int_range.dart';

/// random.org plain-text integer API.
class RandomIntRemoteDataSource {
  final ApiClient _client;

  const RandomIntRemoteDataSource(this._client);

  /// Throws a `NetworkException` when the request fails.
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
      parser: (data) => int.parse('$data'.trim()),
    );
  }
}
