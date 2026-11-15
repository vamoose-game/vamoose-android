import 'package:url_launcher/url_launcher.dart';

abstract interface class LinkOpener {
  Future<bool> open(Uri link);
}

class ExternalLinkOpener implements LinkOpener {
  const ExternalLinkOpener();

  @override
  Future<bool> open(Uri link) =>
      launchUrl(link, mode: LaunchMode.externalApplication);
}
