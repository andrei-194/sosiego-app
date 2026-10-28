import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/card_style.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../data/services/share_service.dart';
import '../../domain/share_text.dart';
import '../../l10n/l10n.dart';
import 'share_card.dart';

/// Carpeta temporal donde se guarda la imagen (se sustituye en las pruebas).
final shareTempDirProvider = Provider<Future<Directory> Function()>(
  (_) => getTemporaryDirectory,
);

/// Enlace corto del versículo (`https://{dominio}/v/juan-3-16`).
String verseShareLink(Verse v) => verseLink(
  bookSlug: v.bookSlug.isNotEmpty ? v.bookSlug : bookSlugFromName(v.bookName),
  chapter: v.chapter,
  verse: v.verse,
);

/// CONTRATO (HU-09): abre la hoja de compartir del versículo (vista previa 9:16,
/// estilos, «Para:», imagen y WhatsApp). [headline] sirve a las tarjetas de
/// racha («7 días con la Palabra»): encabeza la tarjeta.
///
/// Dos toques: «Compartir» y «Compartir imagen». La dedicatoria vive solo en
/// esta hoja: no se guarda ni se envía a ningún servidor.
Future<void> showShareSheet(
  BuildContext context, {
  required Verse verse,
  String? headline,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.block)),
  ),
  builder: (_) => ShareSheet(verse: verse, headline: headline),
);

class ShareSheet extends ConsumerStatefulWidget {
  const ShareSheet({super.key, required this.verse, this.headline});

  final Verse verse;
  final String? headline;

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  final _boundaryKey = GlobalKey();
  final _field = TextEditingController();
  late CardStyle _style = CardStyle.forVerse(widget.verse.id);
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String get _link => verseShareLink(widget.verse);

  String get _text => buildShareText(
    verseText: widget.verse.text,
    reference: widget.verse.reference,
    link: _link,
    dedication: _field.text,
  );

  Future<void> _shareImage() async {
    if (_busy) return;
    final l = context.l10n;
    final service = ref.read(shareServiceProvider);
    final tempDir = ref.read(shareTempDirProvider);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final bytes = await encodeCardPng(boundary);
      final dir = await tempDir();
      // El nombre no lleva la dedicatoria: solo versículo y estilo.
      final file = File(
        p.join(dir.path, 'share_${widget.verse.id}_${_style.id}.png'),
      );
      await file.writeAsBytes(bytes, flush: true);
      await service.shareImage(path: file.path, text: _text);
    } catch (_) {
      if (mounted) setState(() => _message = l.shareImageError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendWhatsapp() async {
    final l = context.l10n;
    final ok = await ref
        .read(shareServiceProvider)
        .openWhatsapp(whatsappUri(_text));
    if (!ok && mounted) setState(() => _message = l.shareWhatsappError);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mq = MediaQuery.of(context);
    final scheme = Theme.of(context).colorScheme;
    final previewHeight = (mq.size.height * 0.36).clamp(200.0, 360.0);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Column(
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
                      l.shareSheetTitle,
                      style: AppText.heading(context),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.shareClose,
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
                Gap.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _preview(previewHeight, l)),
                  const SizedBox(height: Gap.s20),
                  Semantics(
                    header: true,
                    child: Text(
                      l.shareStylesLabel,
                      style: AppText.label(context),
                    ),
                  ),
                  const SizedBox(height: Gap.s8),
                  _StylePicker(
                    selected: _style,
                    onSelected: (s) => setState(() => _style = s),
                  ),
                  const SizedBox(height: Gap.s20),
                  TextField(
                    key: const Key('share-dedication'),
                    controller: _field,
                    maxLength: maxDedicationLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: l.shareToLabel,
                      hintText: l.shareToHint,
                      helperText: l.shareToHelper,
                      helperMaxLines: 2,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: Gap.s12),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: Gap.s8),
                          Expanded(
                            child: Text(
                              _message!,
                              key: const Key('share-message'),
                              style: AppText.body(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Los dos botones quedan siempre a la vista, fuera del desplazamiento.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s24,
              Gap.s8,
              Gap.s24,
              Gap.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('share-image'),
                  onPressed: _busy ? null : _shareImage,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(
                    _busy ? l.shareImagePreparing : l.shareImageButton,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                  ),
                ),
                const SizedBox(height: Gap.s12),
                OutlinedButton.icon(
                  key: const Key('share-whatsapp'),
                  onPressed: _sendWhatsapp,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(l.shareWhatsappButton),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.minTarget),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vista previa 9:16: la misma tarjeta de 1080 × 1920 reducida. Lo que se ve
  /// es lo que se envía.
  Widget _preview(double height, AppLocalizations l) {
    final width = height * 9 / 16;
    return Semantics(
      container: true,
      label: l.sharePreviewSemantics(_style.name, widget.verse.reference),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            width: width,
            height: height,
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: ShareCard(
                  verseText: widget.verse.text,
                  reference: widget.verse.reference,
                  link: _link,
                  appName: l.appTitle,
                  style: _style,
                  dedication: _field.text,
                  headline: widget.headline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de estilos: todos a la vista (sin deslizar), cada uno con su
/// nombre y de 56 dp o más.
class _StylePicker extends StatelessWidget {
  const _StylePicker({required this.selected, required this.onSelected});

  final CardStyle selected;
  final ValueChanged<CardStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelWidth = math.max(
      72.0,
      MediaQuery.textScalerOf(context).scale(14) * 6.2,
    );
    return Wrap(
      spacing: Gap.s8,
      runSpacing: Gap.s12,
      children: [
        for (final s in CardStyle.all)
          Semantics(
            button: true,
            selected: s.id == selected.id,
            label: s.name,
            excludeSemantics: true,
            onTap: () => onSelected(s),
            child: InkWell(
              key: Key('style-${s.id}'),
              borderRadius: BorderRadius.circular(AppRadius.small),
              onTap: () => onSelected(s),
              child: SizedBox(
                width: labelWidth,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: shareCardPalette(s).gradient,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(
                          color: s.id == selected.id
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.25),
                          width: s.id == selected.id ? 3 : 1,
                        ),
                      ),
                      child: s.id == selected.id
                          ? Icon(
                              Icons.check_rounded,
                              color: shareCardPalette(s).accent,
                            )
                          : null,
                    ),
                    const SizedBox(height: Gap.s4),
                    Text(
                      s.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: s.id == selected.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
