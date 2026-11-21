import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../domain/board_theme.dart';
import '../state/theme_controller.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/board_colors.dart';
import '../ui/widgets/key_press_sound.dart';
import 'app_info.dart';
import 'app_services.dart';

class VamooseApp extends StatelessWidget {
  const VamooseApp({
    super.key,
    required this.services,
    this.home = const SplashScreen(),
  });

  static const double maxTextScale = 1.2;

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
        ChangeNotifierProvider.value(value: services.extraTime),
        ChangeNotifierProvider.value(value: services.lives),
        ChangeNotifierProvider.value(value: services.coins),
        ChangeNotifierProvider.value(value: services.streak),
        ChangeNotifierProvider.value(value: services.daily),
        ChangeNotifierProvider.value(value: services.adFree),
        ChangeNotifierProvider.value(value: services.themes),
      ],
      child: Selector<ThemeController, BoardTheme>(
        selector: (_, themes) => themes.active,
        builder: (context, theme, _) => MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(BoardColors.from(theme)),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.statusBar(Brightness.light),
              child: KeyPressSound(
                onPress: services.feedback.keyPressed,
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: media.textScaler.clamp(
                      maxScaleFactor: maxTextScale,
                    ),
                  ),
                  child: child!,
                ),
              ),
            );
          },
          home: home,
        ),
      ),
    );
  }
}
