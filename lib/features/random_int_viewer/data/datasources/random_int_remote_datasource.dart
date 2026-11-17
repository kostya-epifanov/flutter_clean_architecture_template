import 'package:flutter_clean_template/core/config/app_config.dart';
import 'package:flutter_clean_template/core/network/http/http_client.dart';

abstract class IRandomIntRemoteDataSource {
  Future<int> getRandomInt();
}

class RandomIntRemoteDataSource implements IRandomIntRemoteDataSource {
  final HttpClient _httpClient;

  const RandomIntRemoteDataSource(this._httpClient);

  @override
  Future<int> getRandomInt() async {
    final url = '${AppConfig.apiBaseUrl}${AppConfig.randomIntEndpoint}';

    return await _httpClient.execute<int>(
      method: 'GET',
      url: url,
      parser: (data) => int.parse(data.toString().trim()),
      query: {
        'num': 1,
        'min': 1,
        'max': 100,
        'col': 1,
        'base': 10,
        'format': 'plain',
      },
    );
  }
}
