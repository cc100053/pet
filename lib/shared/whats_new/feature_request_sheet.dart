import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../services/feature_requests/feature_request_service.dart';

void showFeatureRequestSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final accent = Theme.of(context).colorScheme.primary;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeatureRequestSheet(l10n: l10n, accent: accent),
  );
}

class _FeatureRequestSheet extends StatefulWidget {
  const _FeatureRequestSheet({required this.l10n, required this.accent});

  final AppLocalizations l10n;
  final Color accent;

  @override
  State<_FeatureRequestSheet> createState() => _FeatureRequestSheetState();
}

class _FeatureRequestSheetState extends State<_FeatureRequestSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await FeatureRequestService.submit(_controller.text);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final accent = widget.accent;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.whatsNewSuggestFeatureTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.whatsNewSuggestFeaturePlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed:
                  (_submitting ||
                          _submitted ||
                          _controller.text.trim().isEmpty)
                      ? null
                      : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _submitted
                          ? l10n.whatsNewSuggestFeatureSuccess
                          : l10n.whatsNewSuggestFeatureSubmit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
