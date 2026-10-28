// DATOS DE MUESTRA. Sustituir por consultas a themes / verse_themes /
// moments / moment_verses cuando exista la lógica (fase siguiente).
// Los ids de versículo son los de la base de muestra (assets/db/content.db).
import '../../domain/content_models.dart';

const mockTopics = <Topic>[
  Topic(id: 'esperanza', label: 'Esperanza', emoji: '🌅'),
  Topic(id: 'paz', label: 'Paz', emoji: '🕊️'),
  Topic(id: 'fe', label: 'Fe', emoji: '🌱'),
  Topic(id: 'amor', label: 'Amor', emoji: '💛'),
  Topic(id: 'fortaleza', label: 'Fortaleza', emoji: '🛡️'),
  Topic(id: 'gratitud', label: 'Gratitud', emoji: '🙏'),
  Topic(id: 'sabiduria', label: 'Sabiduría', emoji: '📖'),
  Topic(id: 'perdon', label: 'Perdón', emoji: '🤍'),
];

const mockMoments = <Moment>[
  Moment(id: 'ansiedad', label: 'Ansiedad', blurb: 'Cuando la mente no para'),
  Moment(
    id: 'duelo',
    label: 'Duelo',
    blurb: 'Cuando extrañas a alguien',
    delicate: true,
  ),
  Moment(
    id: 'cansancio',
    label: 'Cansancio',
    blurb: 'Cuando necesitas descansar',
  ),
  Moment(
    id: 'soledad',
    label: 'Soledad',
    blurb: 'Cuando te sientes solo o sola',
  ),
  Moment(
    id: 'enfermedad',
    label: 'Enfermedad',
    blurb: 'Para días de cuidado y espera',
    delicate: true,
  ),
  Moment(
    id: 'decision',
    label: 'Una decisión difícil',
    blurb: 'Cuando no sabes qué camino tomar',
  ),
  Moment(
    id: 'comienzo',
    label: 'Un nuevo comienzo',
    blurb: 'Cuando algo empieza de nuevo',
  ),
];

/// theme_id / moment_id -> ids de versículo.
const mockTopicVerses = <String, List<int>>{
  'esperanza': [19046001, 43003016, 46013013],
  'paz': [43014027, 19023001, 19023004],
  'fe': [20003005, 46013013, 43003016],
  'amor': [46013004, 43003016, 46013013],
  'fortaleza': [19046001, 19023004, 20003005],
  'gratitud': [19023001, 46013004],
  'sabiduria': [20003005, 19023001],
  'perdon': [43003016, 46013004],
  'ansiedad': [43014027, 20003005, 19046001],
  'duelo': [19023004, 43014027, 19046001],
  'cansancio': [19023001, 43014027],
  'soledad': [19023001, 19023004, 43014027],
  'enfermedad': [19023001, 19046001],
  'decision': [20003005, 19023001],
  'comienzo': [43003016, 19046001, 46013013],
};

Topic? mockTopic(String id) {
  for (final t in mockTopics) {
    if (t.id == id) return t;
  }
  return null;
}

Moment? mockMoment(String id) {
  for (final m in mockMoments) {
    if (m.id == id) return m;
  }
  return null;
}
