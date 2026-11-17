import 'dart:math';

import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int_range.dart';

class RandomIntLocalDataSource {
  final Random _random;

  RandomIntLocalDataSource([Random? random]) : _random = random ?? Random();

  int getRandomInt() =>
      RandomIntRange.min + _random.nextInt(RandomIntRange.max - RandomIntRange.min + 1);
}
