import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/choice_row.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../domain/font_scale.dart';
import '../verse/verse_providers.dart';
import 'settings_providers.dart';
import '../../l10n/l10n.dart';

const appVersion = '0.1.0';

/// Ajustes: tamaño de letra, tema y acerca de. Sin cuentas ni registro.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(chosenFontScaleProvider);
    final mode = ref.watch(themeModeProvider);
    final version = ref.watch(contentVersionProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    // Mismo orden que fontChoices (1.0 / 1.3 / 1.6).
    final fontLabels = [
      (l.fontNormal, l.fontNormalDesc),
      (l.fontLarge, l.fontLargeDesc),
      (l.fontXLarge, l.fontXLargeDesc),
    ];

    Widget gap() => const SizedBox(height: Gap.s8);

    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s48),
        children: [
          ScreenHeader(title: l.settingsTitle, subtitle: l.settingsSubtitle),
          SectionTitle(l.settingsFontSection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Column(
              children: [
                for (final c in fontChoices) ...[
                  ChoiceRow(
                    label: fontLabels[fontChoices.indexOf(c)].$1,
                    description: fontLabels[fontChoices.indexOf(c)].$2,
                    selected: scale == c,
                    leading: Text(
                      l.fontSample,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.verseFont,
                        fontSize:
                            20 *
                            (c == 1.0
                                ? 0.8
                                : c == 1.3
                                ? 1.0
                                : 1.2),
                        color: scheme.primary,
                      ),
                    ),
                    onTap: () {
                      ref.read(chosenFontScaleProvider.notifier).state = c;
                      saveFontScale(c);
                    },
                  ),
                  gap(),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: Gap.s4),
                  child: Text(l.settingsFontNote, style: AppText.body(context)),
                ),
              ],
            ),
          ),
          SectionTitle(l.settingsAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Column(
              children: [
                for (final o in [
                  (
                    ThemeMode.system,
                    l.themeSystem,
                    Icons.brightness_auto_outlined,
                  ),
                  (ThemeMode.light, l.themeLight, Icons.light_mode_outlined),
                  (ThemeMode.dark, l.themeDark, Icons.dark_mode_outlined),
                ]) ...[
                  ChoiceRow(
                    label: o.$2,
                    selected: mode == o.$1,
                    leading: Icon(o.$3, color: scheme.primary),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).state = o.$1;
                      saveThemeMode(o.$1);
                    },
                  ),
                  gap(),
                ],
              ],
            ),
          ),
          SectionTitle(l.settingsAbout),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: scheme.primary),
                      const SizedBox(width: Gap.s12),
                      Expanded(
                        child: Text(
                          l.aboutNoAccountTitle,
                          style: AppText.label(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.s8),
                  Text(l.aboutNoAccountBody, style: AppText.body(context)),
                  const SizedBox(height: Gap.s20),
                  _InfoLine(label: l.aboutAppVersion, value: appVersion),
                  _InfoLine(label: l.aboutBible, value: l.translationName),
                  _InfoLine(
                    label: l.aboutContentVersion,
                    value: version ?? '…',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppText.body(context))),
          const SizedBox(width: Gap.s16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
