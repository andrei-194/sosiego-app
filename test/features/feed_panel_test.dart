import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/core/theme/app_theme.dart';
import 'package:sosiego/core/theme/card_style.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/services/tts_service.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/data/user/providers.dart';
import 'package:sosiego/features/feed/verse_actions.dart';
import 'package:sosiego/l10n/l10n.dart';

import '../helpers/a11y.dart';
import '../helpers/pump_app.dart';
import '../helpers/service_fakes.dart';

const _verso = Verse(
  id: 43003016,
  bookId: 43,
  bookName: 'Juan',
  bookSlug: 'juan',
  chapter: 3,
  verse: 16,
  text: 'Porque de tal manera amó Dios al mundo.',
);

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> _openFeed(
  WidgetTester tester, {
  double scale = 1.0,
  bool dark = false,
  double heightDp = 720,
}) async {
  await pumpApp(tester, scale: scale, dark: dark);
  tester.view.physicalSize = Size(1080, heightDp * 3);
  await openRoute(tester, '/versiculos');
}

/// El feed con la ayuda apagada: solo cambia el alto, no hay que gastarla.
Future<void> _pumpActions(
  WidgetTester tester, {
  double scale = 1.0,
  bool dark = false,
  FakeTtsEngine? engine,
}) async {
  SharedPreferences.setMockInitialValues({});
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
    ProviderScope(
      overrides: [
        ttsEngineProvider.overrideWithValue(
          engine ?? FakeTtsEngine(locale: 'es-CO', autoFinish: false),
        ),
        ttsBlockPauseProvider.overrideWithValue(Duration.zero),
        favoritesRepositoryProvider.overrideWith(
          (_) => MemoryFavoritesRepository(),
        ),
        appStateRepositoryProvider.overrideWith(
          (_) => MemoryAppStateRepository(),
        ),
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
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: VerseActions(
                verse: _verso,
                color: Color(0xFF2B1A0B),
                inline: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('panel inferior del feed', () {
    appTest('HU-04.4 Escuchar, Guardar, Compartir y Más van en una sola fila', (
      tester,
    ) async {
      await _openFeed(tester);
      final tops = <double>{};
      for (final t in ['Escuchar', 'Guardar', 'Compartir', 'Más como este']) {
        final f = find.text(t);
        expect(f, findsOneWidget, reason: t);
        tops.add(tester.getTopLeft(f).dy.roundToDouble());
      }
      // Los rótulos de una línea comparten la misma altura; el de dos
      // líneas («Más como / este») empieza en la misma línea de base.
      expect(tops.length, lessThanOrEqualTo(2));
      final listen = tester.getRect(find.byKey(const Key('listen-start')));
      final save = tester.getRect(find.text('Guardar'));
      expect((listen.center.dy - save.center.dy).abs(), lessThan(60));
      expect(
        listen.bottom,
        lessThan(tester.getRect(find.byKey(const Key('feed-previous'))).top),
      );
    });

    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        appTest('HU-04.4 acciones con 48 dp o más y texto visible '
            '(escala $scale, ${dark ? 'oscuro' : 'claro'}, 720 dp)', (
          tester,
        ) async {
          await _openFeed(tester, scale: scale, dark: dark);
          for (final k in ['listen-start', 'feed-previous', 'feed-next']) {
            final s = tester.getSize(find.byKey(Key(k)));
            expect(s.height, greaterThanOrEqualTo(56), reason: k);
            expect(s.width, greaterThanOrEqualTo(48), reason: k);
          }
          for (final t in ['Guardar', 'Compartir', 'Más como este']) {
            final r = tester.getRect(
              find.ancestor(of: find.text(t), matching: find.byType(InkWell)),
            );
            expect(r.height, greaterThanOrEqualTo(56), reason: t);
            expect(r.width, greaterThanOrEqualTo(48), reason: t);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    appTest(
      'HU-04.2 la ayuda, Anterior y Siguiente caben a 720 dp y letra 2.0',
      (tester) async {
        await _openFeed(tester, scale: 2.0);
        expect(find.byKey(const Key('feed-hint')), findsOneWidget);
        final screen =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        for (final k in ['feed-previous', 'feed-next']) {
          final r = tester.getRect(find.byKey(Key(k)));
          expect(r.bottom, lessThanOrEqualTo(screen), reason: k);
        }
        expect(tester.takeException(), isNull);
      },
    );

    for (final scale in [1.0, 2.0]) {
      appTest(
        'HU-04.1 a 720 dp el versículo se desplaza completo, sin recortes '
        '(escala $scale)',
        (tester) async {
          await _openFeed(tester, scale: scale);
          expect(tester.takeException(), isNull);
          final text = tester.widget<Text>(find.byKey(const Key('verse-text')));
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
          // La referencia, al final del bloque, se alcanza desplazando.
          await tester.ensureVisible(find.byKey(const Key('verse-reference')));
          await tester.pumpAndSettle();
          final screen =
              tester.view.physicalSize.height / tester.view.devicePixelRatio;
          final ref = tester.getRect(find.byKey(const Key('verse-reference')));
          expect(ref.top, greaterThanOrEqualTo(0));
          expect(ref.bottom, lessThanOrEqualTo(screen));
          // Las acciones siguen a la vista mientras se lee.
          expect(find.byKey(const Key('feed-next')), findsOneWidget);
        },
      );
    }

    appTest(
      'HU-04.1 el tamaño de la letra del versículo no cambia al compactar',
      (tester) async {
        await _openFeed(tester, heightDp: 900);
        final tall = tester
            .widget<Text>(find.byKey(const Key('verse-text')))
            .style!
            .fontSize;
        tester.view.physicalSize = const Size(1080, 640 * 3);
        await tester.pumpAndSettle();
        final short = tester
            .widget<Text>(find.byKey(const Key('verse-text')))
            .style!
            .fontSize;
        expect(short, tall);
      },
    );

    for (final dark in [false, true]) {
      appTest('HU-04.4 guías de accesibilidad con letra 2.0 '
          '(${dark ? 'oscuro' : 'claro'})', (tester) async {
        await _openFeed(tester, scale: 2.0, dark: dark);
        expect(tester.takeException(), isNull);
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }

    test('HU-04.5 el texto de las acciones sobre la bandeja cumple 4.5:1 '
        '(en realidad 7:1 o más) en todos los estilos y variantes', () {
      for (final style in CardStyle.all) {
        for (final p in [style.light, style.dark]) {
          for (final bg in [p.top, p.bottom]) {
            final tray = Color.alphaBlend(p.text.withValues(alpha: 0.07), bg);
            expect(
              _contrast(p.text, tray),
              greaterThanOrEqualTo(7),
              reason: '${style.id} ${bg == p.top ? 'top' : 'bottom'}',
            );
          }
        }
      }
    });
  });

  group('Escuchar en la fila de acciones', () {
    testWidgets('HU-08.1 «Escuchar» mide 56 dp y lee referencia y versículo', (
      tester,
    ) async {
      final engine = FakeTtsEngine(locale: 'es-CO');
      await _pumpActions(tester, engine: engine);
      expect(find.text('Escuchar'), findsOneWidget);
      final size = tester.getSize(find.byKey(const Key('listen-start')));
      expect(size.height, greaterThanOrEqualTo(56));
      expect(size.width, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(const Key('listen-start')));
      await tester.pumpAndSettle();
      expect(engine.spoken, [
        'Juan, capítulo 3, versículo 16',
        'Porque de tal manera amó Dios al mundo.',
      ]);
    });

    testWidgets(
      'HU-08.4 al reproducir pasa a «Pausar» y «Detener» en la fila',
      (tester) async {
        await _pumpActions(tester);
        await tester.tap(find.byKey(const Key('listen-start')));
        await tester.pump();
        await tester.pump();
        expect(find.text('Pausar'), findsOneWidget);
        expect(find.text('Detener'), findsOneWidget);
        expect(find.text('Escuchar'), findsNothing);
        for (final k in ['listen-toggle', 'listen-stop']) {
          expect(
            tester.getSize(find.byKey(Key(k))).height,
            greaterThanOrEqualTo(56),
          );
        }
        // Con las cinco acciones, nada se sale de la pantalla.
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('listen-toggle')));
        await tester.pump();
        expect(find.text('Continuar'), findsOneWidget);
        await tester.tap(find.byKey(const Key('listen-stop')));
        await tester.pumpAndSettle();
        expect(find.text('Escuchar'), findsOneWidget);
      },
    );

    for (final dark in [false, true]) {
      testWidgets('HU-08.4 sin desbordes con escala 2.0 al sonar, en la fila '
          '(${dark ? 'oscuro' : 'claro'})', (tester) async {
        await _pumpActions(tester, scale: 2.0, dark: dark);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('listen-start')));
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
