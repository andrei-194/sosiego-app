import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tokens.dart';
import '../../l10n/l10n.dart';

/// Encabezado de pantalla: título en Lora, subtítulo y acciones. Muestra
/// "Volver" si se puede retroceder y, opcionalmente, el acceso a Ajustes.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showSettings = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showSettings;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s8, Gap.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop || showSettings || trailing != null)
            Row(
              children: [
                if (canPop)
                  Transform.translate(
                    offset: const Offset(-Gap.s16, 0),
                    child: IconButton(
                      tooltip: context.l10n.actionBack,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                const Spacer(),
                ?trailing,
                if (showSettings) const SettingsButton(),
              ],
            ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Gap.s16),
              child: Semantics(
                header: true,
                child: Text(title, style: AppText.title(context)),
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: Gap.s8),
            Padding(
              padding: const EdgeInsets.only(right: Gap.s16),
              child: Text(subtitle!, style: AppText.body(context)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Acceso a Ajustes: el mismo icono en todas las pantallas principales.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.actionSettings,
    onPressed: () => context.push('/ajustes'),
    icon: Icon(
      Icons.tune_rounded,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
    ),
  );
}

/// Título de sección dentro de una lista.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.padding});
  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding:
        padding ??
        const EdgeInsets.fromLTRB(Gap.s24, Gap.s24, Gap.s24, Gap.s12),
    child: Semantics(
      header: true,
      child: Text(text, style: AppText.heading(context)),
    ),
  );
}
