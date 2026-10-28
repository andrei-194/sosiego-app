import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_chip.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_tile.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../domain/verse_reference.dart';
import '../../l10n/l10n.dart';

/// Resultado de interpretar lo escrito: una referencia (versículo o capítulo)
/// y/o coincidencias de texto libre (FTS5, sin tildes).
class _Outcome {
  const _Outcome({this.chapterRef, this.refVerse, this.matches = const []});
  final VerseReference? chapterRef;
  final Verse? refVerse;
  final List<Verse> matches;

  bool get isEmpty => chapterRef == null && refVerse == null && matches.isEmpty;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  _Outcome? _outcome;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    final text = q.trim();
    final repo = ref.read(contentRepositoryProvider).valueOrNull;
    _Outcome? outcome;
    if (text.isNotEmpty && repo != null) {
      final ref0 = parseReference(text);
      Verse? verse;
      VerseReference? chapterRef;
      if (ref0 != null) {
        if (ref0.verseId != null) {
          verse = repo.byId(ref0.verseId!);
        } else if (repo.chapterVerses(ref0.bookId, ref0.chapter).isNotEmpty) {
          chapterRef = ref0;
        }
      }
      outcome = _Outcome(
        chapterRef: chapterRef,
        refVerse: verse,
        matches: repo.search(text).where((v) => v.id != verse?.id).toList(),
      );
    }
    setState(() {
      _query = text;
      _outcome = outcome;
    });
  }

  void _fill(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _setQuery(text);
  }

  @override
  Widget build(BuildContext context) {
    // Si la base termina de abrirse con una consulta ya escrita, reintenta.
    ref.listen(contentRepositoryProvider, (_, _) => _setQuery(_query));

    return SafeArea(
      bottom: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: Gap.s32),
        children: [
          ScreenHeader(
            title: context.l10n.searchTitle,
            subtitle: context.l10n.searchSubtitle,
            showSettings: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s24,
              Gap.s8,
              Gap.s24,
              Gap.s8,
            ),
            child: _SearchField(
              controller: _controller,
              onChanged: _setQuery,
              onClear: () => _fill(''),
            ),
          ),
          if (_query.isEmpty)
            _Suggestions(onPick: _fill)
          else if (_outcome == null)
            const SizedBox.shrink()
          else if (_outcome!.isEmpty)
            _NoResults(query: _query, onPick: _fill)
          else
            _Results(outcome: _outcome!),
        ],
      ),
    );
  }
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
      style: TextStyle(fontSize: 20, color: scheme.onSurface),
      cursorColor: scheme.primary,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        hintStyle: TextStyle(
          fontSize: 20,
          color: scheme.onSurface.withValues(alpha: 0.6),
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

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final refs = l.searchSuggestionRefs.split('|');
    final words = l.searchSuggestionWords.split('|');
    Widget chips(List<String> items, {IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
      child: Wrap(
        spacing: Gap.s8,
        runSpacing: Gap.s8,
        children: [
          for (final s in items)
            SoftChip(label: s, icon: icon, onTap: () => onPick(s)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l.searchWithCitation),
        chips(refs, icon: Icons.menu_book_outlined),
        SectionTitle(l.searchWithWord),
        chips(words),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s32, Gap.s24, Gap.s8),
          child: Text(l.searchTip, style: AppText.body(context)),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onPick});
  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        const SizedBox(height: Gap.s32),
        SizedBox(
          height: 320,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: l.searchNoResultsTitle(query),
            message: l.searchNoResultsBody,
          ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.outcome});
  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = outcome.matches.length;
    final cr = outcome.chapterRef;
    String bookName(int id) => bibleBooks.firstWhere((b) => b.id == id).name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Gap.s8),
          if (cr != null) ...[
            SoftCard(
              onTap: () => context.push('/capitulo/${cr.bookId}/${cr.chapter}'),
              color: context.accentWash,
              semanticLabel: l.searchReadChapterSemantics(
                bookName(cr.bookId),
                cr.chapter,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Gap.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.bookChapter(bookName(cr.bookId), cr.chapter),
                          style: AppText.label(context),
                        ),
                        Text(
                          l.searchReadChapterFull,
                          style: AppText.body(context),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: Gap.s16),
          ],
          if (outcome.refVerse != null) ...[
            VerseTile(
              text: outcome.refVerse!.text,
              reference: outcome.refVerse!.reference,
              onTap: () => context.push('/verso/${outcome.refVerse!.id}'),
            ),
            const SizedBox(height: Gap.s16),
          ],
          if (count > 0) ...[
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.s8),
                child: Text(
                  l.searchResultCount(count),
                  style: AppText.body(context),
                ),
              ),
            ),
            for (final v in outcome.matches) ...[
              VerseTile(
                text: v.text,
                reference: v.reference,
                onTap: () => context.push('/verso/${v.id}'),
              ),
              const SizedBox(height: Gap.s12),
            ],
          ],
        ],
      ),
    );
  }
}
