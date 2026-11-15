import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../state/ad_free_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';

class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final adsRemoved = context.select<AdFreeController, bool>(
      (adFree) => adFree.adsRemoved,
    );
    if (adsRemoved || !context.read<AppServices>().ads.showsBanners) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: CustomPaint(
        painter: const _DashedBorderPainter(),
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(
              'AD · ADAPTIVE BANNER',
              style: AppText.label.copyWith(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.slate.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 9) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
