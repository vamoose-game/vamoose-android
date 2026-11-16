import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/settings_controller.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/key_press_sound.dart';
import 'app_info.dart';
import 'app_services.dart';

class VamooseApp extends StatelessWidget {
  const VamooseApp({
    super.key,
    required this.services,
    this.home = const SplashScreen(),
  });

  final AppServices services;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: services),
        ChangeNotifierProvider.value(value: services.settings),
        ChangeNotifierProvider.value(value: services.progress),
        ChangeNotifierProvider.value(value: services.hints),
        ChangeNotifierProvider.value(value: services.daily),
        ChangeNotifierProvider.value(value: services.adFree),
      ],
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        builder: (context, child) {
          final scale = context.select<SettingsController, double>(
            (settings) => settings.textScale,
          );
          return KeyPressSound(
            onPress: services.feedback.keyPressed,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          );
        },
        home: home,
      ),
    );
  }
}
