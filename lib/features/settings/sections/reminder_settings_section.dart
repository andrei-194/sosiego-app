import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/choice_row.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/tokens.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/reminder_service.dart';
import '../../../domain/notification_plan.dart';
import '../../../l10n/l10n.dart';
import '../../daily/daily_reminder_card.dart';

/// ¿Están encendidas las notificaciones en el teléfono? (si no, el aviso no
/// llegaría aunque esté activado).
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    return await ref.read(notificationServiceProvider).areEnabled();
  } catch (_) {
    return true;
  }
});

/// CONTRATO (HU-12): filas de Ajustes de «Versículo diario» (activar y hora) y
/// «Ayuda con las notificaciones».
class ReminderSettingsSection extends ConsumerStatefulWidget {
  const ReminderSettingsSection({super.key});

  @override
  ConsumerState<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState
    extends ConsumerState<ReminderSettingsSection> {
  bool _denied = false;

  Future<void> _toggle(bool on) async {
    final controller = ref.read(reminderControllerProvider.notifier);
    if (!on) {
      setState(() => _denied = false);
      await controller.disable();
      return;
    }
    final result = await controller.enable(
      ref.read(reminderControllerProvider).time,
    );
    if (!mounted) return;
    setState(() => _denied = result == EnableResult.denied);
    ref.invalidate(notificationsAllowedProvider);
  }

  Future<void> _pickOther() async {
    final l = context.l10n;
    final current = parseTimeOfDay(ref.read(reminderControllerProvider).time);
    final picked = await showTimePicker(
      context: context,
      helpText: l.reminderPickerHelp,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 6,
        minute: current?.minute ?? 30,
      ),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(reminderControllerProvider.notifier)
        .setTime(formatTimeOfDay(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(reminderControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final systemOff = settings.enabled
        ? ref.watch(notificationsAllowedProvider).valueOrNull == false
        : false;
    final isPreset = reminderPresetTimes.contains(settings.time);
    final presetNames = [
      l.reminderTimeMorning,
      l.reminderTimeAfternoon,
      l.reminderTimeNight,
    ];
    final status = settings.enabled ? l.reminderOn : l.reminderOff;

    Widget notice(String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(top: Gap.s12),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: scheme.primary),
            const SizedBox(width: Gap.s8),
            Expanded(
              child: Text(text, key: key, style: AppText.body(context)),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.reminderSettingsTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                toggled: settings.enabled,
                label: '${l.reminderSwitchLabel}. $status',
                excludeSemantics: true,
                onTap: () => _toggle(!settings.enabled),
                child: SoftCard(
                  key: const Key('reminder-switch-card'),
                  onTap: () => _toggle(!settings.enabled),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.reminderSwitchLabel,
                              style: AppText.label(context),
                            ),
                            Text(
                              status,
                              key: const Key('reminder-status'),
                              style: AppText.body(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: settings.enabled
                                    ? scheme.primary
                                    : context.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Gap.s12),
                      ExcludeSemantics(
                        child: Switch(
                          value: settings.enabled,
                          onChanged: _toggle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_denied)
                notice(
                  l.reminderPermissionDenied,
                  key: const Key('reminder-denied'),
                ),
              if (systemOff && !_denied)
                notice(
                  l.reminderSystemOff,
                  key: const Key('reminder-system-off'),
                ),
              if (settings.enabled) ...[
                const SizedBox(height: Gap.s16),
                Semantics(
                  header: true,
                  child: Text(
                    l.reminderTimeSection,
                    style: AppText.label(context),
                  ),
                ),
                const SizedBox(height: Gap.s8),
                for (var i = 0; i < reminderPresetTimes.length; i++) ...[
                  ChoiceRow(
                    key: Key('reminder-pick-${reminderPresetTimes[i]}'),
                    label: presetNames[i](
                      reminderTimeLabel(l, reminderPresetTimes[i]),
                    ),
                    selected: settings.time == reminderPresetTimes[i],
                    onTap: () => ref
                        .read(reminderControllerProvider.notifier)
                        .setTime(reminderPresetTimes[i]),
                  ),
                  const SizedBox(height: Gap.s8),
                ],
                ChoiceRow(
                  key: const Key('reminder-pick-other'),
                  label: isPreset
                      ? l.reminderOtherTime
                      : l.reminderOtherTimeChosen(
                          reminderTimeLabel(l, settings.time),
                        ),
                  selected: !isPreset,
                  onTap: _pickOther,
                ),
              ],
              const SizedBox(height: Gap.s16),
              SoftCard(
                key: const Key('reminder-help'),
                onTap: () => showNotificationHelp(context),
                semanticLabel:
                    '${l.reminderHelpTitle}. ${l.reminderHelpSubtitle}',
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: scheme.primary),
                    const SizedBox(width: Gap.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.reminderHelpTitle,
                            style: AppText.label(context),
                          ),
                          Text(
                            l.reminderHelpSubtitle,
                            style: AppText.body(context),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «Ayuda con las notificaciones» (HU-07.8): pasos para quitar el ahorro de
/// batería de la app, y avisos por marca.
Future<void> showNotificationHelp(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.block),
        ),
      ),
      builder: (_) => const _NotificationHelpSheet(),
    );

class _NotificationHelpSheet extends StatelessWidget {
  const _NotificationHelpSheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = [
      l.reminderHelpStep1,
      l.reminderHelpStep2,
      l.reminderHelpStep3,
    ];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s8, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.reminderHelpTitle,
                    style: AppText.heading(context),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.reminderHelpClose,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Gap.s24,
              Gap.s8,
              Gap.s24,
              Gap.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.reminderHelpIntro, style: AppText.body(context)),
                const SizedBox(height: Gap.s16),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Es una secuencia de pasos: la numeración informa.
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.accentWash,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: Gap.s12),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: AppText.body(context)
                                .copyWith(color: scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Gap.s8),
                Semantics(
                  header: true,
                  child: Text(
                    l.reminderHelpBrandsTitle,
                    style: AppText.label(context),
                  ),
                ),
                const SizedBox(height: Gap.s8),
                for (final t in [
                  l.reminderHelpSamsung,
                  l.reminderHelpXiaomi,
                  l.reminderHelpOthers,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s12),
                    child: Text(t, style: AppText.body(context)),
                  ),
                const SizedBox(height: Gap.s4),
                Text(l.reminderHelpLimit, style: AppText.body(context)),
                const SizedBox(height: Gap.s20),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                  child: Text(l.reminderHelpClose),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
