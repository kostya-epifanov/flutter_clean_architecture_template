import 'dart:math';

abstract class IRandomIntLocalDataSource {
  Future<int> getRandomInt();
}

class RandomIntLocalDataSource implements IRandomIntLocalDataSource {
  final Random _random = Random();

  @override
  Future<int> getRandomInt() async => _random.nextInt(100);
}
