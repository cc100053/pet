import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopLegalLinksRow extends StatelessWidget {
  const ShopLegalLinksRow({
    super.key,
    required this.privacyPolicyUri,
    required this.termsOfUseUri,
    required this.privacyPolicyLabel,
    required this.termsOfUseLabel,
    required this.separatorLabel,
    this.onLaunchFailed,
  });

  final Uri privacyPolicyUri;
  final Uri termsOfUseUri;
  final String privacyPolicyLabel;
  final String termsOfUseLabel;
  final String separatorLabel;
  final VoidCallback? onLaunchFailed;

  Future<void> _openExternal(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      onLaunchFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black54,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    final separatorStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black38,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openExternal(privacyPolicyUri),
          child: Text(privacyPolicyLabel, style: textStyle),
        ),
        Text(separatorLabel, style: separatorStyle),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openExternal(termsOfUseUri),
          child: Text(termsOfUseLabel, style: textStyle),
        ),
      ],
    );
  }
}
