import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../data/user/providers.dart';
import '../../domain/font_scale.dart';
import '../../domain/user_data.dart';
import '../../l10n/l10n.dart';
import '../settings/settings_providers.dart';

/// Versículo real que se usa de muestra: Salmos 23:1 si está y, si no, el
/// primero elegible.
final welcomeSampleProvider = FutureProvider<Verse?>((ref) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  final verse = repo.byId(19023001);
  if (verse != null) return verse;
  final ids = repo.eligibleCandidates();
  return ids.isEmpty ? null : repo.byId(ids.first.id);
});

/// Primer arranque (spec HU-01): UNA pantalla «¿Cómo prefieres leer?» con tres
/// tamaños, cada uno con una muestra real a su tamaño. Al tocar una opción la
/// pantalla cambia al instante; «Continuar» confirma. No pide permisos, cuenta
/// ni datos.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  FontSizeChoice? _choice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_choice == null) {
      // Preselección según la letra del sistema (1.3 Grande, 1.6 Muy grande).
      final system = MediaQuery.textScalerOf(context).scale(1);
      _choice = FontSizeChoice.forSystemScale(system);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chosenFontScaleProvider.notifier).state = _choice!.factor;
        }
      });
    }
  }

  void _select(FontSizeChoice c) {
    setState(() => _choice = c);
    ref.read(chosenFontScaleProvider.notifier).state = c.factor;
  }

  Future<void> _continue() async {
    final c = _choice ?? FontSizeChoice.normal;
    await saveFontScale(c.factor);
    await saveOnboardingDone();
    try {
      final state = await ref.read(appStateRepositoryProvider.future);
      await state.set(
        AppStateKeys.firstRunAt,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sample = ref.watch(welcomeSampleProvider).valueOrNull;
    final labels = {
      FontSizeChoice.normal: (l.fontNormal, l.fontNormalDesc),
      FontSizeChoice.grande: (l.fontLarge, l.fontLargeDesc),
      FontSizeChoice.muyGrande: (l.fontXLarge, l.fontXLargeDesc),
    };
    return SosiegoPage(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('welcome'),
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s24,
                Gap.s24,
                Gap.s16,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(l.welcomeTitle, style: AppText.title(context)),
                ),
                const SizedBox(height: Gap.s8),
                Text(l.welcomeBody, style: AppText.body(context)),
                const SizedBox(height: Gap.s20),
                for (final c in FontSizeChoice.values) ...[
                  _SizeOption(
                    key: Key('size-${c.key}'),
                    choice: c,
                    label: labels[c]!.$1,
                    selected: _choice == c,
                    sample: sample,
                    onTap: () => _select(c),
                  ),
                  const SizedBox(height: Gap.s12),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s24,
              Gap.s8,
              Gap.s24,
              Gap.s24,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('welcome-continue'),
                onPressed: _continue,
                child: Text(l.actionContinue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opción: el nombre y un versículo real al tamaño exacto de esa opción
/// (la muestra ignora la escala global para mostrar el tamaño que se elige).
class _SizeOption extends StatelessWidget {
  const _SizeOption({
    super.key,
    required this.choice,
    required this.label,
    required this.selected,
    required this.sample,
    required this.onTap,
  });

  final FontSizeChoice choice;
  final String label;
  final bool selected;
  final Verse? sample;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SoftCard(
        onTap: onTap,
        color: selected ? context.accentWash : null,
        padding: const EdgeInsets.all(Gap.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: AppText.label(context))),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
            if (sample != null) ...[
              const SizedBox(height: Gap.s8),
              Text(
                sample!.text,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: AppTheme.verseFont,
                  fontSize: AppFont.verse * choice.factor,
                  height: 1.5,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: Gap.s4),
              Text(
                sample!.reference,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: AppTheme.verseFont,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: AppFont.reference * choice.factor,
                  color: scheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
