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
  final _dates = <int, DateTime>{};

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
    final saved = await repo.list();
    if (!mounted) return;
    for (final e in saved) {
      _dates.putIfAbsent(e.verseId, () => e.createdAt);
    }
    state = _ordered({...saved.map((e) => e.verseId), ...state});
  }

  Set<int> _ordered(Set<int> ids) {
    final list = ids.toList()
      ..sort((a, b) {
        final c = (_dates[a] ?? DateTime.now()).compareTo(
          _dates[b] ?? DateTime.now(),
        );
        return c != 0 ? c : a.compareTo(b);
      });
    return list.toSet();
  }

  /// Favoritos con su fecha, del más reciente al más antiguo (Guardados).
  List<FavoriteEntry> get entriesNewestFirst => [
    for (final id in state.toList().reversed)
      FavoriteEntry(verseId: id, createdAt: _dates[id] ?? DateTime.now()),
  ];

  /// Alterna el favorito y devuelve `true` si quedó marcado.
  Future<bool> toggle(int id) async {
    final next = {...state};
    final added = next.add(id);
    if (added) {
      _dates[id] = DateTime.now();
    } else {
      next.remove(id);
    }
    state = _ordered(next);
    final repo = await _repo();
    if (added) {
      await repo?.add(id, createdAt: _dates[id]);
    } else {
      await repo?.remove(id);
    }
    return added;
  }

  /// Quita un guardado y devuelve su fecha, para poder deshacer (HU-10.3).
  Future<DateTime?> remove(int id) async {
    final date = _dates[id];
    final next = {...state}..remove(id);
    state = next;
    final repo = await _repo();
    await repo?.remove(id);
    return date;
  }

  /// Restituye un guardado con su fecha original, en su posición (HU-10.3).
  Future<void> restore(int id, DateTime createdAt) async {
    _dates[id] = createdAt;
    state = _ordered({...state, id});
    final repo = await _repo();
    await repo?.add(id, createdAt: createdAt);
  }
}
