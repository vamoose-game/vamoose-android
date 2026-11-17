import 'dart:math';

import 'board.dart';
import 'level_spec.dart';

abstract interface class LevelFeature {
  Board? addTo(Board board, LevelSpec spec, Random random);
}
