import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hoja de compartir del sistema y WhatsApp (spec §9). Detrás de una interfaz
/// para probar sin plugins. Ni la imagen ni la dedicatoria se envían a
/// ningún servidor propio: solo salen por la hoja del sistema o por WhatsApp,
/// a donde la persona decide.
abstract interface class ShareService {
  /// Abre la hoja del sistema con la imagen PNG en [path] y el [text].
  Future<void> shareImage({required String path, required String text});

  /// Abre `https://wa.me/?text=` en una aplicación externa. `false` si el
  /// teléfono no pudo abrirlo.
  Future<bool> openWhatsapp(Uri uri);
}

class PluginShareService implements ShareService {
  const PluginShareService();

  @override
  Future<void> shareImage({required String path, required String text}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile(path, mimeType: 'image/png')],
      ),
    );
  }

  @override
  Future<bool> openWhatsapp(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final shareServiceProvider = Provider<ShareService>(
  (_) => const PluginShareService(),
);
