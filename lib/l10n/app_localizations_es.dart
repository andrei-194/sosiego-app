// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sosiego';

  @override
  String get navHome => 'Inicio';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navSaved => 'Guardados';

  @override
  String get actionBack => 'Volver';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get translationName => 'Reina-Valera 1909';

  @override
  String verseSemantics(String text, String reference) {
    return '$text. $reference';
  }

  @override
  String bookChapter(String book, int chapter) {
    return '$book $chapter';
  }

  @override
  String get moreLikeThis => 'Más como este';

  @override
  String get readChapter => 'Leer el capítulo';

  @override
  String readingTime(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String longDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat(
      'EEEE d \'de\' MMMM',
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get feedSwipeHintSemantics =>
      'Desliza hacia arriba para ver el siguiente versículo';

  @override
  String get feedSwipeHint => 'Desliza para el siguiente';

  @override
  String get feedLoadingSemantics => 'Preparando un versículo';

  @override
  String get feedLoading => 'Preparando un versículo…';

  @override
  String get feedErrorTitle => 'No pudimos abrir los versículos';

  @override
  String get feedErrorBody =>
      'No es culpa tuya. Intenta de nuevo; si sigue igual, cierra y vuelve a abrir la app.';

  @override
  String get feedRetry => 'Intentar de nuevo';

  @override
  String verseCopyText(String text, String reference) {
    return '“$text”\n— $reference (Reina-Valera 1909)';
  }

  @override
  String get verseCopied => 'Versículo copiado';

  @override
  String get verseSavedToast => 'Guardado en favoritos';

  @override
  String get verseUnsavedToast => 'Quitado de favoritos';

  @override
  String get verseCopyTooltip => 'Copiar versículo';

  @override
  String get verseUnfavoriteTooltip => 'Quitar de favoritos';

  @override
  String get verseFavoriteTooltip => 'Guardar en favoritos';

  @override
  String get verseMoreTooltip => 'Reflexión, capítulo y más como este';

  @override
  String get onboardingStep1Title => 'Un versículo a la vez';

  @override
  String get onboardingStep1Body =>
      'Un momento de calma cada vez que abres la app. Sin prisa, sin ruido, solo una palabra que acompaña.';

  @override
  String get onboardingStep2Title => 'Sin registro, sin conexión';

  @override
  String get onboardingStep2Body =>
      'No necesitas cuenta ni internet. Todo vive en tu teléfono y tus favoritos son solo tuyos.';

  @override
  String get onboardingStep3Title => 'A tu ritmo';

  @override
  String get onboardingStep3Body =>
      'Desliza hacia arriba para el siguiente versículo. Guarda con el corazón los que te hablen y vuelve a ellos cuando quieras.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String onboardingStepSemantics(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get exploreSubtitle => 'Palabras para lo que estás viviendo hoy.';

  @override
  String get exploreTopicsSection => 'Temas';

  @override
  String get exploreMomentsSection => 'Momentos de vida';

  @override
  String get exploreMomentsIntro =>
      'Para cuando necesitas algo más cercano a lo que pasa hoy.';

  @override
  String get dailyCardTitle => 'Versículo del día';

  @override
  String get dailyCardCta => 'Leer con su reflexión';

  @override
  String dailyCardSemantics(String date) {
    return 'Versículo del día. $date. Toca para leerlo';
  }

  @override
  String get topicNotFoundTitle => 'No encontramos este tema';

  @override
  String get topicNotFoundBody => 'Vuelve a Explorar y elige otro.';

  @override
  String topicSubtitle(String topic) {
    return 'Versículos sobre $topic.';
  }

  @override
  String get topicNoteDelicate =>
      'Tómate tu tiempo. Estas palabras te acompañan, sin prisa. Si lo que vives pesa mucho, hablar con alguien de confianza también ayuda.';

  @override
  String get topicNoteGeneral => 'Estas palabras son para ti, para hoy.';

  @override
  String get topicEmptyTitle => 'Pronto habrá más aquí';

  @override
  String get topicEmptyBody => 'Estamos preparando versículos para este tema.';

  @override
  String get streakFirstDay => 'Primer día';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get streakSemanticsFirst =>
      'Hoy empezaste tu racha. Toca para saber más';

  @override
  String streakSemantics(int count) {
    return 'Llevas $count días seguidos. Toca para saber más';
  }

  @override
  String get streakSheetTitleFirst => 'Hoy empezaste';

  @override
  String streakSheetTitle(int count) {
    return 'Llevas $count días con calma';
  }

  @override
  String get streakSheetBodyFirst =>
      'Cada día que abres Sosiego suma un día a tu racha.';

  @override
  String get streakSheetBody =>
      'Gracias por volver cada día a un momento de paz.';

  @override
  String get streakSheetNote =>
      'Si un día no abres la app, no pasa nada: tu racha te espera hasta mañana. Aquí no hay nada que perder.';

  @override
  String get streakSheetOk => 'Entendido';

  @override
  String get dailyFallbackTitle => 'Hoy';

  @override
  String get dailyPreparingTitle => 'Preparando el versículo de hoy';

  @override
  String get dailyPreparingBody => 'Un momento, por favor.';

  @override
  String dailyReflectionSemantics(String title, int minutes) {
    return 'Reflexión de hoy: $title. $minutes minutos';
  }

  @override
  String get dailyReflectionKicker => 'Para pensar hoy';

  @override
  String get dailyReadReflection => 'Leer la reflexión';

  @override
  String get dailyMoreSemantics => 'Más sobre este versículo';

  @override
  String get favoritesTitle => 'Guardados';

  @override
  String favoritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versículos para volver a leer.',
      one: '1 versículo para volver a leer.',
    );
    return '$_temp0';
  }

  @override
  String get favoritesEmptyTitle => 'Aquí vivirán tus versículos';

  @override
  String get favoritesEmptyBody =>
      'Toca el corazón en el que te hable y lo encontrarás aquí, incluso sin conexión.';

  @override
  String get favoritesEmptyAction => 'Ir a los versículos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSubtitle => 'Hazlo cómodo para tus ojos.';

  @override
  String get settingsFontSection => 'Tamaño de letra';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontNormalDesc => 'El tamaño de siempre';

  @override
  String get fontLarge => 'Grande';

  @override
  String get fontLargeDesc => 'Más cómodo de leer';

  @override
  String get fontXLarge => 'Muy grande';

  @override
  String get fontXLargeDesc => 'Letra amplia y clara';

  @override
  String get fontSample => 'Aa';

  @override
  String get settingsFontNote =>
      'Si tu teléfono ya usa letra grande, Sosiego la respeta (hasta el doble).';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeSystem => 'Como el teléfono';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get aboutNoAccountTitle => 'Sin cuentas ni registro';

  @override
  String get aboutNoAccountBody =>
      'Sosiego funciona sin conexión. Tus favoritos y ajustes se quedan en este teléfono.';

  @override
  String get aboutAppVersion => 'Versión de la app';

  @override
  String get aboutBible => 'Biblia';

  @override
  String get aboutContentVersion => 'Versión del contenido';

  @override
  String get verseTitle => 'Versículo';

  @override
  String get verseNotFoundTitle => 'No encontramos este versículo';

  @override
  String get verseNotFoundBody => 'Puede que ya no esté disponible.';

  @override
  String reflectionCardSemantics(String title, int minutes) {
    return 'Reflexión: $title. $minutes minutos de lectura';
  }

  @override
  String reflectionCardSubtitle(int minutes) {
    return 'Reflexión · $minutes min de lectura';
  }

  @override
  String readChapterSemantics(String book, int chapter) {
    return 'Leer el capítulo completo, $book $chapter';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchSubtitle => 'Escribe una cita o una palabra.';

  @override
  String get searchHint => 'Salmo 23, Juan 3:16 o «paz»';

  @override
  String get searchClearTooltip => 'Borrar búsqueda';

  @override
  String get searchWithCitation => 'Con una cita';

  @override
  String get searchWithWord => 'O con una palabra';

  @override
  String get searchSuggestionRefs => 'Juan 3:16|Salmo 23|1 Cor 13:4';

  @override
  String get searchSuggestionWords => 'paz|amor|refugio|esperanza|confía';

  @override
  String get searchTip =>
      'No importan las tildes ni las mayúsculas. Si escribes solo el principio de una palabra, también la encontramos.';

  @override
  String searchNoResultsTitle(String query) {
    return 'No encontramos «$query»';
  }

  @override
  String get searchNoResultsBody =>
      'Prueba con una sola palabra, o con una cita como «Salmo 23». Las tildes no importan.';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String searchReadChapterSemantics(String book, int chapter) {
    return 'Leer $book $chapter completo';
  }

  @override
  String get searchReadChapterFull => 'Leer el capítulo completo';

  @override
  String get chapterFallbackTitle => 'Capítulo';

  @override
  String get chapterNotFoundTitle => 'No encontramos este capítulo';

  @override
  String get chapterNotFoundBody => 'Vuelve atrás y prueba con otro versículo.';

  @override
  String chapterVerseSemantics(int number, String highlighted, String text) {
    String _temp0 = intl.Intl.selectLogic(highlighted, {
      'true': ', el que buscabas',
      'other': '',
    });
    return 'Versículo $number$_temp0. $text';
  }

  @override
  String get reflectionKindDaily => 'Reflexión del día';

  @override
  String get reflectionKindEmotion => 'Para lo que sientes';

  @override
  String get reflectionKindMoment => 'Para este momento';

  @override
  String get reflectionFallbackTitle => 'Reflexión';

  @override
  String get reflectionMissingTitle => 'Aún no hay reflexión';

  @override
  String get reflectionMissingBody =>
      'Este versículo todavía no tiene una reflexión. Puedes leerlo con calma o ver su capítulo.';

  @override
  String get reflectionGateTitle => 'Antes de leer';

  @override
  String get reflectionGateBody =>
      'Este texto habla de un momento delicado. Léelo cuando te sientas con calma; puedes volver a él cuando quieras.';

  @override
  String get reflectionGateRead => 'Leer ahora';

  @override
  String get reflectionGateNotNow => 'Ahora no';

  @override
  String get reflectionPrayerTitle => 'Oración';
}
