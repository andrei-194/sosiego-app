import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../data/user/providers.dart';
import '../../data/services/tts_service.dart';
import '../../domain/feed_mode.dart';
import '../../domain/user_data.dart';
import '../../l10n/l10n.dart';
import 'feed_controller.dart';
import 'seen_recorder.dart';
import 'verse_actions.dart';
import 'verse_card.dart';

/// Identifica esta sesión de la app: la ayuda del feed solo aparece en la
/// primera sesión (spec HU-04.2).
final _sessionId = DateTime.now().microsecondsSinceEpoch.toString();

/// ¿Se muestra la ayuda «Desliza o toca Siguiente»? Sí durante la primera
/// sesión en que se abre el feed; en las siguientes, no.
final feedHintProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final state = await ref.read(appStateRepositoryProvider.future);
    final stored = await state.get(AppStateKeys.feedHintSession);
    if (stored == null) {
      await state.set(AppStateKeys.feedHintSession, _sessionId);
      return true;
    }
    return stored == _sessionId;
  } catch (_) {
    return false;
  }
});

/// Nombre que va en la etiqueta del modo: el tema, el momento o la referencia
/// del versículo del que se piden parecidos.
final feedModeNameProvider = FutureProvider.autoDispose
    .family<String?, FeedMode>((ref, mode) async {
      final repo = await ref.watch(contentRepositoryProvider.future);
      return switch (mode.kind) {
        FeedModeKind.general => null,
        FeedModeKind.theme => repo.themeBySlug(mode.slug ?? '')?.name,
        FeedModeKind.moment => repo.momentBySlug(mode.slug ?? '')?.name,
        FeedModeKind.similar => repo.byId(mode.verseId ?? 0)?.reference,
      };
    });

/// Feed vertical (pestaña Versículos): un versículo por pantalla, con
/// Anterior y Siguiente además del deslizamiento. [mode] lo limita a un tema,
/// un momento o los parecidos a un versículo (spec §4 y HU-05).
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.mode = FeedMode.general});

  final FeedMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedControllerProvider(mode));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: feed.when(
        loading: () => const WarmBackdrop(child: _LoadingView()),
        error: (e, _) => WarmBackdrop(
          child: SafeArea(
            child: _ErrorView(
              onRetry: () => ref.invalidate(feedControllerProvider(mode)),
            ),
          ),
        ),
        data: (state) => state.items.isEmpty
            ? WarmBackdrop(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.s16,
                          Gap.s8,
                          Gap.s8,
                          0,
                        ),
                        child: FeedTopBar(mode: mode),
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.menu_book_outlined,
                          title: context.l10n.topicEmptyTitle,
                          message: context.l10n.topicEmptyBody,
                          actionLabel: context.l10n.feedEndBack,
                          onAction: () => context.go('/versiculos'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _FeedPager(mode: mode, initial: state),
      ),
    );
  }
}

/// Franja superior del feed: la etiqueta «Tema: nombre · Salir» (si hay modo)
/// y el acceso a Ajustes. La etiqueta entera es el botón de salir.
class FeedTopBar extends ConsumerWidget {
  const FeedTopBar({super.key, required this.mode});

  final FeedMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final name = mode.kind == FeedModeKind.general
        ? null
        : ref.watch(feedModeNameProvider(mode)).valueOrNull;
    final label = name == null
        ? null
        : mode.kind == FeedModeKind.similar
        ? l.feedModeSimilar(name)
        : l.feedModeTheme(name);
    return Row(
      children: [
        Expanded(
          child: label == null
              ? const SizedBox(height: AppSize.minTarget)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: label,
                    excludeSemantics: true,
                    onTap: () => context.go('/versiculos'),
                    child: Material(
                      color: scheme.onSurface.withValues(alpha: 0.1),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('feed-exit'),
                        onTap: () => context.go('/versiculos'),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSize.minChip,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Gap.s16,
                              vertical: Gap.s8,
                            ),
                            child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: iconLabelMaxScale,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: AppFont.secondary + 2,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        const SettingsButton(),
      ],
    );
  }
}

class _FeedPager extends ConsumerStatefulWidget {
  const _FeedPager({required this.mode, required this.initial});

