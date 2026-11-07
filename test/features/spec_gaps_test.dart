import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/domain/streak.dart';
import 'package:sosiego/domain/user_data.dart';

import '../helpers/pump_app.dart';

/// Registra lo que se pide abrir en vez de abrirlo.
class _FakeLauncher extends UrlLauncherPlatform {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

/// Criterios que tenían hueco en la trazabilidad (tools/trace.py).
void main() {
  group('Acompañamiento sensible (HU-03.5 y HU-13.6)', () {
    appTest('HU-03.5 con sensitive = 1 se muestra el aviso de ayuda', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/tristeza');
      await tester.ensureVisible(find.byKey(const Key('help-block')));
      expect(find.byKey(const Key('help-block')), findsOneWidget);
    });

    appTest('HU-13.6 el cuerpo no se oculta y el bloque de ayuda va al final', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/tristeza');
      for (final k in ['block-context', 'block-reflection', 'prayer']) {
        await tester.ensureVisible(find.byKey(Key(k)));
        final t = tester.widget<Text>(find.byKey(Key(k)));
        expect(t.data, isNotEmpty, reason: k);
      }
      final prayerY = tester.getTopLeft(find.byKey(const Key('prayer'))).dy;
      final helpY = tester.getTopLeft(find.byKey(const Key('help-block'))).dy;
      expect(helpY, greaterThan(prayerY));
    });

    appTest('HU-13.1 una reflexión no sensible no lleva el bloque de ayuda', (
      tester,
    ) async {
      await pumpApp(tester);
      await openRoute(tester, '/acompanamiento/emocion/ansiedad');
      expect(find.byKey(const Key('help-block')), findsNothing);
    });
  });

  group('Inicio y ajustes', () {
    appTest(
      'HU-07.2 la tarjeta del versículo de hoy tiene Leer, Escuchar y Compartir',
      (tester) async {
        await pumpApp(tester);
        final card = find.byKey(const Key('daily-card'));
        expect(card, findsOneWidget);
        for (final label in ['Leer', 'Escuchar', 'Compartir']) {
          expect(
            find.descendant(of: card, matching: find.text(label)),
            findsOneWidget,
            reason: label,
          );
        }
      },
    );

    appTest('HU-12.5 Enviar comentarios abre un correo con destinatario', (
      tester,
    ) async {
      final launcher = _FakeLauncher();
      final previous = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = previous);
      await pumpApp(tester);
      await openRoute(tester, '/ajustes');
      tester.view.physicalSize = const Size(1080, 14400);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('feedback')));
      await tester.tap(find.byKey(const Key('feedback')));
      await tester.pumpAndSettle();
      expect(launcher.launched, hasLength(1));
      final uri = Uri.parse(launcher.launched.single);
      expect(uri.scheme, 'mailto');
      expect(uri.path, contains('@'));
    });
  });

  group('Datos y privacidad', () {
    test(
      'HU-05.3 todo versículo elegible tiene parecidos (el botón se muestra)',
      () {
        final repo = ContentRepository('assets/db/content.db');
        addTearDown(repo.close);
        final eligible = repo.eligibleCandidates();
        expect(eligible, isNotEmpty);
        for (final c in eligible) {
          expect(repo.similarIds(c.id), hasLength(10), reason: 'verso ${c.id}');
        }
      },
    );

    test('HU-09.8 la app no incluye ningún cliente de red propio', () {
      // La imagen y la dedicatoria nunca salen del teléfono: lib/ no usa
      // clientes HTTP ni sockets. (INTERNET solo la pediría el SDK de métricas.)
      final banned = RegExp(
        r'HttpClient|package:http/|package:dio/|WebSocket|Socket\.connect',
      );
      final offenders = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          if (banned.hasMatch(f.readAsStringSync())) offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('Racha (HU-11.1)', () {
    test(
      'HU-11.1 un día marcado en activity_days cuenta como activo',
      () async {
        final activity = MemoryActivityRepository();
        final today = DateTime(2026, 10, 28);
        await activity.markDay(today);
        expect(await activity.days(), contains(dayKey(today)));
        expect(dayKey(today), '2026-10-28');
        expect(
          currentStreak({
            dayKey(today),
            dayKey(today.subtract(const Duration(days: 1))),
          }, today),
          2,
        );
      },
    );
  });
}
