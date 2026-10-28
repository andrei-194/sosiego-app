import 'dart:async';

import 'package:sosiego/data/services/notification_service.dart';
import 'package:sosiego/data/services/reminder_service.dart';
import 'package:sosiego/data/services/share_service.dart';
import 'package:sosiego/data/services/tts_service.dart';
import 'package:sosiego/domain/content_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// Motor de voz falso: anota lo que se dijo y deja controlar cuándo termina.
class FakeTtsEngine implements TtsEngine {
  FakeTtsEngine({this.locale = 'es-CO', this.autoFinish = true});

  String? locale;
  bool autoFinish;
  final spoken = <String>[];
  final rates = <double>[];
  int stops = 0;
  Completer<void>? _current;

  @override
  Future<String?> chooseSpanishVoice() async => locale;

  @override
  Future<void> setRate(double rate) async => rates.add(rate);

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (autoFinish) return;
    final c = _current = Completer<void>();
    await c.future;
  }

  /// Termina el bloque que se está diciendo (modo manual).
  void finishCurrent() {
    final c = _current;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> stop() async {
    stops++;
    finishCurrent();
  }
}

class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.grant = true, tz.Location? location})
    : location = location ?? tz.getLocation('America/Bogota');

  bool grant;
  int permissionRequests = 0;
  List<PlannedNotification> scheduled = [];
  String? launch;
  void Function(String?)? onTap;

  @override
  final tz.Location location;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async =>
      this.onTap = onTap;

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<bool> areEnabled() async => grant;

  @override
  Future<void> replaceAll(List<PlannedNotification> items) async =>
      scheduled = items;

  @override
  Future<void> cancelAll() async => scheduled = [];
}

/// Versículo del día de prueba: uno por día, con el día en el texto.
class FakeDailySource implements DailyVerseSource {
  FakeDailySource({this.textFor});
  final String Function(DateTime)? textFor;
  final asked = <DateTime>[];

  @override
  Future<Verse?> verseFor(DateTime localDate) async {
    asked.add(localDate);
    return Verse(
      id: 43003016,
      bookId: 43,
      bookName: 'Juan',
      bookSlug: 'juan',
      chapter: 3,
      verse: 16,
      text:
          textFor?.call(localDate) ??
          'Texto del ${localDate.month}-${localDate.day}',
    );
  }
}

class FakeShareService implements ShareService {
  String? sharedPath;
  String? sharedText;
  Uri? opened;
  bool whatsappWorks = true;

  @override
  Future<void> shareImage({required String path, required String text}) async {
    sharedPath = path;
    sharedText = text;
  }

  @override
  Future<bool> openWhatsapp(Uri uri) async {
    opened = uri;
    return whatsappWorks;
  }
}
