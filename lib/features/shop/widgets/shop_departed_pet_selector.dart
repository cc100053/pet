part of '../shop_view.dart';

extension _ShopDepartedPetSelector on _ShopViewState {
  Future<void> _showNoDepartedPetsDialog(AppLocalizations l10n) async {
    await showJuiceToast<void>(
      context: context,
      message: l10n.petDepartureLetterUnavailableTitle,
      position: JuicePosition.center,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.petDepartureLetterUnavailableMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              color: const Color(0xFF5A4A42),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(24),
          JuicyScaleButton(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.commonClose,
                  style: GoogleFonts.mPlusRounded1c(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmLetterPurchase(
    AppLocalizations l10n,
    DepartedPetInfo pet,
  ) async {
    final result = await showJuiceToast<bool>(
      context: context,
      message: l10n.petDepartureLetterConfirmTitle(pet.petName),
      position: JuicePosition.center,
      tone: AppDialogTone.danger,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.petDepartureLetterConfirmMessage(pet.petName),
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              color: const Color(0xFF5A4A42),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.petDepartureLetterConfirmAction,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
