import 'package:flutter/services.dart';

import '../domain/level.dart';
import '../domain/level_codec.dart';

class LevelCatalog {
  LevelCatalog(this._levels);

  static const String assetPath = 'assets/levels/levels.json';

  final List<Level> _levels;

  int get count => _levels.length;

  Level byNumber(int number) => _levels[number - 1];

  static Future<LevelCatalog> load(AssetBundle bundle) async =>
      LevelCatalog(LevelCodec.decode(await bundle.loadString(assetPath)));
}
