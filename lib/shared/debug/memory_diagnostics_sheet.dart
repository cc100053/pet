import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../services/performance/memory_diagnostics_service.dart';

class MemoryDiagnosticsSheet extends StatelessWidget {
  const MemoryDiagnosticsSheet({super.key, required this.snapshotsListenable});

  final ValueListenable<List<MemoryDiagnosticsSnapshot>> snapshotsListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.debugMemoryDiagnosticsTitle,
                      key: const ValueKey<String>(
                        'memory-diagnostics-sheet-title',
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ValueListenableBuilder<List<MemoryDiagnosticsSnapshot>>(
                valueListenable: snapshotsListenable,
                builder: (context, snapshots, _) {
                  if (snapshots.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.debugMemoryDiagnosticsEmpty,
                          key: const ValueKey<String>(
                            'memory-diagnostics-sheet-empty',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  final ordered = snapshots.reversed.toList(growable: false);
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ordered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final snapshot = ordered[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            snapshot.debugSummary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.45,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
