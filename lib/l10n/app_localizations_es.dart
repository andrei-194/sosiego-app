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
  String get streakSemanticsMore => 'Toca para saber más';

  @override
  String get navVerses => 'Versículos';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionSaved => 'Guardado';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionPrevious => 'Anterior';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get switchOn => 'Activado';

  @override
  String get switchOff => 'Desactivado';

  @override
  String get feedHint => 'Desliza o toca Siguiente';

  @override
  String feedModeTheme(String name) {
    return 'Tema: $name · Salir';
  }

  @override
  String feedModeSimilar(String reference) {
    return 'Parecidos a $reference · Salir';
  }

  @override
  String get feedEndTitle => 'Llegaste al final de esta lista';

  @override
  String get feedEndBody =>
      'Puedes volver al feed o seguir con versículos parecidos al último.';

  @override
  String get feedEndBack => 'Volver al feed';

  @override
  String get feedEndMoreSimilar => 'Ver más parecidos';

  @override
  String get homeTodayTitle => 'Versículo de hoy';

  @override
  String get homeRead => 'Leer';

  @override
  String get homeFeelingTitle => '¿Cómo te sientes hoy?';

  @override
  String get homeMomentsTitle => 'Momentos';

  @override
  String get homeEmptyTitle => 'Preparando tus versículos';

  @override
  String get homeEmptyBody => 'Un momento, por favor.';

  @override
  String streakCounting(int count) {
    return 'Llevas $count días contigo';
  }

  @override
  String get streakRestart => 'Hoy es un buen día para empezar';

  @override
  String streakMilestoneTitle(int count) {
    return '$count días con la Palabra';
  }

  @override
  String get streakMilestoneBody =>
      'Gracias por volver. Si quieres, comparte este momento con alguien.';

  @override
  String get streakMilestoneShare => 'Compartir';

  @override
  String streakMilestoneHeadline(int count) {
    return '$count días con la Palabra';
  }

  @override
  String get welcomeTitle => '¿Cómo prefieres leer?';

  @override
  String get welcomeBody =>
      'Toca una opción y mira cómo se ve. Podrás cambiarla después en Ajustes.';

  @override
  String get welcomeSelected => 'Elegido';

  @override
  String searchTopicButton(String topic) {
    return 'Ver versículos sobre $topic';
  }

  @override
  String get searchFeelingsTitle => 'Elige cómo te sientes';

  @override
  String get searchEmptyHint => 'Escribe en el campo o toca un sentimiento.';

  @override
  String get searchOpenVerse => 'Abrir versículo';

  @override
  String get helpBlockText =>
      'Si sientes que no puedes más o piensas en hacerte daño, habla hoy con alguien';

  @override
  String get helpCallButton => 'Llamar a una línea de ayuda';

  @override
  String get favoritesTabSaved => 'Guardados';

  @override
  String get favoritesTabSeen => 'Vistos';

  @override
  String get favoritesPhoneNote => 'Tus guardados viven solo en este teléfono';

  @override
  String get favoritesSend => 'Enviarme mis guardados';

  @override
  String get favoritesRemovedToast => 'Quitado de guardados';

  @override
  String get favoritesExportHeader => 'Mis guardados de Sosiego';

  @override
  String get favoritesExportFooter => 'Enviado desde Sosiego';

  @override
  String get seenEmptyTitle => 'Aún no hay versículos vistos';

  @override
  String get seenEmptyBody =>
      'Los versículos que leas unos segundos aparecerán aquí.';

  @override
  String get settingsFontPreview => 'Así se verá tu lectura';

  @override
  String get settingsFontPreviewVerse =>
      'El Señor es mi pastor; nada me faltará.';

  @override
  String get settingsFontPreviewRef => 'Salmos 23:1';

  @override
  String get settingsSendSaved => 'Enviarme mis guardados';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsPrivacyPolicy => 'Leer la política de privacidad';

  @override
  String get settingsAnalytics => 'Ayudar a mejorar la app (anónimo)';

  @override
  String get settingsAnalyticsNote =>
      'Solo contaríamos cuántas veces se usa cada función. Nunca guardamos lo que lees ni lo que escribes.';

  @override
  String get settingsLinkError =>
      'No pudimos abrir el enlace en este teléfono.';

  @override
  String get settingsLicenses => 'Licencias y fuentes';

  @override
  String get settingsFeedback => 'Enviar comentarios';

  @override
  String get settingsFeedbackSubject => 'Comentarios sobre Sosiego';

  @override
  String get aboutSource => 'Fuente del texto';

  @override
  String get aboutPublicDomain => 'Reina-Valera 1909, dominio público';

  @override
  String get aboutAiNote =>
      'Las reflexiones y oraciones se redactan con ayuda de inteligencia artificial y las revisa una persona. No sustituyen la guía pastoral ni la atención médica o psicológica.';

  @override
  String get companionTitle => 'Acompañamiento';

  @override
  String get companionContext => 'Contexto';

  @override
  String get companionReflection => 'Reflexión';

  @override
  String get companionApplication => 'Aplicación';

  @override
  String get companionPrayer => 'Oración';

  @override
  String get companionAiLine =>
      'Redactada con ayuda de inteligencia artificial y revisada por una persona';

  @override
  String get companionAnother => 'Otra palabra';

  @override
  String get companionMoreOfTheme => 'Más versículos de este tema';

  @override
  String get companionMissingTitle => 'Aún no hay una palabra para esto';

  @override
  String get companionMissingBody => 'Puedes ver versículos de este tema.';

  @override
  String readingMinutes(int minutes) {
    return '$minutes min';
  }

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
  String get favoritesEmptyAction => 'Ir a versículos';

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
  String get themeSystem => 'Automático';

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
  String get searchHint => 'Busca una palabra, un tema o Juan 3:16';

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
  String get searchNoResultsTitle =>
      'No encontramos eso. Prueba con una palabra más corta o elige un tema';

  @override
  String get searchNoResultsBody => 'Las tildes y las mayúsculas no importan.';

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

  @override
  String get shareSheetTitle => 'Compartir este versículo';

  @override
  String get shareClose => 'Cerrar';

  @override
  String sharePreviewSemantics(String style, String reference) {
    return 'Vista previa de la tarjeta, estilo $style. $reference';
  }

  @override
  String get shareStylesLabel => 'Elige un estilo';

  @override
  String get shareToLabel => 'Para:';

  @override
  String get shareToHint => 'Por ejemplo, mamá';

  @override
  String get shareToHelper => 'Es opcional y se queda en tu teléfono.';

  @override
  String get shareImageButton => 'Compartir imagen';

  @override
  String get shareImagePreparing => 'Preparando la imagen…';

  @override
  String get shareWhatsappButton => 'Enviar texto por WhatsApp';

  @override
  String get shareImageError =>
      'No pudimos preparar la imagen. Inténtalo de nuevo.';

  @override
  String get shareWhatsappError =>
      'No pudimos abrir WhatsApp. Puedes instalarlo, o usar «Compartir imagen» y elegir otra aplicación.';

  @override
  String get listenAction => 'Escuchar';

  @override
  String get listenPause => 'Pausar';

  @override
  String get listenResume => 'Continuar';

  @override
  String get listenStop => 'Detener';

  @override
  String get listenNoVoice =>
      'Tu teléfono no tiene voz en español. Puedes instalarla en Ajustes del teléfono, en Idioma y Salida de texto a voz';

  @override
  String get listenFailed =>
      'No pudimos leer el texto en voz alta. Inténtalo de nuevo.';

  @override
  String get voiceTitle => 'Velocidad de voz';

  @override
  String get voiceSlow => 'Lenta';

  @override
  String get voiceNormal => 'Normal';

  @override
  String get voiceFast => 'Rápida';

  @override
  String get voiceTest => 'Probar la voz';

  @override
  String get voiceSampleText => 'Jehová es mi pastor; nada me faltará.';

  @override
  String get voiceNote => 'Usamos la voz en español de tu teléfono.';

  @override
  String get reminderCardTitle => '¿Quieres recibir el versículo cada día?';

  @override
  String get reminderCardBody =>
      'Elige una hora y te avisaremos con un versículo, sin molestar.';

  @override
  String reminderClock(int hour, String minute, String period) {
    return '$hour:$minute $period';
  }

  @override
  String get reminderAm => 'a. m.';

  @override
  String get reminderPm => 'p. m.';

  @override
  String reminderTimeMorning(String time) {
    return 'Mañana, $time';
  }

  @override
  String reminderTimeAfternoon(String time) {
    return 'Tarde, $time';
  }

  @override
  String reminderTimeNight(String time) {
    return 'Noche, $time';
  }

  @override
  String get reminderNotNow => 'Ahora no';

  @override
  String reminderDoneTitle(String time) {
    return 'Listo, te avisaremos a las $time';
  }

  @override
  String get reminderDoneBody =>
      'Puedes cambiar la hora o desactivarlo en Ajustes.';

  @override
  String get reminderDeniedTitle => 'Está bien, sin problema';

  @override
  String get reminderDeniedBody =>
      'No activamos los avisos. Cuando quieras, puedes hacerlo desde Ajustes.';

  @override
  String get reminderGotIt => 'Entendido';

  @override
  String get reminderNotificationTitle => 'Tu versículo de hoy';

  @override
  String get reminderSettingsTitle => 'Versículo diario';

  @override
  String get reminderSwitchLabel => 'Recibir el versículo cada día';

  @override
  String get reminderOn => 'Activado';

  @override
  String get reminderOff => 'Desactivado';

  @override
  String get reminderTimeSection => '¿A qué hora?';

  @override
  String get reminderOtherTime => 'Otra hora';

  @override
  String reminderOtherTimeChosen(String time) {
    return 'Otra hora: $time';
  }

  @override
  String get reminderPickerHelp => 'Elige la hora del aviso';

  @override
  String get reminderPermissionDenied =>
      'El teléfono no nos dejó enviar avisos. Puedes permitirlos en Ajustes del teléfono, en Aplicaciones, Sosiego, Notificaciones.';

  @override
  String get reminderSystemOff =>
      'Las notificaciones están apagadas en tu teléfono, así que el aviso no llegará. Puedes encenderlas en Ajustes del teléfono, en Aplicaciones, Sosiego, Notificaciones.';

  @override
  String get reminderHelpTitle => 'Ayuda con las notificaciones';

  @override
  String get reminderHelpSubtitle => 'Si el aviso no llega a su hora';

  @override
  String get reminderHelpIntro =>
      'Algunos teléfonos ahorran batería cerrando las aplicaciones. Para que el aviso llegue:';

  @override
  String get reminderHelpStep1 =>
      'Abre Ajustes del teléfono y entra en Aplicaciones.';

  @override
  String get reminderHelpStep2 => 'Busca Sosiego y toca Batería.';

  @override
  String get reminderHelpStep3 =>
      'Elige Sin restricciones. En algunos teléfonos dice No optimizar o Permitir actividad en segundo plano.';

  @override
  String get reminderHelpBrandsTitle => 'Según la marca de tu teléfono';

  @override
  String get reminderHelpSamsung =>
      'Samsung: Ajustes, Cuidado del dispositivo, Batería, Límites de uso en segundo plano. Quita Sosiego de Apps en suspensión.';

  @override
  String get reminderHelpXiaomi =>
      'Xiaomi, Redmi y Poco: Ajustes, Aplicaciones, Permisos, Inicio automático. Activa Sosiego. Luego, en Ahorro de batería, elige Sin restricciones.';

  @override
  String get reminderHelpOthers =>
      'Motorola, Huawei, Honor, Oppo y Realme: en Batería, busca Inicio automático o Actividad en segundo plano y permítelo para Sosiego.';

  @override
  String get reminderHelpLimit =>
      'Si no abres la aplicación en 30 días, los avisos terminan. Al abrirla, vuelven solos.';

  @override
  String get reminderHelpClose => 'Cerrar';
}
