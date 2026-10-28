import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notification_plan.dart';

/// Ruta que abre una notificación del versículo diario (HU-07.7).
const dailyNotificationRoute = '/hoy';

/// Una notificación por programar: ya con el texto de su día.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    this.payload = dailyNotificationRoute,
  });

  final int id;
  final tz.TZDateTime when;
  final String title;

  /// Versículo (cortado a 180) y referencia; sale también como texto largo.
  final String body;
  final String payload;
}

/// Notificaciones locales detrás de una interfaz (con fake para pruebas).
abstract interface class NotificationService {
  /// Prepara el plugin y el canal. [onTap] recibe el `payload` cuando se toca
  /// una notificación con la app abierta o en segundo plano.
  Future<void> init({required void Function(String? payload) onTap});

  /// Payload de la notificación que abrió la app desde cero, si la hay.
  Future<String?> launchPayload();

  /// Pide POST_NOTIFICATIONS (Android 13 o superior). `true` si se concede.
  /// Solo se llama cuando la persona toca una hora (HU-07.3).
  Future<bool> requestPermission();

  Future<bool> areEnabled();

  /// Reemplaza todo lo programado por [items].
  Future<void> replaceAll(List<PlannedNotification> items);

  Future<void> cancelAll();

  /// Zona horaria con la que se calcula la programación.
  tz.Location get location;
}

/// Canal propio del versículo diario.
const dailyChannelId = 'versiculo_diario';
const dailyChannelName = 'Versículo diario';
const dailyChannelDescription =
    'Un versículo cada día a la hora que elijas, sin sonidos fuertes.';

class LocalNotificationService implements NotificationService {
  LocalNotificationService(this._location);

  final tz.Location _location;
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  tz.Location get location => _location;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        dailyChannelId,
        dailyChannelName,
        description: dailyChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<void> replaceAll(List<PlannedNotification> items) async {
    await _plugin.cancelAllPendingNotifications();
    for (final n in items) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: n.when,
        title: n.title,
        body: n.body,
        payload: n.payload,
        // Modo inexacto: no exige el permiso de alarmas exactas (HU-07.5);
        // puede llegar con unos minutos de retraso.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            dailyChannelId,
            dailyChannelName,
            channelDescription: dailyChannelDescription,
            icon: '@drawable/ic_notification',
            // Texto largo: el versículo completo (ya cortado a 180) al
            // desplegar la notificación.
            styleInformation: BigTextStyleInformation(
              n.body,
              contentTitle: n.title,
            ),
          ),
        ),
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAllPendingNotifications();
}

/// Reemplazo sin plugin (pruebas de widgets y plataformas sin notificaciones).
class NoopNotificationService implements NotificationService {
  NoopNotificationService(this._location);
  final tz.Location _location;

  @override
  tz.Location get location => _location;
  @override
  Future<void> init({required void Function(String? payload) onTap}) async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> areEnabled() async => true;
  @override
  Future<void> replaceAll(List<PlannedNotification> items) async {}
  @override
  Future<void> cancelAll() async {}
}

/// Se sustituye en las pruebas. En producción es el servicio real; fuera de
/// Android (pruebas de escritorio) no hace nada.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final location = ref.watch(deviceLocationProvider);
  return defaultTargetPlatform == TargetPlatform.android && !kIsWeb
      ? LocalNotificationService(location)
      : NoopNotificationService(location);
});

/// Zona horaria del teléfono sin plugin nativo (ver `resolveDeviceLocation`):
/// America/Bogota si el desfase coincide y, si no, una zona con el mismo
/// desfase. Evaluado y descartado `flutter_timezone` por ahora (decisión en
/// docs/licencias-dependencias.md).
final deviceLocationProvider = Provider<tz.Location>((_) {
  tzdata.initializeTimeZones();
  final now = DateTime.now();
  return resolveDeviceLocation(deviceOffset: now.timeZoneOffset, now: now);
});
