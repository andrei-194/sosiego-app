import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/core/theme/app_theme.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/services/notification_service.dart';
import 'package:sosiego/data/services/reminder_service.dart';
import 'package:sosiego/data/services/tts_service.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/data/user/providers.dart';
import 'package:sosiego/domain/reminder_policy.dart';
import 'package:sosiego/features/daily/daily_reminder_card.dart';
import 'package:sosiego/features/listen/listen_button.dart';
import 'package:sosiego/features/settings/sections/reminder_settings_section.dart';
import 'package:sosiego/features/settings/sections/voice_settings_section.dart';
import 'package:sosiego/l10n/l10n.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

import '../helpers/a11y.dart';
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

class _Env {
  _Env({String? locale = 'es-CO', bool autoFinish = true, bool grant = true})
    : engine = FakeTtsEngine(locale: locale, autoFinish: autoFinish),
      notifications = FakeNotificationService(grant: grant);
  final FakeTtsEngine engine;
  final FakeNotificationService notifications;
  final appState = MemoryAppStateRepository();
  final history = MemoryHistoryRepository();
}

Future<_Env> _pump(
  WidgetTester tester,
  Widget child, {
  _Env? env,
  double scale = 1.0,
  bool dark = false,
  Map<String, Object> prefs = const {},
}) async {
  final e = env ?? _Env();
  SharedPreferences.setMockInitialValues(prefs);
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
        ttsEngineProvider.overrideWithValue(e.engine),
        ttsBlockPauseProvider.overrideWithValue(Duration.zero),
        notificationServiceProvider.overrideWithValue(e.notifications),
        dailyVerseSourceProvider.overrideWithValue(FakeDailySource()),
        appStateRepositoryProvider.overrideWith((_) => e.appState),
        historyRepositoryProvider.overrideWith((_) => e.history),
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
        home: Scaffold(body: ListView(children: [child])),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return e;
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('HU-08 botón Escuchar', () {
    testWidgets(
      'HU-08.1 «Escuchar» con texto visible y 56 dp; lee referencia y versículo',
      (tester) async {
        final env = await _pump(tester, const ListenButton(verse: _verso));
        expect(find.text('Escuchar'), findsOneWidget);
        final size = tester.getSize(find.byKey(const Key('listen-start')));
        expect(size.height, greaterThanOrEqualTo(56));
        await tester.tap(find.byKey(const Key('listen-start')));
        await tester.pumpAndSettle();
        expect(env.engine.spoken, [
          'Juan, capítulo 3, versículo 16',
          'Porque de tal manera amó Dios al mundo.',
        ]);
        expect(find.text('Escuchar'), findsOneWidget);
      },
    );

    testWidgets('HU-08.4 al reproducir pasa a «Pausar» y «Detener»', (
      tester,
    ) async {
      final env = await _pump(
        tester,
        const ListenButton(verse: _verso, extraBlocks: ['Contexto', 'Oración']),
        env: _Env(autoFinish: false),
      );
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
      await tester.tap(find.byKey(const Key('listen-toggle')));
      await tester.pump();
      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('listen-stop')));
      await tester.pump();
      expect(find.text('Escuchar'), findsOneWidget);
      expect(env.engine.stops, greaterThan(0));
    });

    testWidgets('HU-08.5 al salir de la pantalla se detiene la lectura', (
      tester,
    ) async {
      final env = await _pump(
        tester,
        const ListenButton(verse: _verso),
        env: _Env(autoFinish: false),
      );
      await tester.tap(find.byKey(const Key('listen-start')));
      await tester.pump();
      final before = env.engine.stops;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(env.engine.stops, greaterThan(before));
    });

    testWidgets(
      'HU-08.7 sin voz en español muestra el mensaje exacto del spec',
      (tester) async {
        await _pump(
          tester,
          const ListenButton(verse: _verso),
          env: _Env(locale: null),
        );
        await tester.tap(find.byKey(const Key('listen-start')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Tu teléfono no tiene voz en español. Puedes instalarla en Ajustes del teléfono, en Idioma y Salida de texto a voz',
          ),
          findsOneWidget,
        );
      },
    );

    for (final dark in [false, true]) {
      testWidgets(
        'HU-08.1 guías de accesibilidad y escala 2.0 ${dark ? 'en oscuro' : 'en claro'}',
        (tester) async {
          await _pump(
            tester,
            const ListenButton(verse: _verso),
            dark: dark,
            scale: 2.0,
          );
          expect(tester.takeException(), isNull);
          await expectMeetsAccessibilityGuidelines(tester);
        },
      );
    }
  });

  group('HU-12 velocidad de voz', () {
    testWidgets('HU-08.6 elegir Rápida guarda tts_rate 0.6; Lenta 0.4', (
      tester,
    ) async {
      await _pump(tester, const VoiceSettingsSection());
      expect(find.text('Lenta'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Rápida'), findsOneWidget);
      await tester.tap(find.byKey(const Key('voice-fast')));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getDouble('tts_rate'),
        0.6,
      );
      await tester.tap(find.byKey(const Key('voice-slow')));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getDouble('tts_rate'),
        0.4,
      );
    });

    testWidgets('HU-08.6 la prueba de voz usa la velocidad elegida', (
      tester,
    ) async {
      final env = await _pump(
        tester,
        const VoiceSettingsSection(),
        prefs: {'tts_rate': 0.6},
      );
      await tester.tap(find.byKey(const Key('voice-test')));
      await tester.pumpAndSettle();
      expect(env.engine.spoken, ['Jehová es mi pastor; nada me faltará.']);
      expect(env.engine.rates.last, 0.6);
    });

    testWidgets('HU-08.7 la prueba de voz sin español muestra el aviso', (
      tester,
    ) async {
      await _pump(
        tester,
        const VoiceSettingsSection(),
        env: _Env(locale: null),
      );
      await tester.tap(find.byKey(const Key('voice-test')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('voice-problem')), findsOneWidget);
    });

    testWidgets('HU-12.1 guías de accesibilidad y escala 2.0', (tester) async {
      await _pump(tester, const VoiceSettingsSection(), scale: 2.0);
      expect(tester.takeException(), isNull);
      await expectMeetsAccessibilityGuidelines(tester);
    });
  });

  group('HU-12 versículo diario en Ajustes', () {
    testWidgets(
      'HU-12.1 dice «Desactivado» y al activar pide permiso, programa y dice «Activado»',
      (tester) async {
        final env = await _pump(tester, const ReminderSettingsSection());
        expect(find.text('Desactivado'), findsOneWidget);
        expect(find.text('¿A qué hora?'), findsNothing);
        await tester.tap(find.byKey(const Key('reminder-switch-card')));
        await tester.pumpAndSettle();
        expect(env.notifications.permissionRequests, 1);
        expect(find.text('Activado'), findsOneWidget);
        expect(env.notifications.scheduled.length, 30);
        // Las tres horas y «Otra hora».
        expect(find.text('Mañana, 6:30 a. m.'), findsOneWidget);
        expect(find.text('Tarde, 1:00 p. m.'), findsOneWidget);
        expect(find.text('Noche, 8:00 p. m.'), findsOneWidget);
        expect(find.text('Otra hora'), findsOneWidget);

        await tester.tap(find.byKey(const Key('reminder-pick-20:00')));
        await tester.pumpAndSettle();
        expect(env.notifications.scheduled.first.when.hour, 20);
        expect(
          (await SharedPreferences.getInstance()).getString('notif_time'),
          '20:00',
        );
        expect(
          (await SharedPreferences.getInstance()).getBool('notif_enabled'),
          isTrue,
        );

        await tester.tap(find.byKey(const Key('reminder-switch-card')));
        await tester.pumpAndSettle();
        expect(find.text('Desactivado'), findsOneWidget);
        expect(env.notifications.scheduled, isEmpty);
      },
    );

    testWidgets(
      'HU-07.3 con el permiso negado: mensaje amable y sigue «Desactivado»',
      (tester) async {
        final env = await _pump(
          tester,
          const ReminderSettingsSection(),
          env: _Env(grant: false),
        );
        await tester.tap(find.byKey(const Key('reminder-switch-card')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('reminder-denied')), findsOneWidget);
        expect(find.text('Desactivado'), findsOneWidget);
        expect(env.notifications.scheduled, isEmpty);
      },
    );

    testWidgets(
      'HU-07.8 «Ayuda con las notificaciones» explica cómo quitar el ahorro de batería',
      (tester) async {
        await _pump(tester, const ReminderSettingsSection());
        await tester.tap(find.byKey(const Key('reminder-help')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Sin restricciones'), findsWidgets);
        expect(find.textContaining('Samsung'), findsOneWidget);
        expect(find.textContaining('Xiaomi'), findsOneWidget);
      },
    );

    for (final dark in [false, true]) {
      testWidgets(
        'HU-12.1 guías de accesibilidad y escala 2.0 ${dark ? 'en oscuro' : 'en claro'}',
        (tester) async {
          await _pump(
            tester,
            const ReminderSettingsSection(),
            dark: dark,
            scale: 2.0,
            prefs: {'notif_enabled': true, 'notif_time': '13:00'},
          );
          expect(tester.takeException(), isNull);
          await expectMeetsAccessibilityGuidelines(tester);
        },
      );
    }
  });

  group('HU-07 tarjeta en Inicio', () {
    Future<_Env> card(
      WidgetTester tester, {
      int opens = 2,
      double scale = 1.0,
      bool dark = false,
    }) async {
      final env = _Env();
      await env.appState.set(ReminderStateKeys.openCount, '$opens');
      return _pump(
        tester,
        const DailyReminderCard(),
        env: env,
        scale: scale,
        dark: dark,
      );
    }

    testWidgets(
      'HU-07.3 en la primera apertura no ocupa espacio ni pide permiso',
      (tester) async {
        final env = await card(tester, opens: 1);
        expect(find.byKey(const Key('daily-reminder-card')), findsNothing);
        expect(find.text('Ahora no'), findsNothing);
        expect(env.notifications.permissionRequests, 0);
      },
    );

    testWidgets(
      'HU-07.3 en la segunda apertura muestra la pregunta, tres horas y «Ahora no»',
      (tester) async {
        final env = await card(tester);
        expect(
          find.text('¿Quieres recibir el versículo cada día?'),
          findsOneWidget,
        );
        expect(find.text('Mañana, 6:30 a. m.'), findsOneWidget);
        expect(find.text('Tarde, 1:00 p. m.'), findsOneWidget);
        expect(find.text('Noche, 8:00 p. m.'), findsOneWidget);
        expect(find.text('Ahora no'), findsOneWidget);
        expect(env.notifications.permissionRequests, 0);
      },
    );

    testWidgets('HU-07.3 al tocar una hora se pide el permiso y se confirma', (
      tester,
    ) async {
      final env = await card(tester);
      await tester.tap(find.byKey(const Key('reminder-time-06:30')));
      await tester.pumpAndSettle();
      expect(env.notifications.permissionRequests, 1);
      expect(
        find.textContaining('Listo, te avisaremos a las 6:30 a. m.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('reminder-got-it')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily-reminder-card')), findsNothing);
    });

    testWidgets('HU-07.4 «Ahora no» oculta la tarjeta y la anota', (
      tester,
    ) async {
      final env = await card(tester);
      await tester.tap(find.byKey(const Key('reminder-not-now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily-reminder-card')), findsNothing);
      expect(await env.appState.get(ReminderStateKeys.dismissCount), '1');
      expect(env.notifications.permissionRequests, 0);
    });

    for (final dark in [false, true]) {
      testWidgets(
        'HU-07.3 guías de accesibilidad y escala 2.0 ${dark ? 'en oscuro' : 'en claro'}',
        (tester) async {
          await card(tester, scale: 2.0, dark: dark);
          expect(tester.takeException(), isNull);
          await expectMeetsAccessibilityGuidelines(tester);
        },
      );
    }
  });
}
