import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_services.dart';
import 'app/vamoose_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final services = await AppServices.create();
  runApp(VamooseApp(services: services));
  services.music.start();
}
