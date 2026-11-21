enum Sound {
  tap(1),
  leave(8),
  bump(1),
  hint(1),
  clear(1),
  star(3),
  tick(1),
  fail(1),
  boost(1);

  const Sound(this.variants);

  final int variants;
}

abstract interface class SoundEffects {
  void play(Sound sound, {int variant = 0});
}
