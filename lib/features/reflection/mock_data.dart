// DATOS DE MUESTRA. Sustituir por reflections / daily_calendar /
// verse_similar cuando exista la lógica (fase siguiente). Textos de
// ejemplo, no son contenido final.
import '../../domain/content_models.dart';

const mockReflections = <int, Reflection>{
  19023001: Reflection(
    id: 1,
    verseId: 19023001,
    kind: ReflectionKind.daily,
    title: 'Descansar también es avanzar',
    body:
        'Un pastor no empuja a sus ovejas: las lleva. Hoy no tienes que '
        'resolverlo todo ni demostrar nada.\n\n'
        'Hay un lugar tranquilo preparado para ti, aunque el día esté lleno. '
        'Respira hondo, suelta lo que no puedes cambiar ahora y permite que '
        'alguien más cargue contigo un rato.',
    prayer:
        'Señor, hazme descansar. Llévame hoy a aguas de reposo y '
        'enséñame a confiar en tu paso, que nunca tiene prisa. Amén.',
    readingSeconds: 90,
  ),
  46013004: Reflection(
    id: 2,
    verseId: 46013004,
    kind: ReflectionKind.daily,
    title: 'Un amor que sabe esperar',
    body:
        'La paciencia casi nunca se nota, pero sostiene todo lo demás. '
        'Amar con calma es dejar que el otro sea quien es, y también '
        'permitirte a ti ser imperfecto.\n\n'
        'Piensa en una persona a quien hoy puedes responder con un poco más '
        'de ternura.',
    prayer:
        'Dios mío, enséñame a amar con paciencia y bondad, empezando por '
        'las personas más cercanas. Amén.',
    readingSeconds: 75,
  ),
  43014027: Reflection(
    id: 3,
    verseId: 43014027,
    kind: ReflectionKind.emotion,
    title: 'Cuando el corazón no se calma',
    body:
        'La ansiedad hace ruido, pero no tiene la última palabra. La paz '
        'que se promete aquí no depende de que todo salga bien: es un '
        'regalo para quien la necesita ahora.\n\n'
        'Prueba esto: inhala despacio, lee el versículo una vez más y '
        'repite solo una frase. No hace falta más.',
    prayer:
        'Jesús, deja tu paz en mi mente cansada. Calma lo que me '
        'inquieta y recuérdame que no estoy solo. Amén.',
    readingSeconds: 100,
  ),
  19046001: Reflection(
    id: 4,
    verseId: 19046001,
    kind: ReflectionKind.emotion,
    title: 'Refugio cuando todo tiembla',
    body:
        'Hay días en que el suelo parece moverse. Un refugio no hace '
        'desaparecer la tormenta, pero te deja atravesarla sin estar a la '
        'intemperie.\n\n'
        'Nombra en voz baja lo que te asusta. Ponerle nombre ya es '
        'ponerle un borde.',
    prayer:
        'Dios, tú eres mi ayuda en el momento difícil. Quédate cerca '
        'mientras todo pasa. Amén.',
    readingSeconds: 80,
  ),
  19023004: Reflection(
    id: 5,
    verseId: 19023004,
    kind: ReflectionKind.moment,
    title: 'Acompañado en el valle',
    body:
        'Hay pérdidas que dejan un silencio muy grande. No tienes que '
        'sentirte distinto ni ir más rápido de lo que puedes.\n\n'
        'El valle es real, pero estas palabras dicen algo importante: no '
        'lo cruzas solo. Puedes llorar, callar o simplemente quedarte aquí '
        'un momento.\n\n'
        'Si el peso se vuelve demasiado, buscar a alguien de confianza '
        'para hablar también es una forma de cuidarte.',
    prayer:
        'Señor, acompáñame en este valle. Sostén mi dolor, y a quienes '
        'extraño, en tus manos. Amén.',
    sensitive: true,
    readingSeconds: 120,
  ),
};

/// verse_id de la reflexión del día para una fecha (daily_calendar de muestra).
const _dailyCycle = <int>[19023001, 46013004, 43014027];

int mockDailyVerseId(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return _dailyCycle[dayOfYear % _dailyCycle.length];
}

/// "Más como este" (verse_similar de muestra): los demás versículos de la
/// base, rotados para que cada uno tenga una lista distinta.
const _sampleIds = <int>[
  19023001,
  19023004,
  19046001,
  20003005,
  43003016,
  43014027,
  46013004,
  46013013,
];

List<int> mockSimilarTo(int verseId, {int count = 4}) {
  final others = _sampleIds.where((id) => id != verseId).toList();
  final start = verseId % others.length;
  return [
    for (var i = 0; i < count && i < others.length; i++)
      others[(start + i) % others.length],
  ];
}
