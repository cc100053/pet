import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../services/settings/app_settings_repository.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/responsive_layout.dart';
import '../../shared/ui/status_bar_style.dart';
import 'pet_animated_image.dart';
import 'pet_catalog.dart';

class PetSelectionResult {
  const PetSelectionResult({required this.pet, required this.petName});

  final PetDefinition pet;
  final String petName;
}

typedef PetSelectionSubmitHandler =
    Future<String?> Function(PetSelectionResult selection);

class PetSelectionPage extends StatefulWidget {
  const PetSelectionPage({
    super.key,
    this.initialSelectionId,
    this.maxPetNameLength = 20,
    this.titleText,
    this.subtitleText,
    this.confirmText,
    this.submittingText,
    this.onSubmitSelection,
  });

  final String? initialSelectionId;
  final int maxPetNameLength;
  final String? titleText;
  final String? subtitleText;
  final String? confirmText;
  final String? submittingText;
  final PetSelectionSubmitHandler? onSubmitSelection;

  static Route<PetSelectionResult> route({
    String? initialSelectionId,
    int maxPetNameLength = 20,
    String? titleText,
    String? subtitleText,
    String? confirmText,
    String? submittingText,
    PetSelectionSubmitHandler? onSubmitSelection,
  }) {
    return PageRouteBuilder<PetSelectionResult>(
      pageBuilder: (context, animation, secondaryAnimation) => PetSelectionPage(
        initialSelectionId: initialSelectionId,
        maxPetNameLength: maxPetNameLength,
        titleText: titleText,
        subtitleText: subtitleText,
        confirmText: confirmText,
        submittingText: submittingText,
        onSubmitSelection: onSubmitSelection,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PetSelectionPage> createState() => _PetSelectionPageState();
}

class _PetSelectionPageState extends State<PetSelectionPage> {
  String? _selectedPetId;
  late final TextEditingController _petNameController;
  String? _petNameError;
  String? _submitError;
  bool _submitting = false;
  bool _didRefreshStatusBar = false;
  String? _currentAppVersion =
      AppSettingsRepository.instance.lastLaunchedAppVersion;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialSelectionId;
    if (!PetCatalog.supportsIdOnAppVersion(
      _selectedPetId,
      _currentAppVersion,
    )) {
      _selectedPetId = null;
    }
    _petNameController = TextEditingController();
    unawaited(_ensureCurrentAppVersion());
  }

  Future<String?> _ensureCurrentAppVersion() async {
    final cached = _currentAppVersion?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final resolved = version.isEmpty ? null : version;
      if (!mounted) {
        _currentAppVersion = resolved;
        return resolved;
      }
      setState(() {
        _currentAppVersion = resolved;
        if (!PetCatalog.supportsIdOnAppVersion(
          _selectedPetId,
          _currentAppVersion,
        )) {
          _selectedPetId = null;
        }
      });
      return resolved;
    } catch (_) {
      return _currentAppVersion;
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _submitSelection() async {
    if (_submitting) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final selectedPetId = _selectedPetId;
    if (selectedPetId == null) {
      return;
    }
    final petName = _petNameController.text.trim();
    if (petName.isEmpty) {
      setState(() {
        _petNameError = l10n.petNameEmptyError;
      });
      return;
    }
    final selection = PetSelectionResult(
      pet: PetCatalog.byIdForAppVersion(
        selectedPetId,
        appVersion: _currentAppVersion,
      ),
      petName: petName,
    );
    final submitHandler = widget.onSubmitSelection;
    if (submitHandler == null) {
      setState(() {
        _petNameError = null;
        _submitError = null;
      });
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(selection);
      return;
    }

    setState(() {
      _petNameError = null;
      _submitError = null;
      _submitting = true;
    });
    try {
      final errorMessage = await submitHandler(selection);
      if (!mounted) {
        return;
      }
      if (errorMessage != null && errorMessage.trim().isNotEmpty) {
        setState(() {
          _submitting = false;
          _submitError = errorMessage;
        });
        return;
      }
      Navigator.of(context).pop(selection);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = l10n.commonTryAgain;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRefreshStatusBar) {
      return;
    }
    _didRefreshStatusBar = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      SystemChrome.setSystemUIOverlayStyle(AppStatusBarStyles.light);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pets = PetCatalog.visiblePetsForAppVersion(_currentAppVersion);
    final titleText = widget.titleText ?? l10n.petSelectionTitle;
    final subtitleText = widget.subtitleText ?? l10n.petSelectionSubtitle;
    final confirmText = widget.confirmText ?? l10n.petSelectionConfirm;
    final submittingText = widget.submittingText ?? l10n.roomSelectionCreating;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.light,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: LayoutBuilder(
            builder: (context, viewport) {
              final responsive = ResponsiveLayout.fromSize(viewport.biggest);
              return Stack(
                children: [
                  Positioned(
                    top: responsive.y(-90),
                    right: responsive.x(-40),
                    child: _bubble(size: responsive.s(200), opacity: 0.5),
                  ),
                  Positioned(
                    bottom: responsive.y(140),
                    left: responsive.x(-60),
                    child: _bubble(size: responsive.s(220), opacity: 0.4),
                  ),
                  SafeArea(
                    child: IgnorePointer(
                      ignoring: _submitting,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: AppTheme.textPrimary,
                                  onPressed: _submitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: Text(
                                    titleText,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text(
                              subtitleText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              keyboardDismissBehavior:
                                  formScrollKeyboardDismissBehavior,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount: pets.length,
                              itemBuilder: (context, index) {
                                final pet = pets[index];
                                final isSelected = pet.id == _selectedPetId;
                                return _buildPetCard(
                                      context,
                                      pet: pet,
                                      isSelected: isSelected,
                                      l10n: l10n,
                                    )
                                    .animate()
                                    .fadeIn(delay: (80 * index).ms)
                                    .slideY(begin: 0.08, end: 0);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: 200.ms,
                                  child: _selectedPetId == null
                                      ? Text(
                                          l10n.petSelectionHint,
                                          key: const ValueKey(
                                            'petSelectionHint',
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        )
                                      : Text(
                                          l10n.petSelectionSelected(
                                            PetCatalog.byIdForAppVersion(
                                              _selectedPetId,
                                              appVersion: _currentAppVersion,
                                            ).name(l10n),
                                          ),
                                          key: const ValueKey(
                                            'petSelectionSelected',
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _petNameController,
                                  onTapOutside: dismissKeyboardOnTapOutside,
                                  textInputAction: TextInputAction.done,
                                  maxLength: widget.maxPetNameLength,
                                  decoration: InputDecoration(
                                    labelText: l10n.petNameLabel,
                                    helperText: l10n.petNameHint,
                                    errorText: _petNameError,
                                  ),
                                  onChanged: (_) {
                                    if (_petNameError == null &&
                                        _submitError == null) {
                                      return;
                                    }
                                    setState(() {
                                      _petNameError = null;
                                      _submitError = null;
                                    });
                                  },
                                  onSubmitted: (_) => _submitSelection(),
                                ),
                                if (_submitError != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _submitError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: FilledButton(
                              onPressed: _selectedPetId == null || _submitting
                                  ? null
                                  : _submitSelection,
                              child: _submitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(submittingText),
                                      ],
                                    )
                                  : Text(confirmText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_submitting)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.24),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  submittingText,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(
    BuildContext context, {
    required PetDefinition pet,
    required bool isSelected,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final borderColor = isSelected ? pet.accent : Colors.black12;
    final shadowColor = isSelected
        ? pet.accent.withValues(alpha: 0.2)
        : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() {
            _selectedPetId = pet.id;
            _petNameError = null;
          });
        },
        child: AnimatedContainer(
          duration: 180.ms,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              const Gap(8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: pet.gradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: PetAnimatedImage(
                      sourceAsset: pet.stayAsset,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              const Gap(10),
              Text(
                pet.name(l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                pet.tagline(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
