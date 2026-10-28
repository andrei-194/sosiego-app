"""Etapa 3: parecidos. Embeddings multilingues (sentence-transformers) -> 10 vecinos por versiculo.

Solo entre versiculos ELEGIBLES (card_score >= umbral) y con maximo 2 del mismo libro entre los 10.
La seleccion (`select_neighbors`) es Python puro para poder probarla y usarla en la muestra.

Uso:
  python -m pipeline.similar --work work/work.db --model BAAI/bge-m3
  python -m pipeline.similar --work work/work.db --backend hash      # sin modelo, solo para ensayar

Modelo por defecto: BAAI/bge-m3 (MIT; ~2.2 GB al primer uso). `sentence-transformers` NO esta en
requirements.txt base: instalar con `pip install sentence-transformers` cuando se vaya a correr.
"""
from __future__ import annotations

import argparse
import hashlib
import math
import sqlite3
import sys
from pathlib import Path

from . import taxonomy, workdb

DEFAULT_MODEL = "BAAI/bge-m3"


def select_neighbors(candidates: list[tuple[int, float]], book_of: dict[int, int],
                     k: int = taxonomy.SIMILAR_K,
                     max_per_book: int = taxonomy.SIMILAR_MAX_PER_BOOK) -> list[tuple[int, float]]:
    """`candidates`: (verse_id, score) ya SIN el propio versiculo. Devuelve k, orden desc por score,
    con no mas de `max_per_book` del mismo libro. Si no alcanzan, devuelve los que se pueda."""
    out: list[tuple[int, float]] = []
    per_book: dict[int, int] = {}
    for vid, score in sorted(candidates, key=lambda p: (-p[1], p[0])):
        b = book_of[vid]
        if per_book.get(b, 0) >= max_per_book:
            continue
        per_book[b] = per_book.get(b, 0) + 1
        out.append((vid, score))
        if len(out) == k:
            break
    return out


def cosine(a: list[float], b: list[float]) -> float:
    na = math.sqrt(sum(x * x for x in a)) or 1.0
    nb = math.sqrt(sum(x * x for x in b)) or 1.0
    return sum(x * y for x, y in zip(a, b)) / (na * nb)


def hash_embedding(text: str, dim: int = 64) -> list[float]:
    """Embedding falso y determinista (bolsa de palabras hasheadas). Solo para ensayar el flujo."""
    v = [0.0] * dim
    for w in text.split():
        d = hashlib.sha256(w.encode()).digest()
        v[d[0] % dim] += 1.0 if d[1] & 1 else -1.0
    return v


def embed_st(texts: list[str], model_name: str):
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError:
        sys.exit("Falta sentence-transformers: pip install sentence-transformers")
    model = SentenceTransformer(model_name)
    return model.encode(texts, batch_size=64, normalize_embeddings=True, show_progress_bar=True)


def run(work: Path, backend: str, model_name: str, threshold: float) -> int:
    import numpy as np
    con = workdb.connect(work)
    rows = con.execute(
        "SELECT v.id, v.book_id, v.text_norm FROM verses_raw v JOIN verse_scores s ON s.verse_id=v.id "
        "WHERE s.card_score >= ? ORDER BY v.id", (threshold,)).fetchall()
    if not rows:
        sys.exit("No hay versiculos elegibles en work.db (corre antes `pipeline.tag`).")
    ids = [r[0] for r in rows]
    book_of = {r[0]: r[1] for r in rows}
    texts = [r[2] for r in rows]
    if backend == "hash":
        emb = np.array([hash_embedding(t) for t in texts], dtype="float32")
        emb /= (np.linalg.norm(emb, axis=1, keepdims=True) + 1e-9)
        label = "hash-64"
    else:
        emb = np.asarray(embed_st(texts, model_name), dtype="float32")
        label = model_name
    con.execute("DELETE FROM similar")
    n = len(ids)
    for start in range(0, n, 512):
        block = emb[start:start + 512] @ emb.T            # (b, n)
        for i in range(block.shape[0]):
            gi = start + i
            row = block[i]
            top = np.argpartition(-row, min(400, n - 1))[: min(400, n)]   # preseleccion amplia
            cand = [(ids[j], float(row[j])) for j in top if j != gi]
            chosen = select_neighbors(cand, book_of)
            if len(chosen) < taxonomy.SIMILAR_K:           # preseleccion corta: reintenta con todo
                cand = [(ids[j], float(row[j])) for j in range(n) if j != gi]
                chosen = select_neighbors(cand, book_of)
            con.executemany(
                "INSERT INTO similar(verse_id, rank, similar_id, score, model) VALUES (?,?,?,?,?)",
                [(ids[gi], r, sid, sc, label) for r, (sid, sc) in enumerate(chosen, start=1)])
    con.commit()
    print(f"similar: {n} versiculos elegibles procesados (modelo {label})")
    return n


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--backend", choices=["st", "hash"], default="st")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--threshold", type=float, default=taxonomy.CARD_SCORE_THRESHOLD)
    a = ap.parse_args(argv)
    run(a.work, a.backend, a.model, a.threshold)


if __name__ == "__main__":
    main()
