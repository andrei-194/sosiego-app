import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/choice_row.dart';
import '../../core/widgets/labeled_switch.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/providers.dart';
import '../../domain/font_scale.dart';
import '../../l10n/l10n.dart';
import '../favorites/share_favorites.dart';
import '../feed/verse_actions.dart';
import 'sections/reminder_settings_section.dart';
import 'sections/voice_settings_section.dart';
import 'settings_providers.dart';

/// Ajustes (spec HU-12): tamaño de letra con vista previa, tema, versículo
/// diario, velocidad de voz, enviarme mis guardados, privacidad, acerca de y
/// enviar comentarios. Los cambios se aplican al instante.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri).catchError((_) => false);
    if (!ok && context.mounted) {
      showToast(context, context.l10n.settingsLinkError);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(chosenFontScaleProvider);
    final mode = ref.watch(themeModeProvider);
    final analytics = ref.watch(analyticsOptInProvider);
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final fontLabels = {
      FontSizeChoice.normal: (l.fontNormal, l.fontNormalDesc),
      FontSizeChoice.grande: (l.fontLarge, l.fontLargeDesc),
      FontSizeChoice.muyGrande: (l.fontXLarge, l.fontXLargeDesc),
    };
    const gap = SizedBox(height: Gap.s8);
    const side = EdgeInsets.symmetric(horizontal: Gap.s24);

    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s48),
        children: [
          ScreenHeader(title: l.settingsTitle, subtitle: l.settingsSubtitle),
          SectionTitle(l.settingsFontSection),
          Padding(
            padding: side,
            child: Column(
              children: [
                // Vista previa: usa el mismo factor que el resto de la app.
                SoftCard(
                  key: const Key('font-preview'),
                  color: context.accentWash,
                  padding: const EdgeInsets.all(Gap.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.settingsFontPreview, style: AppText.body(context)),
                      const SizedBox(height: Gap.s8),
                      Text(
                        l.settingsFontPreviewVerse,
                        style: AppText.verse(context),
                      ),
                      const SizedBox(height: Gap.s4),
                      Text(
                        l.settingsFontPreviewRef,
                        style: AppText.reference(context),
                      ),
                    ],
                  ),
                ),
                gap,
                for (final c in FontSizeChoice.values) ...[
                  ChoiceRow(
                    key: Key('font-${c.key}'),
                    label: fontLabels[c]!.$1,
                    description: fontLabels[c]!.$2,
                    selected: scale == c.factor,
                    leading: Text(
                      l.fontSample,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.verseFont,
                        fontSize: AppFont.action * c.factor,
                        color: scheme.primary,
                      ),
                    ),
                    onTap: () {
                      ref.read(chosenFontScaleProvider.notifier).state =
                          c.factor;
                      saveFontScale(c.factor);
                    },
                  ),
                  gap,
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
            padding: side,
            child: Column(
              children: [
                for (final o in [
                  (ThemeMode.light, l.themeLight, Icons.light_mode_outlined),
                  (ThemeMode.dark, l.themeDark, Icons.dark_mode_outlined),
                  (
                    ThemeMode.system,
                    l.themeSystem,
                    Icons.brightness_auto_outlined,
                  ),
                ]) ...[
                  ChoiceRow(
                    key: Key('theme-${o.$1.name}'),
                    label: o.$2,
                    selected: mode == o.$1,
                    leading: Icon(o.$3, color: scheme.primary),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).state = o.$1;
                      saveThemeMode(o.$1);
                    },
                  ),
                  gap,
                ],
              ],
            ),
          ),
          // Versículo diario (activar y hora), ayuda con las notificaciones y
          // velocidad de voz: las aporta el frente de funciones.
          const ReminderSettingsSection(),
          const VoiceSettingsSection(),
          SectionTitle(l.settingsSendSaved),
          Padding(
            padding: side,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.favoritesPhoneNote, style: AppText.body(context)),
                const SizedBox(height: Gap.s12),
                OutlinedButton.icon(
                  key: const Key('settings-send-saved'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                  onPressed: () => sendMyFavorites(context, ref),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l.favoritesSend),
                ),
              ],
            ),
          ),
          SectionTitle(l.settingsPrivacy),
          Padding(
            padding: side,
            child: Column(
              children: [
                LabeledSwitchRow(
                  key: const Key('analytics-switch'),
                  label: l.settingsAnalytics,
                  description: l.settingsAnalyticsNote,
                  value: analytics,
                  onChanged: (v) {
                    ref.read(analyticsOptInProvider.notifier).state = v;
                    saveAnalyticsOptIn(v);
                  },
                ),
                gap,
                OutlinedButton.icon(
                  key: const Key('privacy-policy'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                  onPressed: () => _open(context, Uri.parse(privacyPolicyUrl)),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l.settingsPrivacyPolicy),
                ),
              ],
            ),
          ),
          SectionTitle(l.settingsAbout),
          Padding(
            padding: side,
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
                  _InfoLine(label: l.aboutBible, value: l.aboutPublicDomain),
                  _InfoLine(
                    label: l.aboutContentVersion,
                    value: repo?.contentVersion ?? '…',
                  ),
                  _InfoLine(
                    label: l.aboutSource,
                    value: repo?.meta('source_url') ?? '…',
                  ),
                  const SizedBox(height: Gap.s12),
                  Text(l.aboutAiNote, style: AppText.body(context)),
                ],
              ),
            ),
          ),
          gap,
          Padding(
            padding: side,
            child: Column(
              children: [
                OutlinedButton.icon(
                  key: const Key('licenses'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: l.appTitle,
                    applicationVersion: appVersion,
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(l.settingsLicenses),
                ),
                gap,
                OutlinedButton.icon(
                  key: const Key('feedback'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                  onPressed: () => _open(
                    context,
                    Uri(
                      scheme: 'mailto',
                      path: feedbackEmail,
                      query:
                          'subject=${Uri.encodeComponent(l.settingsFeedbackSubject)}',
                    ),
                  ),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(l.settingsFeedback),
                ),
              ],
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
              style: AppText.label(context),
            ),
          ),
        ],
      ),
    );
  }
}
