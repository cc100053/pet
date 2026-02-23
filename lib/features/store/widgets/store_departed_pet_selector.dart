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
