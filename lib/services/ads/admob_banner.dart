import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key, required this.unitId});

  final String unitId;

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      return;
    }
    final ad = BannerAd(
      adUnitId: widget.unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => _update(() => _loaded = true),
        onAdFailedToLoad: (ad, _) {
          unawaited(ad.dispose());
          _update(() => _ad = null);
        },
      ),
    );
    _update(() => _ad = ad);
    await ad.load();
  }

  void _update(VoidCallback change) {
    if (mounted) {
      setState(change);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_requested) {
          _requested = true;
          scheduleMicrotask(() => _load(constraints.maxWidth.truncate()));
        }
        final ad = _ad;
        if (ad == null) {
          return const SizedBox.shrink();
        }
        return Center(
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: _loaded ? AdWidget(ad: ad) : null,
          ),
        );
      },
    );
  }
}
