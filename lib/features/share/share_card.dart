import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/card_style.dart';
import '../../domain/share_text.dart';

/// Medidas EXACTAS de la tarjeta (spec §9), en píxeles de la imagen final.
class ShareCardSpec {
  static const double width = 1080;
  static const double height = 1920;
  static const double marginSide = 96;
  static const double marginTop = 200;
  static const double marginBottom = 200;

  /// Cuadro del versículo: 888 × 1100.
  static const double verseBoxWidth = 888;
  static const double verseBoxHeight = 1100;
  static const double verseMaxSize = 72;
  static const double verseMinSize = 36;
  static const double verseLineHeight = 1.3;

  static const double dedicationSize = 56;
  static const double headlineSize = 56;
  static const double referenceSize = 44;
  static const double appNameSize = 32;
  static const double linkSize = 28;
}

/// Variante del estilo que usa SIEMPRE la tarjeta compartida: la clara.
/// Es fija e independiente del tema de la app: la imagen sale igual para
/// quien la envía con el teléfono en oscuro y para quien la recibe, y los
/// degradados claros son los que mejor se leen sobre el fondo de WhatsApp y
/// de las historias.
CardPalette shareCardPalette(CardStyle style) => style.light;

TextStyle verseCardStyle(
  double size, [
  Color color = const Color(0xFF000000),
]) => TextStyle(
  fontFamily: AppTheme.verseFont,
  fontSize: size,
  height: ShareCardSpec.verseLineHeight,
  color: color,
);

/// Resultado del ajuste de tamaño del versículo.
class FittedVerse {
  const FittedVerse(this.fontSize, this.maxLines);

  /// Tamaño elegido, entre 36 y 72 px.
  final double fontSize;

  /// `null` si el versículo cabe completo; si no, las líneas que caben a
  /// 36 px y el texto termina en «…».
  final int? maxLines;

  bool get truncated => maxLines != null;
}

double _heightAt(String text, double size, {int? maxLines}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: verseCardStyle(size)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    textScaler: TextScaler.noScaling,
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: ShareCardSpec.verseBoxWidth);
  final h = painter.height;
  painter.dispose();
  return h;
}

/// Búsqueda binaria del tamaño de letra más grande (enteros de 36 a 72 px)
/// con el que [text] cabe en 888 × 1100 px. Si ni a 36 px cabe, devuelve 36 y
/// las líneas que caben, para cortar con «…».
FittedVerse fitVerseText(
  String text, {
  double maxHeight = ShareCardSpec.verseBoxHeight,
}) {
  var lo = ShareCardSpec.verseMinSize.toInt();
  var hi = ShareCardSpec.verseMaxSize.toInt();
  if (_heightAt(text, lo.toDouble()) > maxHeight) {
    final line = _heightAt('A', lo.toDouble());
    var lines = math.max(1, (maxHeight / line).floor());
    while (lines > 1 &&
        _heightAt(text, lo.toDouble(), maxLines: lines) > maxHeight) {
      lines--;
    }
    return FittedVerse(lo.toDouble(), lines);
  }
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (_heightAt(text, mid.toDouble()) <= maxHeight) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return FittedVerse(lo.toDouble(), null);
}

/// La tarjeta, dibujada a 1080 × 1920 px lógicos (la vista previa la reduce
/// con un `FittedBox`; la imagen se captura con `pixelRatio = 1080 / ancho`).
/// No depende del tema, del tamaño de letra del sistema ni del idioma del
/// teléfono: todo es fijo para que salga igual en todos los teléfonos.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.verseText,
    required this.reference,
    required this.link,
    required this.appName,
    required this.style,
    this.dedication,
    this.headline,
  });

  final String verseText;
  final String reference;

  /// Enlace completo (`https://…`); en la tarjeta se muestra sin esquema.
  final String link;
  final String appName;
  final CardStyle style;
  final String? dedication;
  final String? headline;

  @override
  Widget build(BuildContext context) {
    final palette = shareCardPalette(style);
    final name = cleanDedication(dedication);
    final fitted = fitVerseText(verseText);
    TextStyle uiStyle(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: AppTheme.uiFont,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.25,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: SizedBox(
          width: ShareCardSpec.width,
          height: ShareCardSpec.height,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: palette.gradient),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ShareCardSpec.marginSide,
                ShareCardSpec.marginTop,
                ShareCardSpec.marginSide,
                ShareCardSpec.marginBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (headline != null && headline!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      // Una sola línea: si es larga se achica para caber.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          headline!.trim(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          textScaler: TextScaler.noScaling,
                          style: uiStyle(
                            ShareCardSpec.headlineSize,
                            FontWeight.w700,
                            palette.text,
                          ),
                        ),
                      ),
                    ),
                  if (name != null)
                    Text(
                      dedicationLine(name),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: uiStyle(
                        ShareCardSpec.dedicationSize,
                        FontWeight.w600,
                        palette.accent,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: ShareCardSpec.verseBoxWidth,
                            child: Text(
                              verseText,
                              textAlign: TextAlign.center,
                              maxLines: fitted.maxLines,
                              overflow: fitted.truncated
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip,
                              textScaler: TextScaler.noScaling,
                              style: verseCardStyle(
                                fitted.fontSize,
                                palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 56),
                          Container(
                            width: 96,
                            height: 6,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            reference,
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.noScaling,
                            style: uiStyle(
                              ShareCardSpec.referenceSize,
                              FontWeight.w700,
                              palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        textScaler: TextScaler.noScaling,
                        style: uiStyle(
                          ShareCardSpec.appNameSize,
                          FontWeight.w700,
                          palette.accent,
                        ),
                      ),
                      Text(
                        displayLink(link),
                        textScaler: TextScaler.noScaling,
                        style: uiStyle(
                          ShareCardSpec.linkSize,
                          FontWeight.w400,
                          palette.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convierte lo que dibuja [boundary] en un PNG de 1080 px de ancho
/// (`pixelRatio = 1080 / ancho lógico`).
Future<Uint8List> encodeCardPng(RenderRepaintBoundary boundary) async {
  final ratio = ShareCardSpec.width / boundary.size.width;
  final image = await boundary.toImage(pixelRatio: ratio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('No se pudo codificar la imagen');
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
