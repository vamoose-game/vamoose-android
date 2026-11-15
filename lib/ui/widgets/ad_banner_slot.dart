import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../state/ad_free_controller.dart';

class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final adsRemoved = context.select<AdFreeController, bool>(
      (adFree) => adFree.adsRemoved,
    );
    final ads = context.read<AppServices>().ads;
    if (adsRemoved || !ads.isReady) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ads.banner(),
    );
  }
}
