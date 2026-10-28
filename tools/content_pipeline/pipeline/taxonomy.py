"""Taxonomia inicial (spec §5): 10 emociones, 12 momentos y una lista corta y cerrada de temas.

Se ajusta en la revision humana. Los `icon` son nombres de Material Icons (la app los mapea).
"""
from __future__ import annotations

from dataclasses import dataclass

CARD_SCORE_THRESHOLD = 0.6      # umbral inicial de elegibilidad (spec §4)
THEME_MIN_WEIGHT = 0.3          # verse_themes solo guarda pesos >= 0.3
SIMILAR_K = 10
SIMILAR_MAX_PER_BOOK = 2
MIN_VERSES_PER_EMOTION = 40     # prueba de datos 4 (peso >= 0.6)
MIN_VERSES_PER_MOMENT = 15
EMOTION_STRONG_WEIGHT = 0.6


@dataclass(frozen=True)
class Theme:
    slug: str
    name_es: str
    kind: str   # 'emotion' | 'topic'
    icon: str


@dataclass(frozen=True)
class Moment:
    slug: str
    name_es: str
    description: str
    icon: str


EMOTIONS = [
    Theme("ansiedad", "Ansiedad", "emotion", "waves"),
    Theme("tristeza", "Tristeza", "emotion", "water_drop"),
    Theme("gratitud", "Gratitud", "emotion", "favorite"),
    Theme("miedo", "Miedo", "emotion", "shield"),
    Theme("soledad", "Soledad", "emotion", "person"),
    Theme("perdon", "Perdón", "emotion", "handshake"),
    Theme("esperanza", "Esperanza", "emotion", "wb_sunny"),
    Theme("cansancio", "Cansancio", "emotion", "bedtime"),
    Theme("enojo", "Enojo", "emotion", "local_fire_department"),
    Theme("duda", "Duda", "emotion", "help_outline"),
]

# Temas de apoyo (kind='topic'); lista cerrada y ajustable en la revision.
TOPICS = [
    Theme("amor", "Amor", "topic", "volunteer_activism"),
    Theme("paz", "Paz", "topic", "spa"),
    Theme("fe", "Fe", "topic", "auto_awesome"),
    Theme("sabiduria", "Sabiduría", "topic", "lightbulb"),
    Theme("proteccion", "Protección", "topic", "security"),
]

THEMES = EMOTIONS + TOPICS
THEME_SLUGS = [t.slug for t in THEMES]
EMOTION_SLUGS = [t.slug for t in EMOTIONS]

MOMENTS = [
    Moment("al-despertar", "Al despertar", "Para comenzar el día con calma y gratitud.", "wb_twilight"),
    Moment("antes-de-dormir", "Antes de dormir", "Para soltar el día y descansar en paz.", "nights_stay"),
    Moment("antes-de-comer", "Antes de comer", "Un momento para agradecer el alimento.", "restaurant"),
    Moment("antes-de-un-viaje", "Antes de un viaje", "Para salir con tranquilidad y confianza.", "flight_takeoff"),
    Moment("antes-de-una-cita-medica", "Antes de una cita médica", "Para esperar un resultado con serenidad.", "medical_services"),
    Moment("familiar-enfermo", "Familiar enfermo", "Compañía para quien cuida a un ser querido enfermo.", "volunteer_activism"),
    Moment("entrevista-o-examen", "Entrevista o examen", "Para presentarse con calma ante una prueba.", "school"),
    Moment("problemas-de-dinero", "Problemas de dinero", "Para los días de preocupación por el sustento.", "savings"),
    Moment("perdida-de-un-ser-querido", "Pérdida de un ser querido", "Consuelo en el duelo, sin prisa.", "spa"),
    Moment("nacimiento-o-cumpleanos", "Nacimiento o cumpleaños", "Para celebrar una vida y dar gracias.", "cake"),
    Moment("reconciliarse", "Reconciliarse", "Para dar el primer paso hacia la paz con alguien.", "handshake"),
    Moment("dar-gracias", "Dar gracias", "Para reconocer lo recibido con un corazón agradecido.", "favorite"),
]
MOMENT_SLUGS = [m.slug for m in MOMENTS]

# Cuotas de reflexiones del spec §5: 365 del dia + 10 emociones x 20 + 12 momentos x 10 = 685
REFLECTIONS_DAILY = 365
REFLECTIONS_PER_EMOTION = 20
REFLECTIONS_PER_MOMENT = 10
