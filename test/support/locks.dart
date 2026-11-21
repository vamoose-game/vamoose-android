import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/restraint.dart';

List<Lock> locksOf(Board board) => [
  for (final restraint in board.restraints)
    switch (restraint) {
      Lock() => restraint,
    },
];

/// Plays every block but the key, one legal move at a time in rounds, and
/// says whether the locked block's path is clear once nothing else can go.
bool holdsBack(Board board, Lock lock) {
  var current = board;
  while (true) {
    final round = [
      for (final block in current.movableBlocks)
        if (block.id != lock.keyId) block.id,
    ];
    if (round.isEmpty) {
      return current.blockerOf(current.blockById(lock.blockId)) == null;
    }
    for (final id in round) {
      final block = current.blockById(id);
      if (current.canLeave(block)) {
        current = current.without(id);
      }
    }
  }
}

void expectFairLocks(Board board, {String reason = ''}) {
  final roles = <int>[];
  for (final lock in locksOf(board)) {
    roles.addAll([lock.blockId, lock.keyId]);
    expect(
      board.blockerOf(board.blockById(lock.keyId)),
      isNotNull,
      reason: '$reason: key ${lock.keyId} is free at the start',
    );
    expect(
      holdsBack(board, lock),
      isTrue,
      reason: '$reason: lock on ${lock.blockId} holds nothing back',
    );
  }
  expect(
    roles.toSet(),
    hasLength(roles.length),
    reason: '$reason: a block plays two lock roles',
  );
  expect(board.isSolvable, isTrue, reason: '$reason: stuck');
}
