part of 'home_view.dart';

class _ProfileSummary {
  const _ProfileSummary({required this.nickname, required this.avatarUrl});

  final String? nickname;
  final String? avatarUrl;
}

class _RoomLatestFeed {
  _RoomLatestFeed({
    required this.latestImageUrl,
    required this.latestCaption,
    required this.latestSenderId,
    required this.imageUrls,
    required this.imageCaptions,
  });

  final String latestImageUrl;
  final String? latestCaption;
  final String? latestSenderId;
  final List<String> imageUrls;
  final List<String?> imageCaptions;
}

class _RoomPetSummary {
  const _RoomPetSummary({
    required this.petType,
    required this.healthValue,
    required this.petName,
    required this.petLevel,
  });

  final String petType;
  final double healthValue;
  final String? petName;
  final int? petLevel;
}

class _PlacedFurniture {
  _PlacedFurniture({
    required this.id,
    required this.itemId,
    required this.ownerUserId,
    required this.emoji,
    required this.normalizedPosition,
    required this.isPending,
  });

  String id;
  String itemId;
  String? ownerUserId;
  String emoji;
  Offset normalizedPosition;
  bool isPending;
}

class _PoopSpot {
  const _PoopSpot({required this.index, required this.normalized});

  final int index;
  final Offset normalized;
}

class _RoomCreationDetails {
  const _RoomCreationDetails({required this.petName});

  final String petName;
}

class _LocalFeedCooldown {
  const _LocalFeedCooldown({required this.nextEligibleAt});

  final DateTime nextEligibleAt;
}

class _RoomCreationDialog extends StatefulWidget {
  const _RoomCreationDialog({required this.maxPetNameLength});

  final int maxPetNameLength;

  @override
  State<_RoomCreationDialog> createState() => _RoomCreationDialogState();
}

class _RoomCreationDialogState extends State<_RoomCreationDialog> {
  late final TextEditingController _petController;
  String? _petError;

  @override
  void initState() {
    super.initState();
    _petController = TextEditingController();
  }

  @override
  void dispose() {
    _petController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final petName = _petController.text.trim();
    var hasError = false;
    if (petName.isEmpty) {
      _petError = l10n.petNameEmptyError;
      hasError = true;
    } else {
      _petError = null;
    }
    if (hasError) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(_RoomCreationDetails(petName: petName));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppDialog(
      tone: AppDialogTone.info,
      title: l10n.roomCreateTitle,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _petController,
              textInputAction: TextInputAction.done,
              maxLength: widget.maxPetNameLength,
              decoration: InputDecoration(
                labelText: l10n.petNameLabel,
                helperText: l10n.petNameHint,
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                errorText: _petError,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction.secondary(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction.primary(
          label: l10n.roomCreateAction,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
