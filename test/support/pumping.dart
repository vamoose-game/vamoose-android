import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/app/vamoose_app.dart';

const Duration frame = Duration(milliseconds: 50);

bool _fontsLoaded = false;

Future<void> _loadLexend() async {
  if (_fontsLoaded) {
    return;
  }
  final loader = FontLoader('Lexend');
  for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/Lexend-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  _fontsLoaded = true;
}

extension Pumping on WidgetTester {
  Future<void> launch(AppServices services, {Widget? home}) async {
    await runAsync(_loadLexend);
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 2.625;
    addTearDown(view.reset);
    await pumpWidget(
      home == null
          ? VamooseApp(services: services)
          : VamooseApp(services: services, home: home),
    );
    await wait(frame);
  }

  Future<void> wait(Duration duration) async {
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += frame) {
      await pump(frame);
    }
  }

  Future<void> tapAndWait(
    Finder finder, [
    Duration duration = const Duration(milliseconds: 600),
  ]) async {
    await tap(finder);
    await wait(duration);
  }

  Future<void> close() async {
    await pumpWidget(const SizedBox());
    await wait(const Duration(seconds: 3));
  }
}
