import 'dart:async';

import 'package:flutter/services.dart';

abstract interface class Haptics {
  void light();

  void medium();

  void heavy();
}

class SystemHaptics implements Haptics {
  const SystemHaptics();

  @override
  void light() => unawaited(HapticFeedback.lightImpact());

  @override
  void medium() => unawaited(HapticFeedback.mediumImpact());

  @override
  void heavy() => unawaited(HapticFeedback.heavyImpact());
}
