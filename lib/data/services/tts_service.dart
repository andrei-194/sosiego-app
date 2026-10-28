import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/spoken_reference.dart';

/// Clave de la velocidad de voz en shared_preferences (spec §6).
const ttsRateKey = 'tts_rate';

/// Motor de voz detrás de una interfaz (con fake para pruebas).
abstract interface class TtsEngine {
  /// Deja puesta la mejor voz en español y devuelve su idioma, o `null` si el
  /// teléfono no tiene voz en español (HU-08.7).
  Future<String?> chooseSpanishVoice();

  Future<void> setRate(double rate);

  /// Dice [text] y termina cuando acaba o cuando se llama a [stop].
  /// Lanza si el motor falla.
  Future<void> speak(String text);

  Future<void> stop();
}

/// Motor real: flutter_tts con la voz del sistema.
class FlutterTtsEngine implements TtsEngine {
  FlutterTts? _tts;
  Completer<void>? _done;
  String? _error;

  FlutterTts _ensure() {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    void finish() {
      final d = _done;
      if (d != null && !d.isCompleted) d.complete();
    }

    tts.setCompletionHandler(finish);
    tts.setCancelHandler(finish);
    tts.setErrorHandler((message) {
      _error = message.toString();
      finish();
    });
    return _tts = tts;
  }

  @override
  Future<String?> chooseSpanishVoice() async {
    final tts = _ensure();
    final raw = await tts.getLanguages;
    final available = [
      if (raw is List)
        for (final l in raw) l.toString(),
    ];
    for (final locale in spanishLocaleCandidates(available)) {
      final ok = await tts.setLanguage(locale);
      if (ok == 1 || ok == true) return locale;
    }
    return null;
  }

  @override
  Future<void> setRate(double rate) async => _ensure().setSpeechRate(rate);

  @override
  Future<void> speak(String text) async {
    final tts = _ensure();
    _error = null;
    final done = _done = Completer<void>();
    // `focus: true` pide el foco de audio para que otras apps bajen su sonido.
    final started = await tts.speak(text, focus: true);
    if (started != 1) {
      throw StateError('El motor de voz no pudo empezar');
    }
    await done.future;
    final error = _error;
    if (error != null) throw StateError(error);
  }

  @override
  Future<void> stop() async {
    final tts = _tts;
    if (tts == null) return;
    await tts.stop();
    final d = _done;
    if (d != null && !d.isCompleted) d.complete();
  }
}

enum TtsStatus { stopped, playing, paused }

/// Qué salió mal, para decirlo en lenguaje sencillo.
enum TtsProblem { none, noSpanishVoice, failed }

class TtsState {
  const TtsState({
    this.status = TtsStatus.stopped,
    this.activeKey,
    this.problem = TtsProblem.none,
    this.problemKey,
  });

  final TtsStatus status;

  /// Quién está leyendo (p. ej. `verso-19023001`): solo su botón cambia a
  /// «Pausar» y «Detener».
  final String? activeKey;
  final TtsProblem problem;

  /// A quién pertenece el problema (para mostrarlo bajo su botón).
  final String? problemKey;

  bool isActive(String key) => activeKey == key && status != TtsStatus.stopped;
}

