import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notification_plan.dart';
import '../../domain/reminder_policy.dart';
import '../../domain/user_data.dart';
import '../content/content_repository.dart';
import '../content/providers.dart';
import '../user/providers.dart';
import '../../l10n/app_localizations_es.dart';
import 'notification_service.dart';

/// Claves de shared_preferences (spec §6).
const notifEnabledKey = 'notif_enabled';
const notifTimeKey = 'notif_time';

/// Hora por defecto si la persona activa sin elegir (la de la mañana).
const defaultReminderTime = '06:30';

/// Reloj inyectable (pruebas).
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Versículo del día para una fecha local (`daily_calendar`, HU-07.1).
/// Interfaz propia para programar sin depender de la base en las pruebas.
abstract interface class DailyVerseSource {
  Future<Verse?> verseFor(DateTime localDate);
}

/// Texto que lleva cada notificación: título y cuerpo (versículo cortado a
/// 180 caracteres y referencia).
typedef NotificationTexts = ({String title, String body});

NotificationTexts notificationTexts(Verse verse, {required String title}) => (
  title: title,
  body: '«${truncateForNotification(verse.text)}»\n${verse.reference}',
);

/// Programa las próximas [count] notificaciones desde [now] (HU-07.5). Los
/// días sin versículo en el calendario se omiten. Devuelve cuántas quedaron.
Future<int> scheduleDailyNotifications({
  required NotificationService service,
  required DailyVerseSource source,
  required DateTime now,
  required String time,
  required String title,
  int count = scheduledNotificationCount,
}) async {
  final parsed = parseTimeOfDay(time) ?? parseTimeOfDay(defaultReminderTime)!;
  final plan = planDailySchedule(
    now: tz.TZDateTime.from(now, service.location),
    hour: parsed.hour,
    minute: parsed.minute,
    count: count,
  );
  final items = <PlannedNotification>[];
  for (var i = 0; i < plan.length; i++) {
    final verse = await source.verseFor(plan[i].localDate);
    if (verse == null) continue;
    final t = notificationTexts(verse, title: title);
    items.add(
      PlannedNotification(
        id: i + 1,
        when: plan[i].when,
        title: t.title,
        body: t.body,
      ),
    );
  }
  await service.replaceAll(items);
  return items.length;
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.time = defaultReminderTime,
  });
  final bool enabled;
  final String time;

  ReminderSettings copyWith({bool? enabled, String? time}) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    time: time ?? this.time,
  );
}

enum EnableResult { enabled, denied }

/// Activa, desactiva y reprograma el versículo diario (HU-07 y HU-12).
class ReminderController extends StateNotifier<ReminderSettings> {
  ReminderController(this._ref) : super(const ReminderSettings()) {
    _loaded = _load();
  }

  final Ref _ref;
  late final Future<void> _loaded;

  Future<void> get loaded => _loaded;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final time = parseTimeOfDay(p.getString(notifTimeKey)) == null
          ? defaultReminderTime
          : p.getString(notifTimeKey)!;
      if (mounted) {
        state = ReminderSettings(
          enabled: p.getBool(notifEnabledKey) ?? false,
          time: time,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(notifEnabledKey, state.enabled);
      await p.setString(notifTimeKey, state.time);
    } catch (_) {}
  }

  /// Pide el permiso del sistema (solo aquí, al tocar una hora) y, si lo
  /// conceden, activa y programa. Si lo niegan no cambia nada.
  Future<EnableResult> enable(String time) async {
    await _loaded;
    final service = _ref.read(notificationServiceProvider);
    final granted = await _safe(service.requestPermission, false);
    if (!granted) return EnableResult.denied;
    state = ReminderSettings(enabled: true, time: time);
    await _save();
    await reschedule();
    return EnableResult.enabled;
  }

  Future<void> disable() async {
    await _loaded;
    state = state.copyWith(enabled: false);
    await _save();
    await _safe(_ref.read(notificationServiceProvider).cancelAll, null);
  }

  /// Cambia la hora y, si está activado, reprograma (HU-07.5).
  Future<void> setTime(String time) async {
    await _loaded;
    state = state.copyWith(time: time);
    await _save();
    if (state.enabled) await reschedule();
  }

  /// Reprograma las próximas 30 (al abrir la app y al cambiar la hora).
  Future<void> reschedule() async {
    await _loaded;
    if (!state.enabled) return;
    try {
      await scheduleDailyNotifications(
        service: _ref.read(notificationServiceProvider),
        source: _ref.read(dailyVerseSourceProvider),
        now: _ref.read(clockProvider)(),
        time: state.time,
        title: AppLocalizationsEs().reminderNotificationTitle,
      );
    } catch (e) {
      debugPrint('No se pudo programar el versículo diario: $e');
    }
  }

  Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }
}

