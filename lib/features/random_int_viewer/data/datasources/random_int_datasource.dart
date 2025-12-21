import 'dart:math';

import 'package:flutter_clean_template/core/network/http/http_client.dart';

abstract class IRandomIntDataSource {
  Future<int> getRandomInt();
}

class RandomIntRemoteDataSource implements IRandomIntDataSource {
  final HttpClient _httpClient;

  RandomIntRemoteDataSource(this._httpClient);

  @override
  Future<int> getRandomInt() async {
    return await _httpClient.execute<int>(
      method: 'GET',
      url: 'https://www.random.org/integers/',
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

class RandomIntLocalDataSource implements IRandomIntDataSource {
  @override
  Future<int> getRandomInt() async {
    final random = Random();
    return random.nextInt(100);
  }
}