/// Reproduce una lista de bloques con pausa entre ellos. «Pausar» detiene la
/// voz y, al continuar, repite desde el inicio del bloque en curso (así se
/// comporta igual en todos los teléfonos). Se detiene al salir de la
/// pantalla, al cambiar de versículo y al perder el foco de audio.
class TtsController extends StateNotifier<TtsState>
    with WidgetsBindingObserver {
  TtsController(
    this._engine,
    this._readRate, {
    this.blockPause = listenBlockPause,
    Future<void> Function(Duration)? delay,
    bool observeLifecycle = true,
  }) : _delay = delay ?? Future<void>.delayed,
       super(const TtsState()) {
    if (observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _observing = observeLifecycle;
  }

  final TtsEngine _engine;
  final double Function() _readRate;
  final Duration blockPause;
  final Future<void> Function(Duration) _delay;
  late final bool _observing;

  List<String> _segments = const [];
  int _index = 0;
  int _token = 0;

  @override
  void dispose() {
    _token++;
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    unawaited(_safeStop());
    super.dispose();
  }

  /// Perder el foco de audio (una llamada, otra app): la app pasa a segundo
  /// plano y la lectura se detiene.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      onAudioFocusLost();
    }
  }

  void onAudioFocusLost() => unawaited(stop());

  Future<void> _safeStop() async {
    try {
      await _engine.stop();
    } catch (_) {}
  }

  /// Empieza a leer [segments] a nombre de [key].
  Future<void> play(String key, List<String> segments) async {
    final token = ++_token;
    await _safeStop();
    if (token != _token) return;
    _segments = segments;
    _index = 0;
    state = TtsState(status: TtsStatus.playing, activeKey: key);
    await _run(token, key);
  }

  Future<void> pause() async {
    if (state.status != TtsStatus.playing) return;
    _token++;
    state = TtsState(status: TtsStatus.paused, activeKey: state.activeKey);
    await _safeStop();
  }

  Future<void> resume() async {
    final key = state.activeKey;
    if (state.status != TtsStatus.paused || key == null) return;
    final token = ++_token;
    state = TtsState(status: TtsStatus.playing, activeKey: key);
    await _run(token, key);
  }

  Future<void> stop() async {
    _token++;
    if (mounted && state.status != TtsStatus.stopped) {
      state = const TtsState();
    }
    await _safeStop();
  }

  /// Detiene la lectura solo si es la de [key] (al salir de su pantalla).
  Future<void> stopIfActive(String key) async {
    if (mounted && state.activeKey == key) await stop();
  }

  Future<void> _run(int token, String key) async {
    try {
      final locale = await _engine.chooseSpanishVoice();
      if (token != _token) return;
      if (locale == null) {
        _fail(TtsProblem.noSpanishVoice, key);
        return;
      }
      await _engine.setRate(_readRate());
      while (_index < _segments.length) {
        if (token != _token) return;
        await _engine.speak(_segments[_index]);
        if (token != _token) return;
        _index++;
        if (_index < _segments.length) {
          await _delay(blockPause);
        }
      }
      if (token == _token) state = const TtsState();
    } catch (_) {
      if (token == _token) _fail(TtsProblem.failed, key);
    }
  }

  void _fail(TtsProblem problem, String key) {
    _token++;
    state = TtsState(problem: problem, problemKey: key);
  }
}

/// Velocidad de voz elegida (`tts_rate`): 0.4, 0.5 o 0.6.
class TtsRateNotifier extends StateNotifier<double> {
  TtsRateNotifier() : super(VoiceSpeed.normal.rate) {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted) state = VoiceSpeed.fromRate(p.getDouble(ttsRateKey)).rate;
    } catch (_) {}
  }

  Future<void> choose(VoiceSpeed speed) async {
    state = speed.rate;
    try {
      await (await SharedPreferences.getInstance()).setDouble(
        ttsRateKey,
        speed.rate,
      );
    } catch (_) {}
  }
}

final ttsRateProvider = StateNotifierProvider<TtsRateNotifier, double>(
  (_) => TtsRateNotifier(),
);

final ttsEngineProvider = Provider<TtsEngine>((_) => FlutterTtsEngine());

/// Pausa entre bloques (medio segundo); las pruebas la ponen en cero.
final ttsBlockPauseProvider = Provider<Duration>((_) => listenBlockPause);

final ttsControllerProvider = StateNotifierProvider<TtsController, TtsState>(
  (ref) => TtsController(
    ref.watch(ttsEngineProvider),
    () => ref.read(ttsRateProvider),
    blockPause: ref.watch(ttsBlockPauseProvider),
  ),
);
