import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../shared/theme/app_theme.dart';
import 'pet_catalog.dart';

class PetSelectionPage extends StatefulWidget {
  const PetSelectionPage({super.key, this.initialSelectionId});

  final String? initialSelectionId;

  static Route<PetDefinition> route({String? initialSelectionId}) {
    return PageRouteBuilder<PetDefinition>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          PetSelectionPage(initialSelectionId: initialSelectionId),
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

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialSelectionId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pets = PetCatalog.pets;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
          children: [
            Positioned(
              top: -90,
              right: -40,
              child: _bubble(size: 200, opacity: 0.5),
            ),
            Positioned(
              bottom: 140,
              left: -60,
              child: _bubble(size: 220, opacity: 0.4),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(context).backButtonTooltip,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppTheme.textPrimary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            l10n.petSelectionTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
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
                      l10n.petSelectionSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
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
                    child: AnimatedSwitcher(
                      duration: 200.ms,
                      child: _selectedPetId == null
                          ? Text(
                              l10n.petSelectionHint,
                              key: const ValueKey('petSelectionHint'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Text(
                              l10n.petSelectionSelected(
                                PetCatalog.byId(_selectedPetId)
                                    .name(l10n),
                              ),
                              key: const ValueKey('petSelectionSelected'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: FilledButton(
                      onPressed: _selectedPetId == null
                          ? null
                          : () {
                              final selected =
                                  PetCatalog.byId(_selectedPetId);
                              Navigator.of(context).pop(selected);
                            },
                      child: Text(l10n.petSelectionConfirm),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final shadowColor =
        isSelected ? pet.accent.withValues(alpha: 0.2) : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() {
            _selectedPetId = pet.id;
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
              Align(
                alignment: Alignment.centerRight,
                child: pet.isStarter
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pet.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.petSelectionStarterBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: pet.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox(height: 22),
              ),
              const Gap(8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: pet.gradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Image.asset(
                      pet.stayAsset,
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
