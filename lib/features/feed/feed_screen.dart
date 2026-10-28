import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/content/content_repository.dart';
import '../streak/streak_chip.dart';
import 'feed_controller.dart';
import 'verse_card.dart';
import '../../l10n/l10n.dart';
import '../../core/theme/tokens.dart';

/// Feed vertical: un versículo por pantalla, deslizando hacia arriba.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedControllerProvider);
    final colors = AppTheme.backdrop(Theme.of(context).brightness);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: SizedBox.expand(
          child: feed.when(
            loading: () => const _LoadingView(),
            error: (e, _) => _ErrorView(
              onRetry: () => ref.invalidate(feedControllerProvider),
            ),
            data: (verses) => _FeedPager(verses: verses),
          ),
        ),
      ),
    );
  }
}

class _FeedPager extends ConsumerStatefulWidget {
  const _FeedPager({required this.verses});

  final List<Verse> verses;

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  /// Cuántas tarjetas antes del final se pide la siguiente tanda.
  static const _prefetchMargin = 3;

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    if (i >= widget.verses.length - _prefetchMargin) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        PageView.builder(
          key: const Key('feed'),
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.verses.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (_, i) {
            final card = VerseCard(verse: widget.verses[i]);
            if (reduceMotion) return card;
            // Fundido y leve desplazamiento mientras la tarjeta entra o sale.
            return AnimatedBuilder(
              animation: _controller,
              child: card,
              builder: (context, child) {
                final page =
                    _controller.hasClients &&
                        _controller.position.haveDimensions
                    ? (_controller.page ?? 0)
                    : _index.toDouble();
                final d = (page - i).clamp(-1.0, 1.0);
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
        ),
        // Franja superior mínima: racha (izquierda) y ajustes (derecha).
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StreakChip(),
                    ),
                  ),
                  SettingsButton(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              // Con letra muy grande el contenido ya llena la pantalla: sin pista.
              child: _SwipeHint(
                visible:
                    _index == 0 &&
                    MediaQuery.textScalerOf(context).scale(1) < 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicación "desliza" que rebota unas pocas veces y se apaga al avanzar.
class _SwipeHint extends StatefulWidget {
  const _SwipeHint({required this.visible});

  final bool visible;

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppDuration.hintCycle,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      // Finito (3 rebotes): luego queda quieto y no consume frames.
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: AppDuration.fade,
        child: Semantics(
          label: context.l10n.feedSwipeHintSemantics,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                // Primero ~0.9 s de pausa, luego 3 rebotes.
                final t = ((_anim.value - 0.18) / 0.82).clamp(0.0, 1.0);
                final bounce = (1 - math.cos(t * 2 * math.pi * 3)) / 2;
                return Transform.translate(
                  offset: Offset(0, -8 * bounce),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 32,
                        color: scheme.primary,
                      ),
                      Text(
                        context.l10n.feedSwipeHint,
                        style: TextStyle(
                          fontSize: 15,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
              const SizedBox(height: 8),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: 20),
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
                fontSize: 17,
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