  final FeedMode mode;
  final FeedState initial;

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initial.cursor,
  );
  Timer? _seenTimer;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La pestaña Versículos sigue montada al ir a otra: no cuenta como visto.
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled != _visible || _seenTimer == null) {
      _visible = enabled;
      enabled ? _armSeenTimer() : _seenTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _seenTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  FeedState? get _state =>
      ref.read(feedControllerProvider(widget.mode)).valueOrNull;

  /// Un versículo visible 2 segundos se anota en `history` y marca el día
  /// (spec §4.6 y HU-11.1).
  void _armSeenTimer() {
    _seenTimer?.cancel();
    final verse = _state?.current;
    if (verse == null) return;
    _seenTimer = Timer(AppDuration.seen, () {
      if (mounted && _visible) {
        ref.read(seenRecorderProvider).record(verse.id);
      }
    });
  }

  void _onPageChanged(int i) {
    // La lectura en voz alta no sigue sonando en el versículo anterior.
    ref.read(ttsControllerProvider.notifier).stop();
    ref.read(feedControllerProvider(widget.mode).notifier).moveTo(i);
    _armSeenTimer();
  }

  void _go(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: AppDuration.transition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    // Al recortar la pila de atrás, la página visible cambia de número.
    ref.listen(feedControllerProvider(mode), (prev, next) {
      final a = prev?.valueOrNull;
      final b = next.valueOrNull;
      if (a != null && b != null && a.trimmed != b.trimmed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) _controller.jumpToPage(b.cursor);
        });
      }
    });
    final state =
        ref.watch(feedControllerProvider(mode)).valueOrNull ?? widget.initial;
    final hint = ref.watch(feedHintProvider).valueOrNull ?? false;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final pages = state.items.length + (mode.isFinite ? 1 : 0);

    return PageView.builder(
      key: const Key('feed'),
      controller: _controller,
      scrollDirection: Axis.vertical,
      itemCount: pages,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, i) {
        final Widget page;
        if (i >= state.items.length) {
          page = _EndCard(
            mode: mode,
            last: state.items.last,
            onPrevious: () => _go(i - 1),
          );
        } else {
          page = VerseCard(
            verse: state.items[i],
            topBar: FeedTopBar(mode: mode),
            showHint: hint && i < 3,
            onPrevious: i == 0 ? null : () => _go(i - 1),
            onNext: () {
              if (i + 1 < pages) _go(i + 1);
            },
          );
        }
        if (reduceMotion) return page;
        // Fundido y leve desplazamiento mientras la página entra o sale.
        return AnimatedBuilder(
          animation: _controller,
          child: page,
          builder: (context, child) {
            final current =
                _controller.hasClients && _controller.position.haveDimensions
                ? (_controller.page ?? i.toDouble())
                : state.cursor.toDouble();
            final d = (current - i).clamp(-1.0, 1.0);
            return Opacity(
              opacity: 1 - 0.65 * d.abs(),
              child: Transform.translate(
                offset: Offset(0, d * 28),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

/// Tarjeta final de los modos de lista fija (spec HU-05.2): «Volver al feed» y
/// «Ver más parecidos» (los parecidos del último versículo).
class _EndCard extends ConsumerWidget {
  const _EndCard({
    required this.mode,
    required this.last,
    required this.onPrevious,
  });

  final FeedMode mode;
  final Verse last;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final palette = VerseCard.paletteFor(context, last);
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    // El botón solo sale si el versículo tiene parecidos (HU-05.3).
    final hasSimilar = repo != null && repo.similarIds(last.id).isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.gradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s16,
                Gap.s8,
                Gap.s8,
                Gap.s4,
              ),
              child: FeedTopBar(mode: mode),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.s32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.feedEndTitle,
                            key: const Key('feed-end'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.verseFont,
                              fontSize: 26,
                              height: 1.35,
                              color: palette.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: Gap.s12),
                        Text(
                          l.feedEndBody,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppFont.body,
                            height: 1.45,
                            color: palette.text.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: Gap.s32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('feed-end-back'),
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.accent,
                              foregroundColor: palette.top,
                            ),
                            onPressed: () => context.go('/versiculos'),
                            child: Text(l.feedEndBack),
                          ),
                        ),
                        if (hasSimilar) ...[
                          const SizedBox(height: Gap.s12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              key: const Key('feed-end-similar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                  AppSize.minTarget,
                                ),
                                foregroundColor: palette.text,
                                side: BorderSide(
                                  color: palette.text.withValues(alpha: 0.55),
                                ),
                              ),
                              onPressed: () => openSimilar(context, last.id),
                              child: Text(l.feedEndMoreSimilar),
                            ),
                          ),
                        ],
                        const SizedBox(height: Gap.s12),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSize.minTarget,
                            ),
                            foregroundColor: palette.text,
                          ),
                          onPressed: onPrevious,
                          child: Text(l.actionPrevious),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDuration.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.feedLoadingSemantics,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.25, end: 0.8).animate(_pulse),
                child: Text(
                  '“',
                  style: TextStyle(
                    fontFamily: AppTheme.verseFont,
                    fontSize: 120,
                    height: 0.9,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: Gap.s8),
              Text(
                context.l10n.feedLoading,
                style: TextStyle(
                  fontFamily: AppTheme.verseFont,
                  fontStyle: FontStyle.italic,
                  fontSize: 20,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: Gap.s20),
            Text(
              context.l10n.feedErrorTitle,
              key: const Key('error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.verseFont,
                fontSize: 24,
                height: 1.4,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.feedErrorBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFont.body,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.feedRetry),
            ),
          ],
        ),
      ),
    );
  }
}
