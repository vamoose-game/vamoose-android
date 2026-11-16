import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import 'block_face.dart';

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
