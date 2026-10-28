"""Cliente minimo de Ollama (solo biblioteca estandar + jsonschema) con salida JSON validada.

- Pide a Ollama salida estructurada (`format` = JSON Schema) con temperatura 0.2 y semilla fija.
- Valida el JSON contra el esquema (jsonschema) y, opcionalmente, con un validador extra.
- Si no cumple, reintenta (hasta `retries`) devolviendo al modelo los errores concretos.
- Devuelve todo lo necesario para guardarlo en work.db: prompt, modelo, temperatura, semilla.
"""
from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Callable

import jsonschema

HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
DEFAULT_TEMPERATURE = 0.2
DEFAULT_SEED = 42


class OllamaUnavailable(RuntimeError):
    pass


@dataclass
class Result:
    data: dict | None
    valid: bool
    raw: str
    attempts: int
    error: str | None
    seed: int
    temperature: float
    model: str
    prompt: str                 # system + user, tal como se envio (primer intento)
    duration_s: float = 0.0
    errors_history: list[str] = field(default_factory=list)


def list_models(host: str = HOST) -> list[str]:
    try:
        with urllib.request.urlopen(f"{host}/api/tags", timeout=5) as r:
            return [m["name"] for m in json.load(r)["models"]]
    except (urllib.error.URLError, OSError) as e:
        raise OllamaUnavailable(f"Ollama no responde en {host}: {e}") from e


def _post_chat(host: str, payload: dict, timeout: float) -> str:
    req = urllib.request.Request(f"{host}/api/chat", data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)["message"]["content"]
    except (urllib.error.URLError, OSError) as e:
        raise OllamaUnavailable(f"fallo la llamada a Ollama: {e}") from e


def chat_json(model: str, system: str, user: str, schema: dict, *,
              temperature: float = DEFAULT_TEMPERATURE, seed: int = DEFAULT_SEED,
              retries: int = 3, timeout: float = 600, host: str = HOST,
              extra_validator: Callable[[dict], list[str]] | None = None,
              num_predict: int = 900,
              transport: Callable[[str, dict, float], str] = _post_chat) -> Result:
    """`transport` es inyectable para las pruebas (sin Ollama real)."""
    messages = [{"role": "system", "content": system}, {"role": "user", "content": user}]
    prompt = f"[system]\n{system}\n\n[user]\n{user}"
    t0 = time.time()
    history: list[str] = []
    raw, data, err = "", None, None
    for attempt in range(1, retries + 2):
        cur_seed = seed + attempt - 1
        payload = {"model": model, "messages": messages, "stream": False, "format": schema,
                   "options": {"temperature": temperature, "seed": cur_seed, "num_predict": num_predict}}
        raw = transport(host, payload, timeout)
        errs: list[str] = []
        data = None
        try:
            data = json.loads(raw)
            jsonschema.validate(data, schema)
            if extra_validator:
                errs = extra_validator(data)
        except json.JSONDecodeError as e:
            errs = [f"no es JSON valido: {e}"]
            data = None
        except jsonschema.ValidationError as e:
            errs = [f"no cumple el esquema: {e.message}"]
            data = None
        if not errs:
            return Result(data, True, raw, attempt, None, cur_seed, temperature, model, prompt,
                          time.time() - t0, history)
        err = "; ".join(errs)
        history.append(err)
        messages = messages + [
            {"role": "assistant", "content": raw},
            {"role": "user", "content": "Tu respuesta no es valida: " + err +
             ". Corrigela y responde de nuevo SOLO con el JSON."},
        ]
    return Result(data, False, raw, retries + 1, err, cur_seed, temperature, model, prompt,
                  time.time() - t0, history)
