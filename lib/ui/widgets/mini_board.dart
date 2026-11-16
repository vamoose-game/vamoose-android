import 'package:flutter/widgets.dart';

import '../../domain/board.dart';
import 'block_face.dart';

class MiniBoard extends StatelessWidget {
  const MiniBoard({super.key, required this.board, this.gap = 3});

  final Board board;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / board.size;
          return Stack(
            children: [
              for (final block in board.blocks)
                Positioned(
                  left: block.column * cell + gap,
                  top: block.row * cell + gap,
                  width: (block.isVertical ? 1 : block.length) * cell - gap * 2,
                  height:
                      (block.isVertical ? block.length : 1) * cell - gap * 2,
                  child: BlockFace(direction: block.direction),
                ),
            ],
          );
        },
      ),
    );
  }
}
