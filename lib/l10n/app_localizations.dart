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

  /// No description provided for @streakSemanticsMore.
  ///
  /// In es, this message translates to:
  /// **'Toca para saber más'**
  String get streakSemanticsMore;

  /// No description provided for @navVerses.
  ///
  /// In es, this message translates to:
  /// **'Versículos'**
  String get navVerses;

  /// No description provided for @actionShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get actionShare;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get actionSaved;

  /// No description provided for @actionRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get actionRemove;

  /// No description provided for @actionPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get actionPrevious;

  /// No description provided for @actionNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get actionNext;

  /// No description provided for @actionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @switchOn.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get switchOn;

  /// No description provided for @switchOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get switchOff;

  /// No description provided for @feedHint.
  ///
  /// In es, this message translates to:
  /// **'Desliza o toca Siguiente'**
  String get feedHint;

  /// No description provided for @feedModeTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema: {name} · Salir'**
  String feedModeTheme(String name);

  /// No description provided for @feedModeSimilar.
  ///
  /// In es, this message translates to:
  /// **'Parecidos a {reference} · Salir'**
  String feedModeSimilar(String reference);

  /// No description provided for @feedEndTitle.
  ///
  /// In es, this message translates to:
  /// **'Llegaste al final de esta lista'**
  String get feedEndTitle;

  /// No description provided for @feedEndBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes volver al feed o seguir con versículos parecidos al último.'**
  String get feedEndBody;

  /// No description provided for @feedEndBack.
  ///
  /// In es, this message translates to:
  /// **'Volver al feed'**
  String get feedEndBack;

  /// No description provided for @feedEndMoreSimilar.
  ///
  /// In es, this message translates to:
  /// **'Ver más parecidos'**
  String get feedEndMoreSimilar;

  /// No description provided for @homeTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Versículo de hoy'**
  String get homeTodayTitle;

  /// No description provided for @homeRead.
  ///
  /// In es, this message translates to:
  /// **'Leer'**
  String get homeRead;

  /// No description provided for @homeFeelingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sientes hoy?'**
  String get homeFeelingTitle;

  /// No description provided for @homeMomentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Momentos'**
  String get homeMomentsTitle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando tus versículos'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Un momento, por favor.'**
  String get homeEmptyBody;

  /// No description provided for @streakCounting.
  ///
  /// In es, this message translates to:
  /// **'Llevas {count} días contigo'**
  String streakCounting(int count);

  /// No description provided for @streakRestart.
  ///
  /// In es, this message translates to:
  /// **'Hoy es un buen día para empezar'**
  String get streakRestart;

  /// No description provided for @streakMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'{count} días con la Palabra'**
  String streakMilestoneTitle(int count);

  /// No description provided for @streakMilestoneBody.
  ///
  /// In es, this message translates to:
  /// **'Gracias por volver. Si quieres, comparte este momento con alguien.'**
  String get streakMilestoneBody;

  /// No description provided for @streakMilestoneShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get streakMilestoneShare;

  /// No description provided for @streakMilestoneHeadline.
  ///
  /// In es, this message translates to:
  /// **'{count} días con la Palabra'**
  String streakMilestoneHeadline(int count);

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo prefieres leer?'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Toca una opción y mira cómo se ve. Podrás cambiarla después en Ajustes.'**
  String get welcomeBody;

  /// No description provided for @welcomeSelected.
  ///
  /// In es, this message translates to:
  /// **'Elegido'**
  String get welcomeSelected;

  /// No description provided for @searchTopicButton.
  ///
  /// In es, this message translates to:
  /// **'Ver versículos sobre {topic}'**
  String searchTopicButton(String topic);

  /// No description provided for @searchFeelingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo te sientes'**
  String get searchFeelingsTitle;

  /// No description provided for @searchEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe en el campo o toca un sentimiento.'**
  String get searchEmptyHint;

  /// No description provided for @searchOpenVerse.
  ///
  /// In es, this message translates to:
  /// **'Abrir versículo'**
  String get searchOpenVerse;

  /// No description provided for @helpBlockText.
  ///
  /// In es, this message translates to:
  /// **'Si sientes que no puedes más o piensas en hacerte daño, habla hoy con alguien'**
  String get helpBlockText;

  /// No description provided for @helpCallButton.
  ///
  /// In es, this message translates to:
  /// **'Llamar a una línea de ayuda'**
  String get helpCallButton;

  /// No description provided for @favoritesTabSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardados'**
  String get favoritesTabSaved;

  /// No description provided for @favoritesTabSeen.
  ///
  /// In es, this message translates to:
  /// **'Vistos'**
  String get favoritesTabSeen;

  /// No description provided for @favoritesPhoneNote.
  ///
  /// In es, this message translates to:
  /// **'Tus guardados viven solo en este teléfono'**
  String get favoritesPhoneNote;

  /// No description provided for @favoritesSend.
  ///
  /// In es, this message translates to:
  /// **'Enviarme mis guardados'**
  String get favoritesSend;

  /// No description provided for @favoritesRemovedToast.
  ///
  /// In es, this message translates to:
  /// **'Quitado de guardados'**
  String get favoritesRemovedToast;

  /// No description provided for @favoritesExportHeader.
  ///
  /// In es, this message translates to:
  /// **'Mis guardados de Sosiego'**
  String get favoritesExportHeader;

  /// No description provided for @favoritesExportFooter.
  ///
  /// In es, this message translates to:
  /// **'Enviado desde Sosiego'**
  String get favoritesExportFooter;

  /// No description provided for @seenEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay versículos vistos'**
  String get seenEmptyTitle;

  /// No description provided for @seenEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Los versículos que leas unos segundos aparecerán aquí.'**
  String get seenEmptyBody;

  /// No description provided for @settingsFontPreview.
  ///
  /// In es, this message translates to:
  /// **'Así se verá tu lectura'**
  String get settingsFontPreview;

  /// No description provided for @settingsFontPreviewVerse.
  ///
  /// In es, this message translates to:
  /// **'El Señor es mi pastor; nada me faltará.'**
  String get settingsFontPreviewVerse;

  /// No description provided for @settingsFontPreviewRef.
  ///
  /// In es, this message translates to:
  /// **'Salmos 23:1'**
  String get settingsFontPreviewRef;

  /// No description provided for @settingsSendSaved.
  ///
  /// In es, this message translates to:
  /// **'Enviarme mis guardados'**
  String get settingsSendSaved;

  /// No description provided for @settingsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Leer la política de privacidad'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Ayudar a mejorar la app (anónimo)'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnalyticsNote.
  ///
  /// In es, this message translates to:
  /// **'Solo contaríamos cuántas veces se usa cada función. Nunca guardamos lo que lees ni lo que escribes.'**
  String get settingsAnalyticsNote;

  /// No description provided for @settingsLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el enlace en este teléfono.'**
  String get settingsLinkError;

  /// No description provided for @settingsLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias y fuentes'**
  String get settingsLicenses;

  /// No description provided for @settingsFeedback.
  ///
  /// In es, this message translates to:
  /// **'Enviar comentarios'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackSubject.
  ///
  /// In es, this message translates to:
  /// **'Comentarios sobre Sosiego'**
  String get settingsFeedbackSubject;

  /// No description provided for @aboutSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente del texto'**
  String get aboutSource;

  /// No description provided for @aboutPublicDomain.
  ///
  /// In es, this message translates to:
  /// **'Reina-Valera 1909, dominio público'**
  String get aboutPublicDomain;

  /// No description provided for @aboutAiNote.
  ///
  /// In es, this message translates to:
  /// **'Las reflexiones y oraciones se redactan con ayuda de inteligencia artificial y las revisa una persona. No sustituyen la guía pastoral ni la atención médica o psicológica.'**
  String get aboutAiNote;

  /// No description provided for @companionTitle.
  ///
  /// In es, this message translates to:
  /// **'Acompañamiento'**
  String get companionTitle;

  /// No description provided for @companionContext.
  ///
  /// In es, this message translates to:
  /// **'Contexto'**
  String get companionContext;

  /// No description provided for @companionReflection.
  ///
  /// In es, this message translates to:
  /// **'Reflexión'**
  String get companionReflection;

  /// No description provided for @companionApplication.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get companionApplication;

  /// No description provided for @companionPrayer.
  ///
  /// In es, this message translates to:
  /// **'Oración'**
  String get companionPrayer;

  /// No description provided for @companionAiLine.
  ///
  /// In es, this message translates to:
  /// **'Redactada con ayuda de inteligencia artificial y revisada por una persona'**
  String get companionAiLine;

  /// No description provided for @companionAnother.
  ///
  /// In es, this message translates to:
  /// **'Otra palabra'**
  String get companionAnother;

  /// No description provided for @companionMoreOfTheme.
  ///
  /// In es, this message translates to:
  /// **'Más versículos de este tema'**
  String get companionMoreOfTheme;

  /// No description provided for @companionMissingTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay una palabra para esto'**
  String get companionMissingTitle;

  /// No description provided for @companionMissingBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes ver versículos de este tema.'**
  String get companionMissingBody;

  /// No description provided for @readingMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String readingMinutes(int minutes);

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
  /// **'Ir a versículos'**
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
  /// **'Automático'**
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
  /// **'Busca una palabra, un tema o Juan 3:16'**
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
  /// **'No encontramos eso. Prueba con una palabra más corta o elige un tema'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Las tildes y las mayúsculas no importan.'**
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

  /// No description provided for @shareSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir este versículo'**
  String get shareSheetTitle;

  /// No description provided for @shareClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get shareClose;

  /// No description provided for @sharePreviewSemantics.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de la tarjeta, estilo {style}. {reference}'**
  String sharePreviewSemantics(String style, String reference);

  /// No description provided for @shareStylesLabel.
  ///
  /// In es, this message translates to:
  /// **'Elige un estilo'**
  String get shareStylesLabel;

  /// No description provided for @shareToLabel.
  ///
  /// In es, this message translates to:
  /// **'Para:'**
  String get shareToLabel;

  /// No description provided for @shareToHint.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo, mamá'**
  String get shareToHint;

  /// No description provided for @shareToHelper.
  ///
  /// In es, this message translates to:
  /// **'Es opcional y se queda en tu teléfono.'**
  String get shareToHelper;

  /// No description provided for @shareImageButton.
  ///
  /// In es, this message translates to:
  /// **'Compartir imagen'**
  String get shareImageButton;

  /// No description provided for @shareImagePreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando la imagen…'**
  String get shareImagePreparing;

  /// No description provided for @shareWhatsappButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar texto por WhatsApp'**
  String get shareWhatsappButton;

  /// No description provided for @shareImageError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos preparar la imagen. Inténtalo de nuevo.'**
  String get shareImageError;

  /// No description provided for @shareWhatsappError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir WhatsApp. Puedes instalarlo, o usar «Compartir imagen» y elegir otra aplicación.'**
  String get shareWhatsappError;

  /// No description provided for @listenAction.
  ///
  /// In es, this message translates to:
  /// **'Escuchar'**
  String get listenAction;

  /// No description provided for @listenPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get listenPause;

  /// No description provided for @listenResume.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get listenResume;

  /// No description provided for @listenStop.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get listenStop;

  /// No description provided for @listenNoVoice.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono no tiene voz en español. Puedes instalarla en Ajustes del teléfono, en Idioma y Salida de texto a voz'**
  String get listenNoVoice;

  /// No description provided for @listenFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer el texto en voz alta. Inténtalo de nuevo.'**
  String get listenFailed;

  /// No description provided for @voiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Velocidad de voz'**
  String get voiceTitle;

  /// No description provided for @voiceSlow.
  ///
  /// In es, this message translates to:
  /// **'Lenta'**
  String get voiceSlow;

  /// No description provided for @voiceNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get voiceNormal;

  /// No description provided for @voiceFast.
  ///
  /// In es, this message translates to:
  /// **'Rápida'**
  String get voiceFast;

  /// No description provided for @voiceTest.
  ///
  /// In es, this message translates to:
  /// **'Probar la voz'**
  String get voiceTest;

  /// No description provided for @voiceSampleText.
  ///
  /// In es, this message translates to:
  /// **'Jehová es mi pastor; nada me faltará.'**
  String get voiceSampleText;

  /// No description provided for @voiceNote.
  ///
  /// In es, this message translates to:
  /// **'Usamos la voz en español de tu teléfono.'**
  String get voiceNote;

  /// No description provided for @reminderCardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres recibir el versículo cada día?'**
  String get reminderCardTitle;

  /// No description provided for @reminderCardBody.
  ///
  /// In es, this message translates to:
  /// **'Elige una hora y te avisaremos con un versículo, sin molestar.'**
  String get reminderCardBody;

  /// No description provided for @reminderClock.
  ///
  /// In es, this message translates to:
  /// **'{hour}:{minute} {period}'**
  String reminderClock(int hour, String minute, String period);

  /// No description provided for @reminderAm.
  ///
  /// In es, this message translates to:
  /// **'a. m.'**
  String get reminderAm;

  /// No description provided for @reminderPm.
  ///
  /// In es, this message translates to:
  /// **'p. m.'**
  String get reminderPm;

  /// No description provided for @reminderTimeMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana, {time}'**
  String reminderTimeMorning(String time);

  /// No description provided for @reminderTimeAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Tarde, {time}'**
  String reminderTimeAfternoon(String time);

  /// No description provided for @reminderTimeNight.
  ///
  /// In es, this message translates to:
  /// **'Noche, {time}'**
  String reminderTimeNight(String time);

  /// No description provided for @reminderNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get reminderNotNow;

  /// No description provided for @reminderDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Listo, te avisaremos a las {time}'**
  String reminderDoneTitle(String time);

  /// No description provided for @reminderDoneBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiar la hora o desactivarlo en Ajustes.'**
  String get reminderDoneBody;

  /// No description provided for @reminderDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'Está bien, sin problema'**
  String get reminderDeniedTitle;

  /// No description provided for @reminderDeniedBody.
  ///
  /// In es, this message translates to:
  /// **'No activamos los avisos. Cuando quieras, puedes hacerlo desde Ajustes.'**
  String get reminderDeniedBody;

  /// No description provided for @reminderGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get reminderGotIt;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu versículo de hoy'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Versículo diario'**
  String get reminderSettingsTitle;

  /// No description provided for @reminderSwitchLabel.
  ///
  /// In es, this message translates to:
  /// **'Recibir el versículo cada día'**
  String get reminderSwitchLabel;

  /// No description provided for @reminderOn.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get reminderOn;

  /// No description provided for @reminderOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get reminderOff;

  /// No description provided for @reminderTimeSection.
  ///
  /// In es, this message translates to:
  /// **'¿A qué hora?'**
  String get reminderTimeSection;

  /// No description provided for @reminderOtherTime.
  ///
  /// In es, this message translates to:
  /// **'Otra hora'**
  String get reminderOtherTime;

  /// No description provided for @reminderOtherTimeChosen.
  ///
  /// In es, this message translates to:
  /// **'Otra hora: {time}'**
  String reminderOtherTimeChosen(String time);

  /// No description provided for @reminderPickerHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige la hora del aviso'**
  String get reminderPickerHelp;

  /// No description provided for @reminderPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'El teléfono no nos dejó enviar avisos. Puedes permitirlos en Ajustes del teléfono, en Aplicaciones, Sosiego, Notificaciones.'**
  String get reminderPermissionDenied;

  /// No description provided for @reminderSystemOff.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones están apagadas en tu teléfono, así que el aviso no llegará. Puedes encenderlas en Ajustes del teléfono, en Aplicaciones, Sosiego, Notificaciones.'**
  String get reminderSystemOff;

  /// No description provided for @reminderHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda con las notificaciones'**
  String get reminderHelpTitle;

  /// No description provided for @reminderHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Si el aviso no llega a su hora'**
  String get reminderHelpSubtitle;

  /// No description provided for @reminderHelpIntro.
  ///
  /// In es, this message translates to:
  /// **'Algunos teléfonos ahorran batería cerrando las aplicaciones. Para que el aviso llegue:'**
  String get reminderHelpIntro;

  /// No description provided for @reminderHelpStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre Ajustes del teléfono y entra en Aplicaciones.'**
  String get reminderHelpStep1;

  /// No description provided for @reminderHelpStep2.
  ///
  /// In es, this message translates to:
  /// **'Busca Sosiego y toca Batería.'**
  String get reminderHelpStep2;

  /// No description provided for @reminderHelpStep3.
  ///
  /// In es, this message translates to:
  /// **'Elige Sin restricciones. En algunos teléfonos dice No optimizar o Permitir actividad en segundo plano.'**
  String get reminderHelpStep3;

  /// No description provided for @reminderHelpBrandsTitle.
  ///
  /// In es, this message translates to:
  /// **'Según la marca de tu teléfono'**
  String get reminderHelpBrandsTitle;

  /// No description provided for @reminderHelpSamsung.
  ///
  /// In es, this message translates to:
  /// **'Samsung: Ajustes, Cuidado del dispositivo, Batería, Límites de uso en segundo plano. Quita Sosiego de Apps en suspensión.'**
  String get reminderHelpSamsung;

  /// No description provided for @reminderHelpXiaomi.
  ///
  /// In es, this message translates to:
  /// **'Xiaomi, Redmi y Poco: Ajustes, Aplicaciones, Permisos, Inicio automático. Activa Sosiego. Luego, en Ahorro de batería, elige Sin restricciones.'**
  String get reminderHelpXiaomi;

  /// No description provided for @reminderHelpOthers.
  ///
  /// In es, this message translates to:
  /// **'Motorola, Huawei, Honor, Oppo y Realme: en Batería, busca Inicio automático o Actividad en segundo plano y permítelo para Sosiego.'**
  String get reminderHelpOthers;

  /// No description provided for @reminderHelpLimit.
  ///
  /// In es, this message translates to:
  /// **'Si no abres la aplicación en 30 días, los avisos terminan. Al abrirla, vuelven solos.'**
  String get reminderHelpLimit;

  /// No description provided for @reminderHelpClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get reminderHelpClose;
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
