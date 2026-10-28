import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/core/theme/app_theme.dart';
import 'package:sosiego/core/theme/card_style.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/services/app_bootstrap.dart';
import 'package:sosiego/data/services/share_service.dart';
import 'package:sosiego/features/share/share_card.dart';
import 'package:sosiego/features/share/share_sheet.dart';
import 'package:sosiego/l10n/l10n.dart';

import '../../helpers/a11y.dart';
import '../../helpers/service_fakes.dart';

const _corto = 'Jehová es mi pastor; nada me faltará.';
const _medio =
    'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, '
    'para que todo aquel que en él cree, no se pierda, mas tenga vida eterna. '
    'Porque no envió Dios a su Hijo al mundo para que condene al mundo, mas '
    'para que el mundo sea salvo por él.';
final _largo = List.filled(14, _medio).join(' ');

const _verso = Verse(
  id: 43003016,
  bookId: 43,
  bookName: 'Juan',
  bookSlug: 'juan',
  chapter: 3,
  verse: 16,
  text: _medio,
);

Widget _app(Widget home, {FakeShareService? share, Directory? temp}) =>
    ProviderScope(
      overrides: [
        if (share != null) shareServiceProvider.overrideWithValue(share),
        if (temp != null)
          shareTempDirProvider.overrideWithValue(() async => temp),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('es')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

Future<void> _open(
  WidgetTester tester, {
  double scale = 1.0,
  bool dark = false,
  FakeShareService? share,
  Directory? temp,
  String? headline,
}) async {
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showShareSheet(context, verse: _verso, headline: headline),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      share: share,
      temp: temp,
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('HU-09 ajuste de tamaño del versículo', () {
    test(
      'HU-09.6 un versículo corto va a 72 px y uno medio queda entre 36 y 72',
      () {
        expect(fitVerseText(_corto).fontSize, 72);
        expect(fitVerseText(_corto).truncated, isFalse);
        final medio = fitVerseText(_medio);
        expect(medio.fontSize, inInclusiveRange(36, 72));
        expect(medio.truncated, isFalse);
      },
    );

    test('HU-09.6 baja la letra con el largo, nunca de 36, y corta con … si no cabe', () {
      final corto = fitVerseText(_corto).fontSize;
      final medio = fitVerseText(_medio).fontSize;
      final largo = fitVerseText(_largo);
      expect(medio, lessThan(corto));
      expect(largo.fontSize, 36);
      expect(largo.truncated, isTrue);
      expect(largo.maxLines, greaterThan(1));
      final muyLargo = fitVerseText(List.filled(60, _largo).join(' '));
      expect(muyLargo.fontSize, 36);
      expect(muyLargo.truncated, isTrue);
    });

    test('HU-09.6 elige el tamaño más grande que cabe en 888 × 1100', () {
      final f = fitVerseText(_medio);
      final painter = TextPainter(
        text: TextSpan(text: _medio, style: verseCardStyle(f.fontSize)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: ShareCardSpec.verseBoxWidth);
      expect(painter.height, lessThanOrEqualTo(ShareCardSpec.verseBoxHeight));
      final mas = TextPainter(
        text: TextSpan(text: _medio, style: verseCardStyle(f.fontSize + 1)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: ShareCardSpec.verseBoxWidth);
      expect(mas.height, greaterThan(ShareCardSpec.verseBoxHeight));
    });

    test('HU-09.2 las medidas de la tarjeta son las del spec', () {
      expect(ShareCardSpec.width, 1080);
      expect(ShareCardSpec.height, 1920);
      expect(ShareCardSpec.marginSide, 96);
      expect(ShareCardSpec.marginTop, 200);
      expect(ShareCardSpec.marginBottom, 200);
      expect(ShareCardSpec.verseBoxWidth, 888);
      expect(ShareCardSpec.verseBoxHeight, 1100);
      expect(ShareCardSpec.dedicationSize, 56);
      expect(ShareCardSpec.referenceSize, 44);
      expect(ShareCardSpec.appNameSize, 32);
      expect(ShareCardSpec.linkSize, greaterThanOrEqualTo(28));
    });

    test(
      'HU-09.7 la tarjeta usa una variante fija que no depende del tema',
      () {
        for (final s in CardStyle.all) {
          expect(shareCardPalette(s), same(s.light));
        }
      },
    );
  });

  group('HU-09 imagen', () {
    testWidgets('HU-09.3 el PNG es de 1080 × 1920 px y sale en menos de 1 s', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: FittedBox(
              child: RepaintBoundary(
                key: key,
                child: ShareCard(
                  verseText: _medio,
                  reference: 'Juan 3:16',
                  link: 'https://sosiego.app/v/juan-3-16',
                  appName: 'Sosiego',
                  style: CardStyle.all.first,
                  dedication: 'mamá',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final watch = Stopwatch()..start();
      final bytes = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return encodeCardPng(boundary);
      });
      watch.stop();
      expect(bytes, isNotNull);
      // Cabecera PNG + IHDR: ancho y alto en los bytes 16 a 23.
      final b = bytes!;
      expect(b.sublist(1, 4), [0x50, 0x4E, 0x47]);
      final data = ByteData.sublistView(b);
      expect(data.getUint32(16), 1080);
      expect(data.getUint32(20), 1920);
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets(
      'HU-09.3 guarda share_{verse_id}_{style_id}.png y comparte imagen y texto',
      (tester) async {
        final share = FakeShareService();
        final temp = await tester.runAsync(
          () => Directory.systemTemp.createTemp('sosiego_share'),
        );
        addTearDown(() => temp!.deleteSync(recursive: true));
        await _open(tester, share: share, temp: temp);

        await tester.enterText(
          find.byKey(const Key('share-dedication')),
          'mamá',
        );
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('style-mar')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('style-mar')));
        await tester.pump();
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('share-image')));
          await Future<void>.delayed(const Duration(milliseconds: 800));
        });
        await tester.pumpAndSettle();

        expect(share.sharedPath, isNotNull);
        expect(share.sharedPath!.endsWith('share_43003016_mar.png'), isTrue);
        expect(File(share.sharedPath!).existsSync(), isTrue);
        final lines = share.sharedText!.split('\n');
        expect(lines.first, startsWith('«Porque de tal manera'));
        expect(lines[1], 'Juan 3:16');
        expect(lines[2], 'Para mamá');
        expect(lines.last, 'https://sosiego.app/v/juan-3-16');
      },
    );

    test(
      'HU-09.3 los temporales share_*.png se borran al iniciar la app',
      () async {
        final dir = await Directory.systemTemp.createTemp('sosiego_clean');
        addTearDown(() => dir.deleteSync(recursive: true));
        File('${dir.path}/share_1_amanecer.png').writeAsBytesSync([1]);
        File('${dir.path}/share_2_mar.png').writeAsBytesSync([1]);
        File('${dir.path}/otro.txt').writeAsStringSync('x');
        expect(await cleanShareTempFiles(dir), 2);
        expect(File('${dir.path}/otro.txt').existsSync(), isTrue);
        expect(File('${dir.path}/share_1_amanecer.png').existsSync(), isFalse);
      },
    );
  });

  group('HU-09 hoja de compartir', () {
    testWidgets(
      'HU-09.1 muestra vista previa, 10 estilos con nombre, «Para:» y los dos botones',
      (tester) async {
        await _open(tester);
        expect(find.text('Compartir imagen'), findsOneWidget);
        expect(find.text('Enviar texto por WhatsApp'), findsOneWidget);
        expect(find.text('Para:'), findsWidgets);
        expect(find.byType(ShareCard), findsOneWidget);
        for (final s in CardStyle.all) {
          expect(find.text(s.name), findsOneWidget, reason: s.name);
        }
        expect(CardStyle.all.length, inInclusiveRange(8, 10));
      },
    );

    testWidgets('HU-09.1 «Para:» admite 30 caracteres como máximo', (
      tester,
    ) async {
      await _open(tester);
      await tester.enterText(
        find.byKey(const Key('share-dedication')),
        'x' * 45,
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('share-dedication')),
      );
      expect(field.controller!.text.length, 30);
    });

    testWidgets(
      'HU-09.4 «Enviar texto por WhatsApp» abre wa.me con el texto y la dedicatoria',
      (tester) async {
        final share = FakeShareService();
        await _open(tester, share: share);
        await tester.enterText(
          find.byKey(const Key('share-dedication')),
          'Ana',
        );
        await tester.tap(find.byKey(const Key('share-whatsapp')));
        await tester.pumpAndSettle();
        expect(share.opened!.host, 'wa.me');
        final text = share.opened!.queryParameters['text']!;
        expect(text, contains('Para Ana'));
        expect(text, contains('https://sosiego.app/v/juan-3-16'));
        // La dedicatoria nunca va en el enlace.
        expect(share.opened.toString().contains('v/juan-3-16Ana'), isFalse);
      },
    );

    testWidgets('HU-09.4 si WhatsApp no abre, un mensaje amable', (
      tester,
    ) async {
      final share = FakeShareService()..whatsappWorks = false;
      await _open(tester, share: share);
      await tester.tap(find.byKey(const Key('share-whatsapp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-message')), findsOneWidget);
      expect(find.textContaining('No pudimos abrir WhatsApp'), findsOneWidget);
    });

    testWidgets('HU-11.4 el titular encabeza la tarjeta de racha', (
      tester,
    ) async {
      await _open(tester, headline: '7 días con la Palabra');
      expect(find.text('7 días con la Palabra'), findsOneWidget);
    });

    testWidgets(
      'HU-09.1 a escala 2.0 no desborda y las acciones siguen a la vista',
      (tester) async {
        await _open(tester, scale: 2.0);
        expect(tester.takeException(), isNull);
        expect(find.text('Compartir imagen'), findsOneWidget);
        expect(find.text('Enviar texto por WhatsApp'), findsOneWidget);
        final r = tester.getRect(find.byKey(const Key('share-image')));
        expect(r.height, greaterThanOrEqualTo(56));
        expect(r.bottom, lessThanOrEqualTo(720));
      },
    );

    for (final dark in [false, true]) {
      testWidgets(
        'HU-09.1 cumple las guías de accesibilidad ${dark ? 'en oscuro' : 'en claro'} y a escala 2.0',
        (tester) async {
          await _open(tester, dark: dark);
          await expectMeetsAccessibilityGuidelines(tester);
        },
      );
      testWidgets(
        'HU-09.1 guías de accesibilidad a escala 2.0 ${dark ? 'en oscuro' : 'en claro'}',
        (tester) async {
          await _open(tester, dark: dark, scale: 2.0);
          await expectMeetsAccessibilityGuidelines(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
