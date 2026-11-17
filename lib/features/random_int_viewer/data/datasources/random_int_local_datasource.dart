import 'dart:math';

import 'package:flutter_clean_template/features/random_int_viewer/domain/entities/random_int_range.dart';

abstract class IRandomIntLocalDataSource {
  Future<int> getRandomInt();
}

/// Offline fallback: generates the number on the device.
class RandomIntLocalDataSource implements IRandomIntLocalDataSource {
  final Random _random;

  RandomIntLocalDataSource([Random? random]) : _random = random ?? Random();

  @override
  Future<int> getRandomInt() async =>
      RandomIntRange.min + _random.nextInt(RandomIntRange.max - RandomIntRange.min + 1);
}
