import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import 'key_button.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconKey(
          icon: Icons.chevron_left_rounded,
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppText.pageTitle, maxLines: 1),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
