import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/labeled_action.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../data/services/tts_service.dart';
import '../../domain/spoken_reference.dart';
import '../../l10n/l10n.dart';

/// Clave con la que un versículo se anota como el que está leyendo la voz.
String listenKeyFor(int verseId) => 'verso-$verseId';

/// Botón «Escuchar» (HU-08): con texto visible y 56 dp como mínimo. Al
/// empezar pasa a «Pausar» y «Detener». Lee la referencia en forma hablada y
/// el versículo; con [extraBlocks] (contexto, reflexión, aplicación y
/// oración) los lee en orden con medio segundo de pausa. Se detiene al salir
/// de la pantalla y al cambiar de versículo.
class ListenButton extends ConsumerStatefulWidget {
  const ListenButton({
    super.key,
    required this.verse,
    this.extraBlocks = const [],
    this.rowWith,
  });

  final Verse verse;
  final List<String> extraBlocks;

  /// Variante de fila de acciones: en lugar del botón ancho, Escuchar (y
  /// Pausar y Detener al sonar) se dibujan como [LabeledAction] —icono con el
  /// texto debajo, 56 dp de alto— y comparten la fila con estas acciones, todas
  /// del mismo ancho. El comportamiento es el mismo (HU-08).
  final List<Widget>? rowWith;

  @override
  ConsumerState<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends ConsumerState<ListenButton> {
  late final TtsController _tts;

  String get _key => listenKeyFor(widget.verse.id);

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsControllerProvider.notifier);
  }

  @override
  void didUpdateWidget(ListenButton old) {
    super.didUpdateWidget(old);
    // Pasar a otro versículo corta la lectura del anterior (HU-08.5).
    if (old.verse.id != widget.verse.id) {
      final tts = _tts;
      final key = listenKeyFor(old.verse.id);
      Future.microtask(() => tts.stopIfActive(key));
    }
  }

  @override
  void dispose() {
    // Salir de la pantalla corta la lectura (HU-08.5). Se difiere un instante
    // para no cambiar el estado mientras el árbol se desmonta.
    final key = _key;
    final tts = _tts;
    Future.microtask(() => tts.stopIfActive(key));
    super.dispose();
  }

  void _play() {
    final v = widget.verse;
    _tts.play(
      _key,
      listenSegments(
        bookName: v.bookName,
        chapter: v.chapter,
        verse: v.verse,
        verseText: v.text,
        extraBlocks: widget.extraBlocks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(ttsControllerProvider);
    final active = state.isActive(_key);
    final playing = active && state.status == TtsStatus.playing;
    final problem = state.problemKey == _key ? state.problem : TtsProblem.none;
    final scheme = Theme.of(context).colorScheme;

    final problemNote = problem == TtsProblem.none
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: Gap.s8),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.primary),
                  const SizedBox(width: Gap.s8),
                  Expanded(
                    child: Text(
                      problem == TtsProblem.noSpanishVoice
                          ? l.listenNoVoice
                          : l.listenFailed,
                      key: const Key('listen-problem'),
                      style: widget.rowWith == null
                          ? AppText.body(context)
                          : AppText.body(context)
                                .copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          );

    final rowWith = widget.rowWith;
    if (rowWith != null) {
      final fg = scheme.primary;
      final slots = active
          ? [
              LabeledAction(
                key: const Key('listen-toggle'),
                label: playing ? l.listenPause : l.listenResume,
                color: fg,
                selected: playing,
                balanceLabel: true,
                onTap: playing ? _tts.pause : _tts.resume,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              LabeledAction(
                key: const Key('listen-stop'),
                label: l.listenStop,
                color: fg,
                balanceLabel: true,
                onTap: _tts.stop,
                icon: const Icon(Icons.stop_rounded),
              ),
            ]
          : [
              LabeledAction(
                key: const Key('listen-start'),
                label: l.listenAction,
                color: fg,
                balanceLabel: true,
                onTap: _play,
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ];
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in [...slots, ...rowWith]) Expanded(child: w),
            ],
          ),
          ?problemNote,
        ],
      );
    }

    final buttons = active
        ? [
            _ListenAction(
              key: const Key('listen-toggle'),
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? l.listenPause : l.listenResume,
              onPressed: playing ? _tts.pause : _tts.resume,
              filled: true,
            ),
            _ListenAction(
              key: const Key('listen-stop'),
              icon: Icons.stop_rounded,
              label: l.listenStop,
              onPressed: _tts.stop,
            ),
          ]
        : [
            _ListenAction(
              key: const Key('listen-start'),
              icon: Icons.volume_up_rounded,
              label: l.listenAction,
              onPressed: _play,
            ),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: Gap.s8, runSpacing: Gap.s8, children: buttons),
        ?problemNote,
      ],
    );
  }
}

class _ListenAction extends StatelessWidget {
  const _ListenAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(AppSize.minTarget, AppSize.minTarget),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: Gap.s20),
      ),
    );
    final child = Text(label);
    final iconWidget = Icon(icon);
    return filled
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: iconWidget,
            label: child,
            style: style,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: iconWidget,
            label: child,
            style: style,
          );
  }
}