final reminderControllerProvider =
    StateNotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );

/// Versículo del día desde `daily_calendar` (ContentRepository.dailyVerseFor).
final dailyVerseSourceProvider = Provider<DailyVerseSource>(
  (ref) =>
      _RepositoryDailySource(() => ref.read(contentRepositoryProvider.future)),
);

class _RepositoryDailySource implements DailyVerseSource {
  _RepositoryDailySource(this._repo);
  final Future<ContentRepository> Function() _repo;

  @override
  Future<Verse?> verseFor(DateTime localDate) async =>
      (await _repo()).dailyVerseFor(localDate);
}

/// Estado de la tarjeta de Inicio (HU-07.3/07.4).
enum ReminderCardPhase { hidden, ask, denied, done }

class ReminderCardState {
  const ReminderCardState(this.phase, {this.time});
  final ReminderCardPhase phase;

  /// Hora elegida (`HH:mm`) para el mensaje de «Listo».
  final String? time;
}

class ReminderCardController extends StateNotifier<ReminderCardState> {
  ReminderCardController(this._ref)
    : super(const ReminderCardState(ReminderCardPhase.hidden)) {
    refresh();
  }

  final Ref _ref;

  Future<AppStateRepository> get _appState =>
      _ref.read(appStateRepositoryProvider.future);

  /// Vuelve a calcular si corresponde mostrarla.
  Future<void> refresh() async {
    try {
      final reminder = _ref.read(reminderControllerProvider.notifier);
      await reminder.loaded;
      final settings = _ref.read(reminderControllerProvider);
      final app = await _appState;
      final history = await _ref.read(historyRepositoryProvider.future);
      final opens =
          int.tryParse(await app.get(ReminderStateKeys.openCount) ?? '') ?? 0;
      final seen = (await history.recent(limit: reminderVersesThreshold))
          .length;
      final count =
          int.tryParse(await app.get(ReminderStateKeys.dismissCount) ?? '') ??
          0;
      final at = int.tryParse(
        await app.get(ReminderStateKeys.dismissedAt) ?? '',
      );
      final show = shouldShowReminderCard(
        enabled: settings.enabled,
        openCount: opens,
        versesSeen: seen,
        dismissCount: count,
        dismissedAt: at == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(at),
        now: _ref.read(clockProvider)(),
      );
      if (mounted && state.phase == ReminderCardPhase.hidden && show) {
        state = const ReminderCardState(ReminderCardPhase.ask);
      }
    } catch (_) {}
  }

  /// «Ahora no»: se anota para volver una sola vez a los 7 días.
  Future<void> dismiss() async {
    state = const ReminderCardState(ReminderCardPhase.hidden);
    await _recordDismiss();
  }

  /// [definitive] marca la respuesta como definitiva (permiso negado): la tarjeta
  /// no vuelve y solo queda Ajustes.
  Future<void> _recordDismiss({bool definitive = false}) async {
    try {
      final app = await _appState;
      final count =
          int.tryParse(await app.get(ReminderStateKeys.dismissCount) ?? '') ??
          0;
      await app.set(
        ReminderStateKeys.dismissCount,
        '${definitive ? 2 : count + 1}',
      );
      await app.set(
        ReminderStateKeys.dismissedAt,
        '${_ref.read(clockProvider)().millisecondsSinceEpoch}',
      );
    } catch (_) {}
  }

  /// La persona tocó una hora: aquí (y solo aquí) se pide el permiso.
  Future<void> choose(String time) async {
    final result = await _ref
        .read(reminderControllerProvider.notifier)
        .enable(time);
    if (!mounted) return;
    if (result == EnableResult.enabled) {
      state = ReminderCardState(ReminderCardPhase.done, time: time);
    } else {
      state = const ReminderCardState(ReminderCardPhase.denied);
      // Sin permiso no se insiste: queda solo en Ajustes.
      await _recordDismiss(definitive: true);
    }
  }

  /// Cierra el mensaje de «Listo» o de permiso negado.
  void close() => state = const ReminderCardState(ReminderCardPhase.hidden);
}

final reminderCardProvider =
    StateNotifierProvider<ReminderCardController, ReminderCardState>(
      ReminderCardController.new,
    );
