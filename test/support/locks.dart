import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/restraint.dart';

List<Lock> locksOf(Board board) => [
  for (final restraint in board.restraints)
    switch (restraint) {
      Lock() => restraint,
    },
];

bool holdsBack(Board board, Lock lock) {
  var current = board;
  while (true) {
    final free = current.movableBlocks
        .where((block) => block.id != lock.keyId)
        .toList();
    if (free.isEmpty) {
      return current.blockerOf(current.blockById(lock.blockId)) == null;
    }
    for (final block in free) {
      current = current.without(block.id);
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
