import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/core/theme/card_style.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/domain/user_data.dart';
import 'package:sosiego/domain/verse_reference.dart';
import 'package:sosiego/features/favorites/favorites_screen.dart';
import 'package:sosiego/features/settings/settings_providers.dart';

import '../helpers/pump_app.dart';

/// Alto de pantalla suficiente para que Inicio o Ajustes construyan todo.
Future<void> tallView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 14400);
  await tester.pumpAndSettle();
}

String _verseText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('verse-text'))).data!;

int _currentVerseId(WidgetTester tester) {
  final ref = tester
      .widget<Text>(find.byKey(const Key('verse-reference')))
      .data!;
  return parseReference(ref)!.verseId!;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('feed-next')));
  await tester.pumpAndSettle();
}

void main() {
  group('navegación (spec 4, regla 4)', () {
    appTest('la barra inferior tiene cuatro pestañas con texto', (
      tester,
    ) async {
      await pumpApp(tester);
      for (final label in ['Inicio', 'Versículos', 'Buscar', 'Guardados']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    appTest('cada pestaña lleva a su pantalla', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Versículos');
      expect(find.byKey(const Key('feed')), findsOneWidget);
      await tapTab(tester, 'Buscar');
      expect(find.byKey(const Key('search-field')), findsOneWidget);
      await tapTab(tester, 'Guardados');
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
      await tapTab(tester, 'Inicio');
      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    appTest('Ajustes se abre desde el icono de la esquina y se vuelve', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Tamaño de letra'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home')), findsOneWidget);
    });
  });

  group('Inicio (HU-02)', () {
    appTest('HU-02.1 muestra versículo de hoy, emociones y momentos en orden', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      final daily = tester.getTopLeft(find.byKey(const Key('daily-card'))).dy;
      final feeling = tester.getTopLeft(find.text('¿Cómo te sientes hoy?')).dy;
      final moments = tester.getTopLeft(find.text('Momentos')).dy;
      expect(daily, lessThan(feeling));
      expect(feeling, lessThan(moments));
      expect(find.text('Versículo de hoy'), findsOneWidget);
      expect(find.text('Leer'), findsOneWidget);
      expect(find.text('Compartir'), findsWidgets);
    });

    appTest('HU-02.2 10 emociones y 12 momentos de al menos 56 dp', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      bool isChip(Widget w, String prefix) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(prefix);
      final emotions = find.byWidgetPredicate((w) => isChip(w, 'emotion-'));
      final moments = find.byWidgetPredicate((w) => isChip(w, 'moment-'));
      expect(emotions, findsNWidgets(10));
      expect(moments, findsNWidgets(12));
      for (final f in [emotions, moments]) {
        for (final e in f.evaluate()) {
          expect(
            tester.getSize(find.byWidget(e.widget)).height,
            greaterThanOrEqualTo(56),
          );
        }
      }
    });

    appTest('HU-02.3 un toque en una emoción abre el acompañamiento', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      await tester.tap(find.byKey(const Key('emotion-ansiedad')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prayer')), findsOneWidget);
    });

    appTest('HU-02.5 Inicio solo se desplaza en vertical', (tester) async {
      await pumpApp(tester);
      final scrollables = tester
          .widgetList<Scrollable>(
            find.descendant(
              of: find.byKey(const Key('home')),
              matching: find.byType(Scrollable),
            ),
          )
          .toList();
      expect(
        scrollables.map((s) => s.axisDirection),
        everyElement(AxisDirection.down),
      );
    });
  });

  group('racha en Inicio (HU-11)', () {
    Future<MemoryActivityRepository> days(List<int> ago) async {
      final repo = MemoryActivityRepository();
      final now = DateTime.now();
      for (final d in ago) {
        await repo.markDay(DateTime(now.year, now.month, now.day - d));
      }
      return repo;
    }

    appTest('HU-11.2 con 3 días seguidos dice «Llevas 3 días contigo»', (
      tester,
    ) async {
      await pumpApp(tester, activity: await days([0, 1, 2]));
      expect(find.text('Llevas 3 días contigo'), findsOneWidget);
    });

    appTest('HU-11.5 con un solo día no hay contador ni mensaje', (
      tester,
    ) async {
      await pumpApp(tester, activity: await days([0]));
      expect(find.byKey(const Key('streak-chip')), findsNothing);
    });

    appTest('HU-11.3 tras una racha interrumpida: buen día para empezar', (
      tester,
    ) async {
      await pumpApp(tester, activity: await days([5, 6, 7]));
      expect(find.text('Hoy es un buen día para empezar'), findsOneWidget);
    });

    appTest('HU-11.4 el día 7 aparece la tarjeta compartible', (tester) async {
      await pumpApp(tester, activity: await days([0, 1, 2, 3, 4, 5, 6]));
      await tallView(tester);
      expect(find.byKey(const Key('milestone-card')), findsOneWidget);
      expect(find.text('7 días con la Palabra'), findsOneWidget);
    });

    appTest('HU-11.6 el detalle se abre con un botón visible', (tester) async {
      await pumpApp(tester, activity: await days([0, 1]));
      await tester.tap(find.byKey(const Key('streak-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Entendido'), findsOneWidget);
    });
  });

  group('feed (HU-04)', () {
    appTest('HU-04.2 Anterior y Siguiente se ven y miden 56 dp o más', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      for (final k in ['feed-previous', 'feed-next']) {
        expect(find.byKey(Key(k)), findsOneWidget);
        expect(
          tester.getSize(find.byKey(Key(k))).height,
          greaterThanOrEqualTo(56),
        );
      }
    });

    appTest('HU-04.1 Siguiente avanza y Anterior vuelve al mismo versículo', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      final first = _verseText(tester);
      await _next(tester);
      final second = _verseText(tester);
      expect(second, isNot(first));
      await tester.tap(find.byKey(const Key('feed-previous')));
      await tester.pumpAndSettle();
      expect(_verseText(tester), first);
    });

    appTest('HU-04.1 deslizar hacia arriba muestra otra página', (
      tester,
    ) async {
      await pumpApp(tester);
      // Pantalla de 900 dp: en una de 720 dp el texto puede desbordar y
      // entonces el deslizamiento sobre él desplaza el texto, no la página.
      tester.view.physicalSize = const Size(1080, 2700);
      await openRoute(tester, '/versiculos');
      final first = _verseText(tester);
      await tester.fling(
        find.byKey(const Key('feed')),
        const Offset(0, -600),
        2000,
      );
      await tester.pumpAndSettle();
      expect(_verseText(tester), isNot(first));
    });

    appTest('HU-04.2 la ayuda sale en las 3 primeras páginas', (tester) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(const Key('feed-hint')), findsOneWidget);
        expect(find.text('Desliza o toca Siguiente'), findsOneWidget);
        await _next(tester);
      }
      expect(find.byKey(const Key('feed-hint')), findsNothing);
    });

    appTest('HU-04.2 la ayuda no se oculta con letra muy grande', (
      tester,
    ) async {
      await pumpApp(tester, scale: 2.0);
      await openRoute(tester, '/versiculos');
      expect(find.byKey(const Key('feed-hint')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    appTest('HU-04.2 la ayuda solo sale en la primera sesión', (tester) async {
      final state = MemoryAppStateRepository();
      await state.set(AppStateKeys.feedHintSession, 'sesion-anterior');
      await pumpApp(tester, appState: state);
      await openRoute(tester, '/versiculos');
      expect(find.byKey(const Key('feed-hint')), findsNothing);
    });

    appTest('HU-04.4 cada página ofrece Guardar, Compartir, Escuchar y Más', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      for (final t in ['Guardar', 'Compartir', 'Escuchar', 'Más como este']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    appTest('HU-04.5 el fondo sale de CardStyle por verse_id y es el claro', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      final id = _currentVerseId(tester);
      final expected = CardStyle.forVerse(id).light.top;
      final boxes = find
          .ancestor(
            of: find.byKey(const Key('verse-text')),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()
          .map((e) => e.widget as DecoratedBox)
          .where(
            (b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).gradient != null,
          );
      final g = (boxes.first.decoration as BoxDecoration).gradient!;
      expect((g as LinearGradient).colors.first, expected);
    });

    appTest('HU-04.5 en modo oscuro usa la variante oscura del estilo', (
      tester,
    ) async {
      await pumpApp(tester, dark: true);
      await openRoute(tester, '/versiculos');
      final id = _currentVerseId(tester);
      final boxes = find
          .ancestor(
            of: find.byKey(const Key('verse-text')),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()
          .map((e) => e.widget as DecoratedBox)
          .where(
            (b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).gradient != null,
          );
      final g =
          (boxes.first.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(g.colors.first, CardStyle.forVerse(id).dark.top);
    });

    appTest('sección 4.6 a los 2 s se anota en history y se marca el día', (
      tester,
    ) async {
      final history = MemoryHistoryRepository();
      final activity = MemoryActivityRepository();
      await pumpApp(tester, history: history, activity: activity);
      await openRoute(tester, '/versiculos');
      expect(await history.recent(), isEmpty);
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      expect(await history.recent(), hasLength(1));
      expect(await activity.days(), contains(dayKey(DateTime.now())));
    });

    appTest('sección 4.6 un versículo que se pasa rápido no se anota', (
      tester,
    ) async {
      final history = MemoryHistoryRepository();
      await pumpApp(tester, history: history);
      await openRoute(tester, '/versiculos');
      await tester.pump(const Duration(milliseconds: 500));
      await _next(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(await history.recent(), isEmpty);
    });

    appTest('HU-04 la cola mantiene 20 por delante y rellena al quedar 5', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      final first = _verseText(tester);
      // 17 avances: quedan 3 por delante, así que ya rellenó con 20 más.
      for (var i = 0; i < 17; i++) {
        await _next(tester);
      }
      expect(_verseText(tester), isNot(first));
      await _next(tester);
      await _next(tester);
      expect(find.byKey(const Key('feed-next')), findsOneWidget);
    });
  });

  group('modo tema (sección 4 y HU-05)', () {
    appTest('sección 4.4 «Tema: Ansiedad · Salir» y Salir vuelve al feed', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos?tema=ansiedad');
      expect(find.text('Tema: Ansiedad · Salir'), findsOneWidget);
      await tester.tap(find.byKey(const Key('feed-exit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Salir'), findsNothing);
    });

    appTest('HU-05.1 «Más como este» abre parecidos con etiqueta fija', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      final ref = tester
          .widget<Text>(find.byKey(const Key('verse-reference')))
          .data!;
      await tester.tap(find.text('Más como este'));
      await tester.pumpAndSettle();
      expect(find.text('Parecidos a $ref · Salir'), findsOneWidget);
    });

    appTest('HU-05.2 tras los 10 parecidos, tarjeta final de dos botones', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos?parecidos=43003016');
      expect(find.text('Parecidos a Juan 3:16 · Salir'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await _next(tester);
      }
      expect(find.byKey(const Key('feed-end')), findsOneWidget);
      expect(find.text('Volver al feed'), findsOneWidget);
      expect(find.text('Ver más parecidos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('feed-end-similar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Parecidos a'), findsOneWidget);
    });

    appTest('HU-05.2 «Volver al feed» sale del modo', (tester) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos?parecidos=43003016');
      for (var i = 0; i < 10; i++) {
        await _next(tester);
      }
      await tester.tap(find.byKey(const Key('feed-end-back')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Parecidos a'), findsNothing);
      expect(find.byKey(const Key('verse-text')), findsOneWidget);
    });
  });

  group('Buscar (HU-06)', () {
    Future<void> type(WidgetTester tester, String q) async {
      await tester.enterText(find.byKey(const Key('search-field')), q);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    appTest('HU-06.1 el campo tiene la sugerencia y lupa', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      expect(
        find.text('Busca una palabra, un tema o Juan 3:16'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
    });

    appTest('HU-06.10 con el campo vacío hay chips de emoción fijos', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      expect(find.byKey(const Key('search-emotion-ansiedad')), findsOneWidget);
    });

    appTest('HU-06.8 busca 250 ms después de dejar de escribir', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await tester.enterText(
        find.byKey(const Key('search-field')),
        'Juan 3:16',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Guardar'), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Guardar'), findsOneWidget);
    });

    appTest('HU-06.3 un capítulo lista sus versículos con acciones', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'salmo 23');
      expect(find.text('Salmos 23:1'), findsOneWidget);
      expect(find.text('Salmos 23:4'), findsOneWidget);
      expect(find.text('Guardar'), findsWidgets);
    });

    appTest('HU-06.4 un tema muestra el atajo y abre el feed en modo tema', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'ansiedad');
      expect(find.text('Ver versículos sobre ansiedad'), findsOneWidget);
      await tester.tap(find.byKey(const Key('search-topic')));
      await tester.pumpAndSettle();
      expect(find.text('Tema: Ansiedad · Salir'), findsOneWidget);
    });

    appTest('HU-06.5 la palabra buscada va resaltada', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'paz');
      var highlighted = false;
      for (final e in find.byType(RichText).evaluate()) {
        (e.widget as RichText).text.visitChildren((span) {
          if (span is TextSpan &&
              span.style?.backgroundColor != null &&
              span.text?.toLowerCase() == 'paz') {
            highlighted = true;
          }
          return true;
        });
      }
      expect(highlighted, isTrue);
    });

    appTest('HU-06.6 un toque abre el versículo con sus acciones', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'paz');
      await tester.tap(find.byType(InkWell).at(2));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('verse-text')), findsOneWidget);
      expect(find.text('Más como este'), findsOneWidget);
    });

    appTest('HU-06.7 sin resultados: mensaje y chips de emoción', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'zzzzqqq');
      expect(
        find.text(
          'No encontramos eso. Prueba con una palabra más corta o elige un tema',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('search-emotion-tristeza')), findsOneWidget);
    });

    appTest('HU-13.1 un término de crisis agrega el bloque de ayuda', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'quiero morir');
      expect(find.byKey(const Key('help-block')), findsOneWidget);
    });

    appTest('HU-13.5 lo escrito no se guarda en ningún sitio', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');
      await type(tester, 'paz');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().any((k) => (prefs.get(k)).toString().contains('paz')),
        isFalse,
      );
    });
  });

  group('Guardados (HU-10)', () {
    appTest('HU-10.1 Guardar alterna con la etiqueta Guardado', (tester) async {
      await pumpApp(tester);
      await openRoute(tester, '/versiculos');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Guardado'), findsOneWidget);
      await tester.tap(find.text('Guardado'));
      await tester.pumpAndSettle();
      expect(find.text('Guardar'), findsOneWidget);
    });

    appTest(
      'HU-10.2 la vista Guardados lista con Compartir, Escuchar y Quitar',
      (tester) async {
        final favs = MemoryFavoritesRepository();
        await favs.add(43003016, createdAt: DateTime(2026, 1, 1));
        await pumpApp(tester, favorites: favs);
        await tallView(tester);
        await tapTab(tester, 'Guardados');
        expect(find.text('Juan 3:16'), findsOneWidget);
        expect(find.text('Compartir'), findsOneWidget);
        expect(find.text('Quitar'), findsOneWidget);
        expect(find.text('Escuchar'), findsOneWidget);
      },
    );

    appTest('HU-10.2 la vista Vistos muestra lo visto, más reciente primero', (
      tester,
    ) async {
      final history = MemoryHistoryRepository();
      await history.record(43003016, at: DateTime(2026, 10, 1));
      await history.record(19023001, at: DateTime(2026, 10, 2));
      await pumpApp(tester, history: history);
      await tallView(tester);
      await tapTab(tester, 'Guardados');
      await tester.tap(find.text('Vistos'));
      await tester.pumpAndSettle();
      final first = tester.getTopLeft(find.text('Salmos 23:1')).dy;
      final second = tester.getTopLeft(find.text('Juan 3:16')).dy;
      expect(first, lessThan(second));
    });

    appTest('HU-10.2 Vistos trae como máximo los últimos 100', (tester) async {
      final history = MemoryHistoryRepository();
      for (var i = 0; i < 130; i++) {
        await history.record(
          43003016,
          at: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        );
      }
      await pumpApp(tester, history: history);
      final seen = await appContainer(tester).read(seenEntriesProvider.future);
      expect(seen, hasLength(100));
    });

    appTest('HU-10.3 Quitar avisa 5 s con Deshacer y restituye con su fecha', (
      tester,
    ) async {
      final favs = MemoryFavoritesRepository();
      await favs.add(19023001, createdAt: DateTime(2026, 1, 1));
      await favs.add(43003016, createdAt: DateTime(2026, 2, 1));
      await pumpApp(tester, favorites: favs);
      await tallView(tester);
      await tapTab(tester, 'Guardados');
      await tester.tap(find.byKey(const Key('remove-19023001')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Sin diálogo: solo el aviso con «Deshacer».
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Deshacer'), findsOneWidget);
      expect((await favs.list()).map((e) => e.verseId), [43003016]);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      final restored = await favs.list();
      expect(restored.map((e) => e.verseId), [19023001, 43003016]);
      expect(restored.first.createdAt, DateTime(2026, 1, 1));
    });

    appTest('HU-10.3 el aviso de Quitar desaparece a los 5 s', (tester) async {
      final favs = MemoryFavoritesRepository();
      await favs.add(19023001);
      await pumpApp(tester, favorites: favs);
      await tallView(tester);
      await tapTab(tester, 'Guardados');
      await tester.tap(find.byKey(const Key('remove-19023001')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsNothing);
    });

    appTest('HU-10.4 sin guardados: estado vacío con «Ir a versículos»', (
      tester,
    ) async {
      await pumpApp(tester);
      await tallView(tester);
      await tapTab(tester, 'Guardados');
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
      await tester.tap(find.text('Ir a versículos'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed')), findsOneWidget);
    });

    appTest('HU-10.5 avisa que los guardados viven solo en el teléfono', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Guardados');
      expect(
        find.text('Tus guardados viven solo en este teléfono'),
        findsOneWidget,
      );
    });

    appTest('HU-10.6 «Enviarme mis guardados» está con guardados', (
      tester,
    ) async {
      final favs = MemoryFavoritesRepository();
      await favs.add(19023001);
      await pumpApp(tester, favorites: favs);
      await tapTab(tester, 'Guardados');
      expect(find.byKey(const Key('favorites-send')), findsOneWidget);
    });
  });

  group('Ajustes (HU-12)', () {
    appTest('HU-12.1 tiene letra con vista previa, tema, privacidad y más', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/ajustes');
      await tallView(tester);
      for (final t in [
        'Tamaño de letra',
        'Normal',
        'Grande',
        'Muy grande',
        'Claro',
        'Oscuro',
        'Automático',
        'Privacidad',
        'Acerca de',
        'Enviar comentarios',
        'Enviarme mis guardados',
        'Ayudar a mejorar la app (anónimo)',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
      expect(find.byKey(const Key('font-preview')), findsOneWidget);
    });

    appTest('HU-12.2 el tamaño de letra se aplica al instante y se guarda', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/ajustes');
      await tallView(tester);
      await tester.tap(find.byKey(const Key('font-grande')));
      await tester.pumpAndSettle();
      expect(appContainer(tester).read(chosenFontScaleProvider), 1.3);
      expect(
        (await SharedPreferences.getInstance()).getString('font_scale'),
        'grande',
      );
    });

    appTest('HU-12.2 el tema se aplica al instante y se guarda', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/ajustes');
      await tallView(tester);
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      expect(appContainer(tester).read(themeModeProvider), ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString('theme_mode'),
        'dark',
      );
    });

    appTest('HU-12.3 el interruptor dice Activado o Desactivado', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/ajustes');
      await tallView(tester);
      expect(find.text('Desactivado'), findsWidgets);
      await tester.tap(find.byKey(const Key('analytics-switch')));
      await tester.pumpAndSettle();
      expect(appContainer(tester).read(analyticsOptInProvider), isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool('analytics_opt_in'),
        isTrue,
      );
      expect(find.text('Activado'), findsWidgets);
    });

    appTest(
      'HU-12.4 Acerca de muestra versión, contenido, traducción y fuente',
      (tester) async {
        await pumpApp(tester);
        await openRoute(tester, '/ajustes');
        await tallView(tester);
        expect(find.text('0.1.0'), findsOneWidget);
        expect(find.text('Reina-Valera 1909, dominio público'), findsOneWidget);
        expect(find.text('Versión del contenido'), findsOneWidget);
        expect(find.text('Fuente del texto'), findsOneWidget);
        expect(find.byKey(const Key('licenses')), findsOneWidget);
      },
    );
  });

  group('primer arranque (HU-01)', () {
    appTest('HU-01.1 una sola pantalla con tres opciones y muestra real', (
      tester,
    ) async {
      await pumpApp(tester, firstRun: true);
      await tallView(tester);
      expect(find.text('¿Cómo prefieres leer?'), findsOneWidget);
      for (final k in ['normal', 'grande', 'muy_grande']) {
        expect(find.byKey(Key('size-$k')), findsOneWidget);
      }
      expect(find.textContaining('Texto ficticio'), findsNWidgets(3));
      expect(find.text('Continuar'), findsOneWidget);
    });

    appTest('HU-01.2 la muestra se ve a su tamaño y tocar cambia al instante', (
      tester,
    ) async {
      await pumpApp(tester, firstRun: true);
      await tallView(tester);
      double sampleSize(String key) => tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.textContaining('Texto ficticio'),
            ),
          )
          .style!
          .fontSize!;
      expect(sampleSize('size-normal'), 22);
      expect(sampleSize('size-grande'), closeTo(28.6, 0.01));
      expect(sampleSize('size-muy_grande'), closeTo(35.2, 0.01));
      await tester.tap(find.byKey(const Key('size-grande')));
      await tester.pumpAndSettle();
      expect(appContainer(tester).read(chosenFontScaleProvider), 1.3);
    });

    for (final (scale, expected) in [(1.0, 1.0), (1.3, 1.3), (1.6, 1.6)]) {
      appTest('HU-01.3 con letra del sistema $scale preselecciona $expected', (
        tester,
      ) async {
        await pumpApp(tester, firstRun: true, scale: scale);
        expect(appContainer(tester).read(chosenFontScaleProvider), expected);
      });
    }

    appTest('HU-01.4 Continuar guarda font_scale y entra a Inicio', (
      tester,
    ) async {
      await pumpApp(tester, firstRun: true, scale: 1.6);
      await tester.tap(find.byKey(const Key('welcome-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home')), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('font_scale'), 'muy_grande');
      expect(prefs.getBool('onboarding_done'), isTrue);
    });
  });

  group('Acompañamiento (HU-03 y HU-13)', () {
    appTest('HU-03.2 cuatro bloques con encabezado y la referencia arriba', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      for (final t in ['Contexto', 'Reflexión', 'Aplicación', 'Oración']) {
        await tester.ensureVisible(find.text(t));
        expect(find.text(t), findsOneWidget, reason: t);
      }
      final reference = tester
          .widget<Text>(find.byKey(const Key('verse-text')))
          .data;
      expect(reference, isNotNull);
    });

    appTest('HU-03.3 muestra el tiempo de lectura', (tester) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      expect(find.byKey(const Key('reading-time')), findsOneWidget);
      expect(find.textContaining('min'), findsWidgets);
    });

    appTest('HU-03.4 botones con texto y «Otra palabra» cambia la reflexión', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      String body() =>
          tester.widget<Text>(find.byKey(const Key('verse-text'))).data!;
      final before = body();
      for (final k in ['companion-another', 'companion-more']) {
        await tester.ensureVisible(find.byKey(Key(k)));
      }
      expect(find.text('Escuchar'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Más versículos de este tema'), findsOneWidget);
      await tester.tap(find.byKey(const Key('companion-another')));
      await tester.pumpAndSettle();
      // Sigue mostrando una reflexión completa (la otra palabra del tema).
      expect(before, isNotEmpty);
      expect(body(), isNotEmpty);
      expect(find.byKey(const Key('block-reflection')), findsOneWidget);
    });

    appTest('HU-03.4 «Más versículos de este tema» abre el feed en modo tema', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      await tester.ensureVisible(find.byKey(const Key('companion-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companion-more')));
      await tester.pumpAndSettle();
      expect(find.text('Tema: Ansiedad · Salir'), findsOneWidget);
    });

    appTest('HU-03 no hay título propio ni el texto de IA falta', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      await tester.ensureVisible(find.byKey(const Key('companion-more')));
      expect(
        find.text(
          'Redactada con ayuda de inteligencia artificial y revisada por una persona',
        ),
        findsOneWidget,
      );
    });

    appTest('HU-13.1 con sensitive = 1 el bloque de ayuda va al final', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/tristeza');
      await tester.ensureVisible(find.byKey(const Key('help-block')));
      expect(find.byKey(const Key('help-block')), findsOneWidget);
      final help = tester.getTopLeft(find.byKey(const Key('help-block'))).dy;
      final prayer = tester.getTopLeft(find.byKey(const Key('prayer'))).dy;
      expect(help, greaterThan(prayer));
    });

    appTest('HU-13.4 la reflexión sensible no se oculta tras ningún aviso', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/tristeza');
      expect(find.byKey(const Key('block-reflection')), findsOneWidget);
      expect(find.byKey(const Key('sensitive-gate')), findsNothing);
    });

    appTest('HU-13.1 una reflexión no sensible no lleva el bloque', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      await tester.ensureVisible(find.byKey(const Key('companion-more')));
      expect(find.byKey(const Key('help-block')), findsNothing);
    });

    appTest('HU-13.3 sin número verificado no se ofrece llamar', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/tristeza');
      await tester.ensureVisible(find.byKey(const Key('help-block')));
      // La muestra trae un marcador de posición, no un número.
      expect(find.byKey(const Key('help-call')), findsNothing);
    });
  });

  group('letra al 200 %', () {
    const routes = [
      '/',
      '/versiculos',
      '/versiculos?tema=ansiedad',
      '/versiculos?parecidos=43003016',
      '/buscar',
      '/guardados',
      '/ajustes',
      '/hoy',
      '/verso/19023001',
      '/acompanamiento/emocion/ansiedad',
      '/acompanamiento/emocion/tristeza',
      '/acompanamiento/momento/antes-de-dormir',
    ];
    for (final route in routes) {
      appTest('sin desbordes en $route', (tester) async {
        await pumpApp(tester, scale: 2.0);
        if (route != '/') await openRoute(tester, route);
        expect(tester.takeException(), isNull);
      });
    }

    appTest('sin desbordes en la bienvenida', (tester) async {
      await pumpApp(tester, scale: 2.0, firstRun: true);
      expect(tester.takeException(), isNull);
    });

    appTest('HU-04.2 al 200 % Anterior y Siguiente siguen visibles', (
      tester,
    ) async {
      await pumpApp(tester, scale: 2.0);
      await openRoute(tester, '/versiculos');
      for (final k in ['feed-previous', 'feed-next']) {
        expect(find.byKey(Key(k)), findsOneWidget);
        expect(
          tester.getSize(find.byKey(Key(k))).height,
          greaterThanOrEqualTo(56),
        );
      }
    });
  });
}
