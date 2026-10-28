import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/choice_row.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/tokens.dart';
import '../../../data/services/tts_service.dart';
import '../../../domain/spoken_reference.dart';
import '../../../l10n/l10n.dart';

const _voiceTestKey = 'prueba-voz';

/// CONTRATO (HU-12): fila de Ajustes «Velocidad de voz» (Lenta, Normal, Rápida)
/// con una prueba de voz. Se guarda en `tts_rate` y se aplica al instante.
class VoiceSettingsSection extends ConsumerWidget {
  const VoiceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rate = ref.watch(ttsRateProvider);
    final tts = ref.watch(ttsControllerProvider);
    final controller = ref.read(ttsControllerProvider.notifier);
    final selected = VoiceSpeed.fromRate(rate);
    final testing = tts.isActive(_voiceTestKey);
    final problem = tts.problemKey == _voiceTestKey
        ? tts.problem
        : TtsProblem.none;

    final labels = {
      VoiceSpeed.slow: l.voiceSlow,
      VoiceSpeed.normal: l.voiceNormal,
      VoiceSpeed.fast: l.voiceFast,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.voiceTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in VoiceSpeed.values) ...[
                ChoiceRow(
                  key: Key('voice-${s.name}'),
                  label: labels[s]!,
                  selected: selected == s,
                  leading: Icon(switch (s) {
                    VoiceSpeed.slow => Icons.hourglass_bottom_rounded,
                    VoiceSpeed.normal => Icons.record_voice_over_outlined,
                    VoiceSpeed.fast => Icons.fast_forward_rounded,
                  }, color: Theme.of(context).colorScheme.primary),
                  onTap: () async {
                    await ref.read(ttsRateProvider.notifier).choose(s);
                    // Lo que se está probando sigue con la velocidad nueva.
                    if (testing) {
                      await controller.play(_voiceTestKey, [l.voiceSampleText]);
                    }
                  },
                ),
                const SizedBox(height: Gap.s8),
              ],
              const SizedBox(height: Gap.s4),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  key: const Key('voice-test'),
                  onPressed: () => testing
                      ? controller.stop()
                      : controller.play(_voiceTestKey, [l.voiceSampleText]),
                  icon: Icon(
                    testing ? Icons.stop_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(testing ? l.listenStop : l.voiceTest),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      AppSize.minTarget,
                      AppSize.minTarget,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.s8),
              if (problem != TtsProblem.none)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    problem == TtsProblem.noSpanishVoice
                        ? l.listenNoVoice
                        : l.listenFailed,
                    key: const Key('voice-problem'),
                    style: AppText.body(context),
                  ),
                )
              else
                Text(l.voiceNote, style: AppText.body(context)),
            ],
          ),
        ),
      ],
    );
  }
}
