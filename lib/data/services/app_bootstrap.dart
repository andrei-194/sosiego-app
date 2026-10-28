import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/reminder_policy.dart';
import '../user/providers.dart';
import 'notification_service.dart';
import 'reminder_service.dart';

/// Borra las imágenes temporales de compartir (`share_*.png`) de [dir].
/// Devuelve cuántas borró (spec §9: «se borran al iniciar la app»).
Future<int> cleanShareTempFiles(Directory dir) async {
  var removed = 0;
  try {
    if (!await dir.exists()) return 0;
    await for (final e in dir.list()) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      if (name.startsWith('share_') && name.endsWith('.png')) {
        try {
          await e.delete();
          removed++;
        } catch (_) {}
      }
    }
  } catch (_) {}
  return removed;
}

/// Tareas de arranque de los servicios: limpiar temporales, contar la
/// apertura, preparar las notificaciones, atender el toque que abrió la app y
/// reprogramar las próximas 30. Cada paso falla en silencio: ninguno puede
/// impedir que la app abra.
class AppBootstrap {
  AppBootstrap(this._ref);
  final Ref _ref;
  bool _started = false;

  Future<void> start(GoRouter router) async {
    if (_started) return;
    _started = true;
    await _step(() async {
      await cleanShareTempFiles(await getTemporaryDirectory());
    });
    await _step(() async {
      final app = await _ref.read(appStateRepositoryProvider.future);
      final n =
          int.tryParse(await app.get(ReminderStateKeys.openCount) ?? '') ?? 0;
      await app.set(ReminderStateKeys.openCount, '${n + 1}');
      // La tarjeta de Inicio vuelve a calcular con la apertura ya contada.
      _ref.invalidate(reminderCardProvider);
    });
    await _step(() async {
      final service = _ref.read(notificationServiceProvider);
      await service.init(onTap: (payload) => _open(router, payload));
      await _open(router, await service.launchPayload());
    });
    await _step(
      () => _ref.read(reminderControllerProvider.notifier).reschedule(),
    );
  }

  /// Tocar la notificación lleva a /hoy, con la app abierta o cerrada.
  Future<void> _open(GoRouter router, String? payload) async {
    if (payload == null || !payload.startsWith('/')) return;
    final here = router.routerDelegate.currentConfiguration.uri.path;
    if (here == payload) return;
    unawaited(router.push(payload));
  }

  Future<void> _step(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Arranque de servicios: $e');
    }
  }
}

final appBootstrapProvider = Provider<AppBootstrap>(AppBootstrap.new);
