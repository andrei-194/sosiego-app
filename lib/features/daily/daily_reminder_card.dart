import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../data/services/reminder_service.dart';
import '../../domain/notification_plan.dart';
import '../../l10n/l10n.dart';

/// «6:30 a. m.», «1:00 p. m.», «8:00 p. m.» a partir de `HH:mm`.
String reminderTimeLabel(AppLocalizations l, String hhmm) {
  final t = parseTimeOfDay(hhmm) ?? (hour: 6, minute: 30);
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return l.reminderClock(
    h12,
    t.minute.toString().padLeft(2, '0'),
    t.hour < 12 ? l.reminderAm : l.reminderPm,
  );
}

/// CONTRATO (HU-07.3): tarjeta «¿Quieres recibir el versículo cada día?» para
/// Inicio. Se muestra sola cuando corresponde (segunda apertura o 5
/// versículos vistos; si dijo «Ahora no», vuelve una vez a los 7 días) y si
/// no, ocupa 0 de alto. NO pide permiso al aparecer: solo al tocar una hora.
class DailyReminderCard extends ConsumerWidget {
  const DailyReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(reminderCardProvider);
    if (card.phase == ReminderCardPhase.hidden) return const SizedBox.shrink();
    final controller = ref.read(reminderCardProvider.notifier);
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final Widget body = switch (card.phase) {
      ReminderCardPhase.ask => _Ask(controller: controller),
      ReminderCardPhase.done => _Message(
        title: l.reminderDoneTitle(reminderTimeLabel(l, card.time ?? '')),
        body: l.reminderDoneBody,
        onClose: controller.close,
      ),
      ReminderCardPhase.denied => _Message(
        title: l.reminderDeniedTitle,
        body: l.reminderPermissionDenied,
        onClose: controller.close,
      ),
      ReminderCardPhase.hidden => const SizedBox.shrink(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.s8),
      child: SoftCard(
        key: const Key('daily-reminder-card'),
        color: context.accentWash,
        radius: AppRadius.block,
        padding: const EdgeInsets.all(Gap.s24),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSurface),
          child: body,
        ),
      ),
    );
  }
}

class _Ask extends StatelessWidget {
  const _Ask({required this.controller});
  final ReminderCardController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      (
        reminderPresetTimes[0],
        l.reminderTimeMorning,
        Icons.wb_twilight_rounded,
      ),
      (
        reminderPresetTimes[1],
        l.reminderTimeAfternoon,
        Icons.wb_sunny_outlined,
      ),
      (reminderPresetTimes[2], l.reminderTimeNight, Icons.nightlight_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l.reminderCardTitle, style: AppText.heading(context)),
        ),
        const SizedBox(height: Gap.s8),
        Text(l.reminderCardBody, style: AppText.body(context)),
        const SizedBox(height: Gap.s16),
        for (final o in options) ...[
          FilledButton.tonalIcon(
            key: Key('reminder-time-${o.$1}'),
            onPressed: () => controller.choose(o.$1),
            icon: Icon(o.$3),
            label: Text(o.$2(reminderTimeLabel(l, o.$1))),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSize.minTarget),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Gap.s8),
        ],
        TextButton(
          key: const Key('reminder-not-now'),
          onPressed: controller.dismiss,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.minTarget),
          ),
          child: Text(l.reminderNotNow),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.onClose,
  });
  final String title;
  final String body;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.heading(context)),
          const SizedBox(height: Gap.s8),
          Text(body, style: AppText.body(context)),
          const SizedBox(height: Gap.s16),
          FilledButton(
            key: const Key('reminder-got-it'),
            onPressed: onClose,
            child: Text(l.reminderGotIt),
          ),
        ],
      ),
    );
  }
}
