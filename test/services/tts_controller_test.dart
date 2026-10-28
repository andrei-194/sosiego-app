import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/data/services/tts_service.dart';

import '../helpers/service_fakes.dart';

TtsController _controller(FakeTtsEngine engine, {double rate = 0.5}) =>
    TtsController(
      engine,
      () => rate,
      delay: (_) async {},
      observeLifecycle: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HU-08 escuchar', () {
    test('HU-08.3 lee los bloques en orden', () async {
      final engine = FakeTtsEngine();
      final c = _controller(engine);
      await c.play('v1', ['ref', 'versículo', 'contexto', 'oración']);
      expect(engine.spoken, ['ref', 'versículo', 'contexto', 'oración']);
      expect(c.state.status, TtsStatus.stopped);
    });

    test(
      'HU-08.3 deja medio segundo entre bloques (no tras el último)',
      () async {
        final waits = <Duration>[];
        final c = TtsController(
          FakeTtsEngine(),
          () => 0.5,
          delay: (d) async => waits.add(d),
          observeLifecycle: false,
        );
        await c.play('v1', ['a', 'b', 'c']);
        expect(waits, [
          const Duration(milliseconds: 500),
          const Duration(milliseconds: 500),
        ]);
      },
    );

    test('HU-08.6 usa la velocidad guardada', () async {
      final engine = FakeTtsEngine();
      await _controller(engine, rate: 0.6).play('v1', ['a']);
      expect(engine.rates, [0.6]);
    });

    test('HU-08.4 pasa a reproduciendo, pausado y detenido', () async {
      final engine = FakeTtsEngine(autoFinish: false);
      final c = _controller(engine);
      final done = c.play('v1', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, TtsStatus.playing);
      expect(c.state.isActive('v1'), isTrue);
      expect(c.state.isActive('v2'), isFalse);

      await c.pause();
      expect(c.state.status, TtsStatus.paused);

      final resumed = c.resume();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, TtsStatus.playing);
      // Al continuar repite el bloque en curso desde su inicio.
      expect(engine.spoken, ['a', 'a']);

      await c.stop();
      expect(c.state.status, TtsStatus.stopped);
      await done;
      await resumed;
      expect(engine.spoken, ['a', 'a']);
    });

    test('HU-08.5 al pasar a otro versículo se detiene el anterior', () async {
      final engine = FakeTtsEngine(autoFinish: false);
      final c = _controller(engine);
      unawaited2(c.play('v1', ['a', 'b']));
      await Future<void>.delayed(Duration.zero);
      unawaited2(c.play('v2', ['x']));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.activeKey, 'v2');
      engine.finishCurrent();
      await Future<void>.delayed(Duration.zero);
      expect(engine.spoken, ['a', 'x']);
    });

    test(
      'HU-08.5 al salir de la pantalla se detiene solo su lectura',
      () async {
        final engine = FakeTtsEngine(autoFinish: false);
        final c = _controller(engine);
        unawaited2(c.play('v1', ['a']));
        await Future<void>.delayed(Duration.zero);
        await c.stopIfActive('otro');
        expect(c.state.status, TtsStatus.playing);
        await c.stopIfActive('v1');
        expect(c.state.status, TtsStatus.stopped);
      },
    );

    test('HU-08.5 al perder el foco de audio se detiene', () async {
      final engine = FakeTtsEngine(autoFinish: false);
      final c = _controller(engine);
      unawaited2(c.play('v1', ['a']));
      await Future<void>.delayed(Duration.zero);
      c.onAudioFocusLost();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, TtsStatus.stopped);
    });

    test('HU-08.7 sin voz en español avisa y no dice nada', () async {
      final engine = FakeTtsEngine(locale: null);
      final c = _controller(engine);
      await c.play('v1', ['a']);
      expect(engine.spoken, isEmpty);
      expect(c.state.problem, TtsProblem.noSpanishVoice);
      expect(c.state.problemKey, 'v1');
      expect(c.state.status, TtsStatus.stopped);
    });
  });
}

void unawaited2(Future<void> f) {}
