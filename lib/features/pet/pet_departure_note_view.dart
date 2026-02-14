import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/status_bar_style.dart';

class PetDepartureNoteView extends StatelessWidget {
  const PetDepartureNoteView({
    super.key,
    required this.heroTag,
    required this.noteText,
    this.onReturnPressed,
  });

  final String heroTag;
  final String noteText;
  final VoidCallback? onReturnPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.toLowerCase();
    final useJapaneseFont = languageCode == 'ja';
    final useChineseFont = languageCode == 'zh';
    final useEnglishFont = languageCode == 'en';
    final baseNoteStyle =
        Theme.of(context).textTheme.headlineSmall ??
        const TextStyle(fontSize: 24);
    final petNoteStyle = useJapaneseFont
        ? baseNoteStyle.copyWith(
            fontFamily: 'Heiseijyoji',
            color: const Color(0xFF4A3B2A),
            fontWeight: FontWeight.w600,
            height: 1.35,
          )
        : useChineseFont
        ? baseNoteStyle.copyWith(
            fontFamily: 'ChildJPZh',
            color: const Color(0xFF4A3B2A),
            fontWeight: FontWeight.w600,
            height: 1.35,
          )
        : useEnglishFont
        ? baseNoteStyle.copyWith(
            fontFamily: 'LittleKidsHandwriting',
            color: const Color(0xFF4A3B2A),
            fontWeight: FontWeight.w600,
            height: 1.35,
          )
        : GoogleFonts.kleeOne(
            textStyle: Theme.of(context).textTheme.headlineSmall,
            color: const Color(0xFF4A3B2A),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ).copyWith(
            fontFamilyFallback: const [
              'Noto Sans CJK JP',
              'Noto Sans CJK TC',
              'Noto Sans JP',
              'Noto Sans TC',
              'PingFang TC',
              'PingFang SC',
            ],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.dark,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * 0.74;
                    final cardHeight = constraints.maxHeight * 0.65;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Hero(
                        tag: heroTag,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: width,
                              height: cardHeight,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                24,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE8D8B5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                      icon: const Icon(Icons.close_rounded),
                                      tooltip: l10n.commonClose,
                                    ),
                                  ),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, contentConstraints) {
                                        final rawBottomHeight =
                                            contentConstraints.maxHeight * 0.42;
                                        final bottomHeight = rawBottomHeight
                                            .clamp(140.0, 220.0)
                                            .toDouble()
                                            .clamp(
                                              0.0,
                                              contentConstraints.maxHeight,
                                            );
                                        return Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: bottomHeight + 8,
                                                ),
                                                child: Center(
                                                  child: SingleChildScrollView(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: Text(
                                                        noteText,
                                                        textAlign:
                                                            TextAlign.center,
                                                        textWidthBasis:
                                                            TextWidthBasis
                                                                .parent,
                                                        style: petNoteStyle,
                                                        strutStyle:
                                                            StrutStyle.fromTextStyle(
                                                              petNoteStyle,
                                                              forceStrutHeight:
                                                                  true,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: SizedBox(
                                                height: bottomHeight,
                                                child: Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Divider(
                                                          height: 20,
                                                          color: Color(
                                                            0xFFE8D8B5,
                                                          ),
                                                        ),
                                                        Text(
                                                          l10n.petDepartureGuideTitle,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                color:
                                                                    const Color(
                                                                      0xFF4A3B2A,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          l10n.petDepartureGuideMessage,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color:
                                                                    const Color(
                                                                      0xFF4A3B2A,
                                                                    ),
                                                                height: 1.4,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Tooltip(
                                                          message: l10n
                                                              .petDepartureGuideGoStore,
                                                          child: SizedBox(
                                                            width: 64,
                                                            height: 44,
                                                            child: ElevatedButton(
                                                              onPressed:
                                                                  onReturnPressed,
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFF4A3B2A,
                                                                    ),
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: SvgPicture.asset(
                                                                'assets/icon/icon-park-outline--shopping-bag.svg',
                                                                width: 20,
                                                                height: 20,
                                                                colorFilter:
                                                                    const ColorFilter.mode(
                                                                      Colors
                                                                          .white,
                                                                      BlendMode
                                                                          .srcIn,
                                                                    ),
                                                              ),
                                                            ),
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
