import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/providers.dart';
import '../../domain/user_data.dart';

/// Ids de los versículos marcados como favoritos, del más antiguo al más
/// reciente. Viven en user.db (spec D11), en el teléfono.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Future<FavoritesRepository?> _repo() async {
    try {
      return await _ref.read(favoritesRepositoryProvider.future);
    } catch (_) {
      return null; // Sin base: la app sigue funcionando sin guardar.
    }
  }

  Future<void> _load() async {
    final repo = await _repo();
    if (repo == null) return;
    final saved = (await repo.list()).map((e) => e.verseId);
    // Lo marcado mientras cargaba (ya en el estado) se conserva.
    if (mounted) state = {...saved, ...state};
  }

  /// Alterna el favorito y devuelve `true` si quedó marcado.
  Future<bool> toggle(int id) async {
    final next = {...state};
    final added = next.add(id);
    if (!added) next.remove(id);
    state = next;
    final repo = await _repo();
    if (added) {
      await repo?.add(id);
    } else {
      await repo?.remove(id);
    }
    return added;
  }
}
