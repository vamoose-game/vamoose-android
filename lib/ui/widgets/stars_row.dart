import 'package:flutter/widgets.dart';

import '../../domain/star_rating.dart';
import 'glyphs.dart';

class StarsRow extends StatelessWidget {
  const StarsRow({
    super.key,
    required this.stars,
    this.size = 18,
    this.outlined = true,
  });

  final int stars;
  final double size;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of ${StarRating.max} stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < StarRating.max; index++)
            StarGlyph(
              size: size,
              filled: index < stars,
              outlined: outlined,
              strokeWidth: 1.4,
            ),
        ],
      ),
    );
  }
}
