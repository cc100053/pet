part of '../store_view.dart';

extension _StoreDepartedPetSelector on _StoreViewState {
  Future<void> _showNoDepartedPetsDialog(AppLocalizations l10n) async {
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterUnavailableTitle,
        message: l10n.petDepartureLetterUnavailableMessage,
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<DepartedPetInfo?> _selectDepartedPet(AppLocalizations l10n) {
    return showAppDialog<DepartedPetInfo>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterSelectTitle,
        message: l10n.petDepartureLetterSelectMessage,
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _departedPets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pet = _departedPets[index];
              final petDefinition = PetCatalog.byId(pet.petType);
              return Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: petDefinition.accent.withValues(alpha: 0.28),
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.38),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(pet),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: petDefinition.accent.withValues(
                                alpha: 0.14,
                              ),
                              alignment: Alignment.center,
                              child: Image.asset(
                                petDefinition.stayAsset,
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pet.petName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmLetterPurchase(
    AppLocalizations l10n,
    DepartedPetInfo pet,
  ) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterConfirmTitle(pet.petName),
        message: l10n.petDepartureLetterConfirmMessage(pet.petName),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppDialogAction.primary(
            label: l10n.petDepartureLetterConfirmAction,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
