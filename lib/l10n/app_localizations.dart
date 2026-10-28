import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Sosiego'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get navExplore;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardados'**
  String get navSaved;

  /// No description provided for @actionBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get actionBack;

  /// No description provided for @actionSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get actionSettings;

  /// No description provided for @actionUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get actionUndo;

  /// No description provided for @translationName.
  ///
  /// In es, this message translates to:
  /// **'Reina-Valera 1909'**
  String get translationName;

  /// No description provided for @verseSemantics.
  ///
  /// In es, this message translates to:
  /// **'{text}. {reference}'**
  String verseSemantics(String text, String reference);

  /// No description provided for @bookChapter.
  ///
  /// In es, this message translates to:
  /// **'{book} {chapter}'**
  String bookChapter(String book, int chapter);

  /// No description provided for @moreLikeThis.
  ///
  /// In es, this message translates to:
  /// **'Más como este'**
  String get moreLikeThis;

  /// No description provided for @readChapter.
  ///
  /// In es, this message translates to:
  /// **'Leer el capítulo'**
  String get readChapter;

  /// No description provided for @readingTime.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de lectura'**
  String readingTime(int minutes);

  /// No description provided for @longDate.
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String longDate(DateTime date);

  /// No description provided for @feedSwipeHintSemantics.
  ///
  /// In es, this message translates to:
  /// **'Desliza hacia arriba para ver el siguiente versículo'**
  String get feedSwipeHintSemantics;

  /// No description provided for @feedSwipeHint.
  ///
  /// In es, this message translates to:
  /// **'Desliza para el siguiente'**
  String get feedSwipeHint;

  /// No description provided for @feedLoadingSemantics.
  ///
  /// In es, this message translates to:
  /// **'Preparando un versículo'**
  String get feedLoadingSemantics;

  /// No description provided for @feedLoading.
  ///
  /// In es, this message translates to:
  /// **'Preparando un versículo…'**
  String get feedLoading;

  /// No description provided for @feedErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir los versículos'**
  String get feedErrorTitle;

  /// No description provided for @feedErrorBody.
  ///
  /// In es, this message translates to:
  /// **'No es culpa tuya. Intenta de nuevo; si sigue igual, cierra y vuelve a abrir la app.'**
  String get feedErrorBody;

  /// No description provided for @feedRetry.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get feedRetry;

  /// No description provided for @verseCopyText.
  ///
  /// In es, this message translates to:
  /// **'“{text}”\n— {reference} (Reina-Valera 1909)'**
  String verseCopyText(String text, String reference);

  /// No description provided for @verseCopied.
  ///
  /// In es, this message translates to:
  /// **'Versículo copiado'**
  String get verseCopied;

  /// No description provided for @verseSavedToast.
  ///
  /// In es, this message translates to:
  /// **'Guardado en favoritos'**
  String get verseSavedToast;

  /// No description provided for @verseUnsavedToast.
  ///
  /// In es, this message translates to:
  /// **'Quitado de favoritos'**
  String get verseUnsavedToast;

  /// No description provided for @verseCopyTooltip.
  ///
  /// In es, this message translates to:
  /// **'Copiar versículo'**
  String get verseCopyTooltip;

  /// No description provided for @verseUnfavoriteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get verseUnfavoriteTooltip;

  /// No description provided for @verseFavoriteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Guardar en favoritos'**
  String get verseFavoriteTooltip;

  /// No description provided for @verseMoreTooltip.
  ///
  /// In es, this message translates to:
  /// **'Reflexión, capítulo y más como este'**
  String get verseMoreTooltip;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Un versículo a la vez'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Body.
  ///
  /// In es, this message translates to:
  /// **'Un momento de calma cada vez que abres la app. Sin prisa, sin ruido, solo una palabra que acompaña.'**
  String get onboardingStep1Body;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Sin registro, sin conexión'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Body.
  ///
  /// In es, this message translates to:
  /// **'No necesitas cuenta ni internet. Todo vive en tu teléfono y tus favoritos son solo tuyos.'**
  String get onboardingStep2Body;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In es, this message translates to:
  /// **'A tu ritmo'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Body.
  ///
  /// In es, this message translates to:
  /// **'Desliza hacia arriba para el siguiente versículo. Guarda con el corazón los que te hablen y vuelve a ellos cuando quieras.'**
  String get onboardingStep3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onboardingStart;

  /// No description provided for @onboardingStepSemantics.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingStepSemantics(int current, int total);

  /// No description provided for @exploreTitle.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Palabras para lo que estás viviendo hoy.'**
  String get exploreSubtitle;

  /// No description provided for @exploreTopicsSection.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get exploreTopicsSection;

  /// No description provided for @exploreMomentsSection.
  ///
  /// In es, this message translates to:
  /// **'Momentos de vida'**
  String get exploreMomentsSection;

  /// No description provided for @exploreMomentsIntro.
  ///
  /// In es, this message translates to:
  /// **'Para cuando necesitas algo más cercano a lo que pasa hoy.'**
  String get exploreMomentsIntro;

  /// No description provided for @dailyCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Versículo del día'**
  String get dailyCardTitle;

  /// No description provided for @dailyCardCta.
  ///
  /// In es, this message translates to:
  /// **'Leer con su reflexión'**
  String get dailyCardCta;

  /// No description provided for @dailyCardSemantics.
  ///
  /// In es, this message translates to:
  /// **'Versículo del día. {date}. Toca para leerlo'**
  String dailyCardSemantics(String date);

  /// No description provided for @topicNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este tema'**
  String get topicNotFoundTitle;

  /// No description provided for @topicNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a Explorar y elige otro.'**
  String get topicNotFoundBody;

  /// No description provided for @topicSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Versículos sobre {topic}.'**
  String topicSubtitle(String topic);

  /// No description provided for @topicNoteDelicate.
  ///
  /// In es, this message translates to:
  /// **'Tómate tu tiempo. Estas palabras te acompañan, sin prisa. Si lo que vives pesa mucho, hablar con alguien de confianza también ayuda.'**
  String get topicNoteDelicate;

  /// No description provided for @topicNoteGeneral.
  ///
  /// In es, this message translates to:
  /// **'Estas palabras son para ti, para hoy.'**
  String get topicNoteGeneral;

  /// No description provided for @topicEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Pronto habrá más aquí'**
  String get topicEmptyTitle;

  /// No description provided for @topicEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando versículos para este tema.'**
  String get topicEmptyBody;

  /// No description provided for @streakFirstDay.
  ///
  /// In es, this message translates to:
  /// **'Primer día'**
  String get streakFirstDay;

  /// No description provided for @streakDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String streakDays(int count);

  /// No description provided for @streakSemanticsFirst.
  ///
  /// In es, this message translates to:
  /// **'Hoy empezaste tu racha. Toca para saber más'**
  String get streakSemanticsFirst;

  /// No description provided for @streakSemantics.
  ///
  /// In es, this message translates to:
  /// **'Llevas {count} días seguidos. Toca para saber más'**
  String streakSemantics(int count);

  /// No description provided for @streakSheetTitleFirst.
  ///
  /// In es, this message translates to:
  /// **'Hoy empezaste'**
  String get streakSheetTitleFirst;

  /// No description provided for @streakSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Llevas {count} días con calma'**
  String streakSheetTitle(int count);

  /// No description provided for @streakSheetBodyFirst.
  ///
  /// In es, this message translates to:
  /// **'Cada día que abres Sosiego suma un día a tu racha.'**
  String get streakSheetBodyFirst;

  /// No description provided for @streakSheetBody.
  ///
  /// In es, this message translates to:
  /// **'Gracias por volver cada día a un momento de paz.'**
  String get streakSheetBody;

  /// No description provided for @streakSheetNote.
  ///
  /// In es, this message translates to:
  /// **'Si un día no abres la app, no pasa nada: tu racha te espera hasta mañana. Aquí no hay nada que perder.'**
  String get streakSheetNote;

  /// No description provided for @streakSheetOk.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get streakSheetOk;

  /// No description provided for @dailyFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get dailyFallbackTitle;

  /// No description provided for @dailyPreparingTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando el versículo de hoy'**
  String get dailyPreparingTitle;

  /// No description provided for @dailyPreparingBody.
  ///
  /// In es, this message translates to:
  /// **'Un momento, por favor.'**
  String get dailyPreparingBody;

  /// No description provided for @dailyReflectionSemantics.
  ///
  /// In es, this message translates to:
  /// **'Reflexión de hoy: {title}. {minutes} minutos'**
  String dailyReflectionSemantics(String title, int minutes);

  /// No description provided for @dailyReflectionKicker.
  ///
  /// In es, this message translates to:
  /// **'Para pensar hoy'**
  String get dailyReflectionKicker;

  /// No description provided for @dailyReadReflection.
  ///
  /// In es, this message translates to:
  /// **'Leer la reflexión'**
  String get dailyReadReflection;

  /// No description provided for @dailyMoreSemantics.
  ///
  /// In es, this message translates to:
  /// **'Más sobre este versículo'**
  String get dailyMoreSemantics;

  /// No description provided for @favoritesTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardados'**
  String get favoritesTitle;

  /// No description provided for @favoritesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 versículo para volver a leer.} other{{count} versículos para volver a leer.}}'**
  String favoritesCount(int count);

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí vivirán tus versículos'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Toca el corazón en el que te hable y lo encontrarás aquí, incluso sin conexión.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoritesEmptyAction.
  ///
  /// In es, this message translates to:
  /// **'Ir a los versículos'**
  String get favoritesEmptyAction;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Hazlo cómodo para tus ojos.'**
  String get settingsSubtitle;

  /// No description provided for @settingsFontSection.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de letra'**
  String get settingsFontSection;

  /// No description provided for @fontNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get fontNormal;

  /// No description provided for @fontNormalDesc.
  ///
  /// In es, this message translates to:
  /// **'El tamaño de siempre'**
  String get fontNormalDesc;

  /// No description provided for @fontLarge.
  ///
  /// In es, this message translates to:
  /// **'Grande'**
  String get fontLarge;

  /// No description provided for @fontLargeDesc.
  ///
  /// In es, this message translates to:
  /// **'Más cómodo de leer'**
  String get fontLargeDesc;

  /// No description provided for @fontXLarge.
  ///
  /// In es, this message translates to:
  /// **'Muy grande'**
  String get fontXLarge;

  /// No description provided for @fontXLargeDesc.
  ///
  /// In es, this message translates to:
  /// **'Letra amplia y clara'**
  String get fontXLargeDesc;

  /// No description provided for @fontSample.
  ///
  /// In es, this message translates to:
  /// **'Aa'**
  String get fontSample;

  /// No description provided for @settingsFontNote.
  ///
  /// In es, this message translates to:
  /// **'Si tu teléfono ya usa letra grande, Sosiego la respeta (hasta el doble).'**
  String get settingsFontNote;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Como el teléfono'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAbout;

  /// No description provided for @aboutNoAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin cuentas ni registro'**
  String get aboutNoAccountTitle;

  /// No description provided for @aboutNoAccountBody.
  ///
  /// In es, this message translates to:
  /// **'Sosiego funciona sin conexión. Tus favoritos y ajustes se quedan en este teléfono.'**
  String get aboutNoAccountBody;

  /// No description provided for @aboutAppVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get aboutAppVersion;

  /// No description provided for @aboutBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get aboutBible;

  /// No description provided for @aboutContentVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión del contenido'**
  String get aboutContentVersion;

  /// No description provided for @verseTitle.
  ///
  /// In es, this message translates to:
  /// **'Versículo'**
  String get verseTitle;

  /// No description provided for @verseNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este versículo'**
  String get verseNotFoundTitle;

  /// No description provided for @verseNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'Puede que ya no esté disponible.'**
  String get verseNotFoundBody;

  /// No description provided for @reflectionCardSemantics.
  ///
  /// In es, this message translates to:
  /// **'Reflexión: {title}. {minutes} minutos de lectura'**
  String reflectionCardSemantics(String title, int minutes);

  /// No description provided for @reflectionCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reflexión · {minutes} min de lectura'**
  String reflectionCardSubtitle(int minutes);

  /// No description provided for @readChapterSemantics.
  ///
  /// In es, this message translates to:
  /// **'Leer el capítulo completo, {book} {chapter}'**
  String readChapterSemantics(String book, int chapter);

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe una cita o una palabra.'**
  String get searchSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Salmo 23, Juan 3:16 o «paz»'**
  String get searchHint;

  /// No description provided for @searchClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get searchClearTooltip;

  /// No description provided for @searchWithCitation.
  ///
  /// In es, this message translates to:
  /// **'Con una cita'**
  String get searchWithCitation;

  /// No description provided for @searchWithWord.
  ///
  /// In es, this message translates to:
  /// **'O con una palabra'**
  String get searchWithWord;

  /// No description provided for @searchSuggestionRefs.
  ///
  /// In es, this message translates to:
  /// **'Juan 3:16|Salmo 23|1 Cor 13:4'**
  String get searchSuggestionRefs;

  /// No description provided for @searchSuggestionWords.
  ///
  /// In es, this message translates to:
  /// **'paz|amor|refugio|esperanza|confía'**
  String get searchSuggestionWords;

  /// No description provided for @searchTip.
  ///
  /// In es, this message translates to:
  /// **'No importan las tildes ni las mayúsculas. Si escribes solo el principio de una palabra, también la encontramos.'**
  String get searchTip;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos «{query}»'**
  String searchNoResultsTitle(String query);

  /// No description provided for @searchNoResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con una sola palabra, o con una cita como «Salmo 23». Las tildes no importan.'**
  String get searchNoResultsBody;

  /// No description provided for @searchResultCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 resultado} other{{count} resultados}}'**
  String searchResultCount(int count);

  /// No description provided for @searchReadChapterSemantics.
  ///
  /// In es, this message translates to:
  /// **'Leer {book} {chapter} completo'**
  String searchReadChapterSemantics(String book, int chapter);

  /// No description provided for @searchReadChapterFull.
  ///
  /// In es, this message translates to:
  /// **'Leer el capítulo completo'**
  String get searchReadChapterFull;

  /// No description provided for @chapterFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Capítulo'**
  String get chapterFallbackTitle;

  /// No description provided for @chapterNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este capítulo'**
  String get chapterNotFoundTitle;

  /// No description provided for @chapterNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'Vuelve atrás y prueba con otro versículo.'**
  String get chapterNotFoundBody;

  /// No description provided for @chapterVerseSemantics.
  ///
  /// In es, this message translates to:
  /// **'Versículo {number}{highlighted, select, true{, el que buscabas} other{}}. {text}'**
  String chapterVerseSemantics(int number, String highlighted, String text);

  /// No description provided for @reflectionKindDaily.
  ///
  /// In es, this message translates to:
  /// **'Reflexión del día'**
  String get reflectionKindDaily;

  /// No description provided for @reflectionKindEmotion.
  ///
  /// In es, this message translates to:
  /// **'Para lo que sientes'**
  String get reflectionKindEmotion;

  /// No description provided for @reflectionKindMoment.
  ///
  /// In es, this message translates to:
  /// **'Para este momento'**
  String get reflectionKindMoment;

  /// No description provided for @reflectionFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Reflexión'**
  String get reflectionFallbackTitle;

  /// No description provided for @reflectionMissingTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay reflexión'**
  String get reflectionMissingTitle;

  /// No description provided for @reflectionMissingBody.
  ///
  /// In es, this message translates to:
  /// **'Este versículo todavía no tiene una reflexión. Puedes leerlo con calma o ver su capítulo.'**
  String get reflectionMissingBody;

  /// No description provided for @reflectionGateTitle.
  ///
  /// In es, this message translates to:
  /// **'Antes de leer'**
  String get reflectionGateTitle;

  /// No description provided for @reflectionGateBody.
  ///
  /// In es, this message translates to:
  /// **'Este texto habla de un momento delicado. Léelo cuando te sientas con calma; puedes volver a él cuando quieras.'**
  String get reflectionGateBody;

  /// No description provided for @reflectionGateRead.
  ///
  /// In es, this message translates to:
  /// **'Leer ahora'**
  String get reflectionGateRead;

  /// No description provided for @reflectionGateNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get reflectionGateNotNow;

  /// No description provided for @reflectionPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Oración'**
  String get reflectionPrayerTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
