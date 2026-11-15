import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import 'block_face.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.47;
    Widget block(Direction direction) => SizedBox.square(
      dimension: tile,
      child: BlockFace(direction: direction),
    );
    return SizedBox.square(
      dimension: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [block(Direction.up), block(Direction.right)],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [block(Direction.left), block(Direction.down)],
          ),
        ],
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 54, this.withKey = false});

  final double size;
  final bool withKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vamoose',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('vamoose', style: AppText.logo.copyWith(fontSize: size)),
            if (withKey) ...[
              SizedBox(width: size * 0.2),
              SizedBox.square(
                dimension: size * 0.7,
                child: const BlockFace(direction: Direction.right),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
