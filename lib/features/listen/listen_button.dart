import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content/content_repository.dart';

/// CONTRATO (HU-08): botón «Escuchar» con texto visible que pasa a «Pausar» y
/// «Detener»; mínimo 56 dp. Stub: lo reemplaza el frente de funciones.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
