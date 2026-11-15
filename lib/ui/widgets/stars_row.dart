import 'package:material_ui/material_ui.dart';

import '../../domain/star_rating.dart';
import '../theme/palette.dart';

class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of ${StarRating.max} stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < StarRating.max; index++)
            Icon(
              Icons.star_rounded,
              size: size,
              color: index < stars ? Palette.sun : Palette.edge,
            ),
        ],
      ),
    );
  }
}
