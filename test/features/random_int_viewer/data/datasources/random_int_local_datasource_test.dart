import 'dart:math';

import 'package:clean_architecture_demo/features/random_int_viewer/data/datasources/random_int_local_datasource.dart';
import 'package:clean_architecture_demo/features/random_int_viewer/domain/entities/random_int_range.dart';
import 'package:flutter_test/flutter_test.dart';

/// [Random] that always returns the smallest or the largest allowed value.
class _ExtremeRandom implements Random {
  _ExtremeRandom({required this.highest});

  final bool highest;

  @override
  int nextInt(int max) => highest ? max - 1 : 0;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  group('RandomIntLocalDataSource', () {
    test('lowest draw maps to RandomIntRange.min', () {
      final dataSource = RandomIntLocalDataSource(_ExtremeRandom(highest: false));

      expect(dataSource.getRandomInt(), RandomIntRange.min);
    });

    test('highest draw maps to RandomIntRange.max', () {
      final dataSource = RandomIntLocalDataSource(_ExtremeRandom(highest: true));

      expect(dataSource.getRandomInt(), RandomIntRange.max);
    });

    test('always stays within 1..100 for a seeded generator', () {
      final dataSource = RandomIntLocalDataSource(Random(1));

      final values = [for (var i = 0; i < 1000; i++) dataSource.getRandomInt()];

      expect(values, everyElement(inInclusiveRange(1, 100)));
    });
  });
}
