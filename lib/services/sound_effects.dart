enum Sound { tap, slide, bump, hint, clear, star }

abstract interface class SoundEffects {
  void play(Sound sound);
}
