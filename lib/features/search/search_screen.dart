import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_chip.dart';
import '../../core/widgets/theme_icons.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../domain/text_normalizer.dart';
import '../../domain/use_cases.dart';
import '../../l10n/l10n.dart';
import '../feed/verse_actions.dart';
import '../help/help_line_block.dart';
import '../home/home_screen.dart';
import '../home/topic_navigation.dart';

/// Buscador único (spec HU-06): un campo, y la entrada se resuelve en orden
/// referencia, tema o momento y texto. Espera 250 ms tras dejar de escribir.
/// Lo escrito vive solo en memoria: no hay búsquedas recientes (HU-06.10).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  SearchOutcome? _outcome;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _query = '';
        _outcome = null;
      });
      return;
    }
    _debounce = Timer(AppDuration.searchDebounce, () => _run(q));
  }

  void _run(String q) {
    final search = ref.read(searchVersesProvider).valueOrNull;
    final text = q.trim();
    setState(() {
      _query = text;
      _outcome = search == null || text.isEmpty ? null : search(text);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _outcome = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Si la base termina de abrirse con una consulta ya escrita, reintenta.
    ref.listen(searchVersesProvider, (_, _) {
      if (_query.isNotEmpty) _run(_query);
    });
    final outcome = _outcome;
    final words = ContentRepository.queryTokens(_query);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: l.searchTitle,
              subtitle: l.searchSubtitle,
              showSettings: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s8,
                Gap.s24,
                Gap.s8,
              ),
              child: _SearchField(
                controller: _controller,
                onChanged: _onChanged,
                onClear: _clear,
              ),
            ),
          ),
          if (_query.isEmpty)
            const SliverToBoxAdapter(child: _FeelingChips(showHint: true))
          else if (outcome == null)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else if (outcome.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.s24,
                  Gap.s16,
                  Gap.s24,
                  0,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l.searchNoResultsTitle,
                    key: const Key('search-empty'),
                    style: AppText.heading(context),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _FeelingChips()),
            if (outcome.crisis) const _HelpSliver(),
          ] else ...[
            if (outcome.topic != null)
              SliverToBoxAdapter(child: _TopicButton(match: outcome.topic!)),
            if (outcome.referenceVerses.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s24, 0),
                sliver: SliverList.separated(
                  itemCount: outcome.referenceVerses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.s12),
                  itemBuilder: (_, i) =>
                      _ReferenceItem(verse: outcome.referenceVerses[i]),
                ),
              ),
            if (outcome.textMatches.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.s24,
                    Gap.s16,
                    Gap.s24,
                    Gap.s8,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l.searchResultCount(outcome.textMatches.length),
                      style: AppText.body(context),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
                sliver: SliverList.separated(
                  itemCount: outcome.textMatches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.s12),
                  itemBuilder: (_, i) =>
                      _ResultTile(verse: outcome.textMatches[i], words: words),
                ),
              ),
            ],
            if (outcome.crisis) const _HelpSliver(),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Gap.s32)),
        ],
      ),
    );
  }
}

class _HelpSliver extends StatelessWidget {
  const _HelpSliver();

  @override
  Widget build(BuildContext context) => const SliverPadding(
    padding: EdgeInsets.fromLTRB(Gap.s24, Gap.s24, Gap.s24, 0),
    sliver: SliverToBoxAdapter(child: HelpLineBlock()),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      key: const Key('search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: AppFont.action + 2, color: scheme.onSurface),
      cursorColor: scheme.primary,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        hintStyle: TextStyle(
          fontSize: AppFont.action,
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: context.softSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.s20,
          vertical: Gap.s20,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 28),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: context.l10n.searchClearTooltip,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.block),
          borderSide: BorderSide(color: context.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.block),
          borderSide: BorderSide(color: context.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.block),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// Sugerencias fijas del campo vacío y de «sin resultados»: los chips de
/// emoción (HU-06.7 y 06.10).
class _FeelingChips extends ConsumerWidget {
  const _FeelingChips({this.showHint = false});

  final bool showHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final emotions = ref.watch(emotionsProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l.searchFeelingsTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
          child: Wrap(
            spacing: Gap.s8,
            runSpacing: Gap.s8,
            children: [
              for (final t in emotions)
                SoftChip(
                  key: Key('search-emotion-${t.slug}'),
                  label: t.name,
                  icon: contentIcon(t.icon),
                  minHeight: AppSize.minTarget,
                  onTap: () => openEmotion(context, t.slug),
                ),
            ],
          ),
        ),
        if (showHint)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s24, Gap.s24, 0),
            child: Text(l.searchTip, style: AppText.body(context)),
          ),
      ],
    );
  }
}

/// Atajo «Ver versículos sobre ansiedad» (HU-06.4): abre el feed en modo tema.
class _TopicButton extends StatelessWidget {
  const _TopicButton({required this.match});

  final TopicMatch match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s24, Gap.s8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('search-topic'),
          onPressed: () =>
              openThemeFeed(context, match.slug, isMoment: match.isMoment),
          icon: const Icon(Icons.auto_stories_outlined),
          label: Text(context.l10n.searchTopicButton(match.name.toLowerCase())),
        ),
      ),
    );
  }
}

/// Un versículo de un capítulo o rango, con las mismas acciones que el feed.
class _ReferenceItem extends StatelessWidget {
  const _ReferenceItem({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(Gap.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse.reference,
            style: AppText.label(context)
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: Gap.s8),
          Text(verse.text, style: AppText.verse(context)),
          const SizedBox(height: Gap.s8),
          VerseActions(verse: verse),
        ],
      ),
    );
  }
}

/// Un resultado de texto: referencia en negrita, hasta dos líneas con la
/// palabra resaltada y, al tocar, el versículo con sus acciones (HU-06.6).
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.verse, required this.words});

  final Verse verse;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = AppText.verse(context, size: AppFont.verse - 2);
    return SoftCard(
      onTap: () => context.push('/verso/${verse.id}'),
      semanticLabel: context.l10n.verseSemantics(verse.text, verse.reference),
      padding: const EdgeInsets.all(Gap.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse.reference,
            style: TextStyle(
              fontFamily: AppTheme.uiFont,
              fontSize: AppFont.body,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: Gap.s4),
          Text.rich(
            highlightSpans(
              verse.text,
              words,
              base,
              base.copyWith(
                fontWeight: FontWeight.bold,
                backgroundColor: context.accentWash,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Parte [text] en trozos y resalta las palabras que empiezan con alguna de
/// [words] (ya normalizadas). La normalización conserva la longitud, así que
/// los índices del texto normalizado valen para el original.
TextSpan highlightSpans(
  String text,
  List<String> words,
  TextStyle base,
  TextStyle highlight,
) {
  if (words.isEmpty) return TextSpan(text: text, style: base);
  final norm = normalizeText(text);
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in RegExp(r'[a-z0-9]+').allMatches(norm)) {
    final word = m.group(0)!;
    if (words.any(word.startsWith)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      spans.add(
        TextSpan(text: text.substring(m.start, m.end), style: highlight),
      );
      last = m.end;
    }
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return TextSpan(children: spans, style: base);
}
