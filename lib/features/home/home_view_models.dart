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
  });

  final String latestImageUrl;
  final String? latestCaption;
  final String? latestSenderId;
  final List<String> imageUrls;
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
  const _RoomCreationDetails({required this.roomName, required this.petName});

  final String roomName;
  final String petName;
}

class _RoomCreationDialog extends StatefulWidget {
  const _RoomCreationDialog({
    required this.initialRoomName,
    required this.maxPetNameLength,
  });

  final String initialRoomName;
  final int maxPetNameLength;

  @override
  State<_RoomCreationDialog> createState() => _RoomCreationDialogState();
}

class _RoomCreationDialogState extends State<_RoomCreationDialog> {
  late final TextEditingController _roomController;
  late final TextEditingController _petController;
  String? _roomError;
  String? _petError;

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(
      text: widget.initialRoomName.isEmpty ? null : widget.initialRoomName,
    );
    _petController = TextEditingController();
  }

  @override
  void dispose() {
    _roomController.dispose();
    _petController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final roomName = _roomController.text.trim();
    final petName = _petController.text.trim();
    var hasError = false;
    if (roomName.isEmpty) {
      _roomError = l10n.roomNameEmptyError;
      hasError = true;
    } else {
      _roomError = null;
    }
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
    Navigator.of(
      context,
    ).pop(_RoomCreationDetails(roomName: roomName, petName: petName));
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
              controller: _roomController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.roomNameLabel,
                helperText: l10n.roomDefaultName,
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                errorText: _roomError,
              ),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const Gap(12),
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
