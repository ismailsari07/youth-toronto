// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mosquée Pape';

  @override
  String get tabPrayer => 'Prière';

  @override
  String get tabCommunity => 'Communauté';

  @override
  String get tabProfile => 'Profil';

  @override
  String prayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'sunrise': 'Lever du soleil',
      'dhuhr': 'Dhohr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Icha',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String prayerSalah(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'sunrise': 'Lever du soleil',
      'dhuhr': 'Dhohr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Icha',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Après le Fajr',
      'sunrise': 'Après le lever du soleil',
      'dhuhr': 'Après le Dhohr',
      'asr': 'Après l\'Asr',
      'maghrib': 'Après le Maghrib',
      'isha': 'Après l\'Icha',
      'other': 'Après $prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerInline(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'après le Fajr',
      'sunrise': 'après le lever du soleil',
      'dhuhr': 'après le Dhohr',
      'asr': 'après l\'Asr',
      'maghrib': 'après le Maghrib',
      'isha': 'après l\'Icha',
      'other': 'après $prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerTitle(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Après la prière du Fajr',
      'sunrise': 'Après le lever du soleil',
      'dhuhr': 'Après la prière du Dhohr',
      'asr': 'Après la prière de l\'Asr',
      'maghrib': 'Après la prière du Maghrib',
      'isha': 'Après la prière de l\'Icha',
      'other': 'Après la prière',
    });
    return '$_temp0';
  }

  @override
  String get organisationEyebrow => 'CANADIAN TURKISH ISLAMIC TRUST';

  @override
  String get nextPrayer => 'PROCHAINE PRIÈRE';

  @override
  String get city => 'Toronto';

  @override
  String get todayAtTheMosque => 'Aujourd\'hui à la mosquée';

  @override
  String get homeCommunitySection => 'Communauté';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get athanIqamah => 'Adhan · Iqama';

  @override
  String get iqamah => 'IQAMA';

  @override
  String athanAt(String time) {
    return 'Adhan $time';
  }

  @override
  String iqamahAt(String time) {
    return 'Iqama $time';
  }

  @override
  String prayerNow(String prayer) {
    return '$prayer · maintenant';
  }

  @override
  String get fajrWindowCloses => 'Fin du temps du Fajr';

  @override
  String get prayerReminders => 'Rappels de prière';

  @override
  String get prayerRemindersDetail => '5 minutes avant chaque iqama';

  @override
  String get reminderBody => 'Iqama dans 5 minutes';

  @override
  String get timesUnavailable => 'Horaires indisponibles';

  @override
  String get pullToRefresh => 'Tirez pour actualiser';

  @override
  String get timesUnavailableTitle => 'Les horaires du jour sont indisponibles';

  @override
  String get timesUnavailableBody =>
      'Le calendrier de la mosquée est inaccessible. Les rappels déjà programmés sur cet appareil restent actifs.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get jumuahThisFriday => 'Prière du vendredi · ce vendredi';

  @override
  String get jumuahEveryFriday => 'Chaque vendredi à la mosquée';

  @override
  String get everyFriday => 'Chaque vendredi';

  @override
  String salahAt(String time) {
    return 'Prière à $time';
  }

  @override
  String get eidFitr => 'Aïd al-Fitr';

  @override
  String get eidAdha => 'Aïd al-Adha';

  @override
  String eidTimes(String first, String second) {
    return 'Prière à $first · 2ᵉ prière à $second';
  }

  @override
  String get directions => 'Itinéraire';

  @override
  String get call => 'Appeler';

  @override
  String get callOffice => 'Appeler le bureau';

  @override
  String get hijriMonth1 => 'Mouharram';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi al-awwal';

  @override
  String get hijriMonth4 => 'Rabi ath-thani';

  @override
  String get hijriMonth5 => 'Joumada al-oula';

  @override
  String get hijriMonth6 => 'Joumada ath-thania';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Chaabane';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get hijriMonth10 => 'Chawwal';

  @override
  String get hijriMonth11 => 'Dhou al-qi\'da';

  @override
  String get hijriMonth12 => 'Dhou al-hijja';

  @override
  String get datePatternTitle => 'EEEE d MMMM';

  @override
  String get datePatternLong => 'EEEE d MMMM';

  @override
  String get datePatternShort => 'EEE d MMM';

  @override
  String get datePatternDayMonth => 'd MMMM';

  @override
  String get datePatternMonthYear => 'MMMM y';

  @override
  String get datePatternCard => 'd MMM';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String postedAgo(String ago) {
    return 'Publié $ago';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get repeatsWeekly => 'Chaque semaine';

  @override
  String get repeatsBiweekly => 'Toutes les 2 semaines';

  @override
  String get repeatsMonthly => 'Chaque mois';

  @override
  String everyWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Tous les lundis',
      'tue': 'Tous les mardis',
      'wed': 'Tous les mercredis',
      'thu': 'Tous les jeudis',
      'fri': 'Tous les vendredis',
      'sat': 'Tous les samedis',
      'sun': 'Tous les dimanches',
      'other': 'Tous les lundis',
    });
    return '$_temp0';
  }

  @override
  String everyOtherWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Un lundi sur deux',
      'tue': 'Un mardi sur deux',
      'wed': 'Un mercredi sur deux',
      'thu': 'Un jeudi sur deux',
      'fri': 'Un vendredi sur deux',
      'sat': 'Un samedi sur deux',
      'sun': 'Un dimanche sur deux',
      'other': 'Un lundi sur deux',
    });
    return '$_temp0';
  }

  @override
  String get everyTwoWeeks => 'Toutes les 2 semaines';

  @override
  String get monthly => 'Chaque mois';

  @override
  String everyMonthOnDay(String day) {
    return 'Le $day de chaque mois';
  }

  @override
  String get weeklyProgrammeEyebrow => 'PROGRAMME HEBDOMADAIRE';

  @override
  String get biweeklyProgrammeEyebrow => 'TOUTES LES 2 SEMAINES';

  @override
  String get monthlyProgrammeEyebrow => 'PROGRAMME MENSUEL';

  @override
  String get eventEyebrow => 'ÉVÉNEMENT';

  @override
  String get weeklyProgramme => 'Programme hebdomadaire';

  @override
  String get biweeklyProgramme => 'Programme toutes les 2 semaines';

  @override
  String get monthlyProgramme => 'Programme mensuel';

  @override
  String nextOn(String date) {
    return 'prochaine : $date';
  }

  @override
  String aboutTime(String time) {
    return 'vers $time';
  }

  @override
  String beginsAboutOn(String begins, String time, String date) {
    return '$begins — vers $time le $date';
  }

  @override
  String registerAt(String url) {
    return 'Inscription : $url';
  }

  @override
  String get events => 'Événements';

  @override
  String get announcements => 'Annonces';

  @override
  String get noEventsTitle => 'Aucun événement prévu';

  @override
  String get noEventsBody =>
      'Les événements publiés par la mosquée apparaîtront ici. La prière du vendredi a lieu chaque semaine, comme d\'habitude.';

  @override
  String get noAnnouncementsTitle => 'Aucune annonce';

  @override
  String get noAnnouncementsBody =>
      'Les avis du bureau de la mosquée apparaîtront ici.';

  @override
  String get notifyMe => 'Me prévenir des nouvelles publications';

  @override
  String get newBadge => 'Nouveau';

  @override
  String get announcementEyebrow => 'ANNONCE';

  @override
  String get register => 'S\'inscrire';

  @override
  String get registerFree => 'S\'inscrire · gratuit';

  @override
  String get aboutThisEvent => 'À propos de l\'événement';

  @override
  String get shareThisEvent => 'Partager l\'événement';

  @override
  String get shareThisAnnouncement => 'Partager l\'annonce';

  @override
  String get questions => 'Des questions ?';

  @override
  String get callTheOffice => 'Appeler le bureau de la mosquée';

  @override
  String get mosqueOffice => 'Bureau de la mosquée';

  @override
  String get everyoneWelcome => 'Tout le monde est bienvenu';

  @override
  String get freeToAttend => 'Entrée gratuite';

  @override
  String get ticketed => 'Sur billet';

  @override
  String get map => 'Carte';

  @override
  String get dropIn => 'Entrée libre — sans inscription';

  @override
  String get nextSession => 'Prochaine séance';

  @override
  String get startTime => 'Heure de début';

  @override
  String get date => 'Date';

  @override
  String get beginsAfterJamaah => 'Commence après la prière en commun';

  @override
  String get notSignedIn => 'Aucun compte connecté';

  @override
  String get notSignedInBody =>
      'Connectez-vous pour vous inscrire aux événements et retrouver vos rappels sur tous vos appareils.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signingIn => 'Connexion…';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createAccountButton => 'Créer le compte';

  @override
  String get creatingAccount => 'Création…';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get settings => 'Paramètres';

  @override
  String get settingsRowSubtitle => 'Rappels, langue, compte';

  @override
  String get yourDetails => 'Vos informations';

  @override
  String get notifications => 'Notifications';

  @override
  String get app => 'Application';

  @override
  String get account => 'Compte';

  @override
  String get accountEyebrow => 'COMPTE';

  @override
  String signedInAs(String email) {
    return 'Session ouverte : $email';
  }

  @override
  String get notSignedInShort => 'Aucune session ouverte';

  @override
  String get language => 'Langue';

  @override
  String get deviceLanguage => 'Langue de l\'appareil';

  @override
  String get deviceLanguageDetail => 'Suit le réglage du téléphone';

  @override
  String get languageAuto => 'Auto';

  @override
  String get mosqueAndContact => 'Mosquée et contact';

  @override
  String get aboutThisApp => 'À propos de l\'application';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get worksWithoutAccount =>
      'Les horaires de prière, les événements et les annonces fonctionnent sans compte.';

  @override
  String get member => 'Membre';

  @override
  String memberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get name => 'Nom';

  @override
  String get email => 'Courriel';

  @override
  String get phone => 'Téléphone';

  @override
  String get website => 'Site web';

  @override
  String get notAdded => 'Non renseigné';

  @override
  String get password => 'Mot de passe';

  @override
  String get emailHint => 'vous@exemple.com';

  @override
  String get welcomeBack => 'Bienvenue';

  @override
  String get signInSubtitle =>
      'Connectez-vous pour vous inscrire aux événements';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get accountOptional =>
      'Le compte est facultatif. Les horaires de prière, les événements et les annonces fonctionnent sans compte.';

  @override
  String get signUpSubtitle => 'Pour que le bureau sache qui vient';

  @override
  String get fullName => 'Nom complet';

  @override
  String get yourName => 'Votre nom';

  @override
  String get phoneOptional => 'Téléphone (facultatif)';

  @override
  String get detailsSharedOnlyWithOffice =>
      'Vos informations sont communiquées uniquement au bureau de la mosquée.';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get enterName => 'Veuillez saisir votre nom.';

  @override
  String get enterValidEmail => 'Veuillez saisir un courriel valide.';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get chooseDob => 'Veuillez indiquer votre date de naissance.';

  @override
  String get errorUnexpected => 'Une erreur inattendue s\'est produite.';

  @override
  String get errorInvalidCredentials => 'Courriel ou mot de passe incorrect.';

  @override
  String get errorEmailTaken => 'Un compte existe déjà avec ce courriel.';

  @override
  String get errorWeakPassword =>
      'Ce mot de passe est trop faible. Veuillez en choisir un plus sûr.';

  @override
  String get errorEmailNotConfirmed =>
      'Veuillez d\'abord confirmer votre courriel avec le lien envoyé.';

  @override
  String get errorRateLimited =>
      'Trop de tentatives. Veuillez patienter un moment, puis réessayer.';

  @override
  String get errorNetwork =>
      'Impossible de joindre le serveur. Vérifiez votre connexion, puis réessayez.';

  @override
  String get errorSessionExpired =>
      'Votre session a expiré. Reconnectez-vous, puis réessayez.';

  @override
  String get errorAdminAccount =>
      'Les comptes administrateur ne peuvent pas être supprimés depuis l\'application. Contactez un autre administrateur.';

  @override
  String get errorDeleteFailed =>
      'Impossible de supprimer votre compte. Veuillez réessayer.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get deleting => 'Suppression…';

  @override
  String get keepMyAccount => 'Garder mon compte';

  @override
  String get cannotBeUndone => 'Cette action est irréversible';

  @override
  String get deleteAccountBody1 =>
      'La suppression de votre compte efface votre nom, votre courriel, votre numéro de téléphone et votre date de naissance des registres de la mosquée, ainsi que tout document transmis au service du mariage.';

  @override
  String get deleteAccountBody2 =>
      'L\'application fonctionne aussi sans compte : horaires de prière, événements et annonces restent accessibles.';

  @override
  String get whatStays => 'Ce qui est conservé';

  @override
  String get remindersStay =>
      'Conservés sur cet appareil, ils ne sont pas liés à votre compte';

  @override
  String get attendanceRecorded => 'Participations déjà enregistrées';

  @override
  String get attendanceStays =>
      'Conservées sous forme de total, sans votre nom';

  @override
  String get confirm => 'Confirmation';

  @override
  String get deleteConfirmWord => 'SUPPRIMER';

  @override
  String typeWordToConfirm(String word) {
    return 'Saisissez $word pour confirmer';
  }

  @override
  String get accountDeleted => 'Votre compte a été supprimé.';

  @override
  String get mosqueServices => 'Services de la mosquée';

  @override
  String get marriageService => 'Service du mariage';

  @override
  String get marriageServiceRow => 'Mise en relation confidentielle';

  @override
  String get marriageEyebrow => 'SERVICE DU MARIAGE';

  @override
  String get underReview => 'En cours d\'examen';

  @override
  String submittedOn(String date) {
    return 'Envoyé le $date';
  }

  @override
  String get marriageGateTitle => 'Mise en relation confidentielle';

  @override
  String get marriageGateSubtitle => 'Un service de la mosquée Pape';

  @override
  String get marriageGateBody =>
      'Si vous souhaitez vous marier, vous pouvez transmettre un document vous présentant à l\'imam de la mosquée. L\'imam le lit en privé et, si une personne semble vous convenir, vous contacte directement. Rien n\'est publié et personne d\'autre ne le voit.';

  @override
  String get yourPrivacy => 'Votre confidentialité';

  @override
  String get privacyOnlyImam => 'Vous et l\'imam uniquement';

  @override
  String get privacyOnlyImamBody =>
      'Votre document n\'est jamais montré aux autres membres';

  @override
  String get privacyNoProfiles => 'Ni profils, ni consultation';

  @override
  String get privacyNoProfilesBody =>
      'Il n\'existe aucune liste ni aucun annuaire des demandes';

  @override
  String get privacyWithdraw => 'Retrait possible à tout moment';

  @override
  String get privacyWithdrawBody =>
      'Votre document est supprimé dès le retrait';

  @override
  String get marriageAgeNote => 'Réservé aux membres de 18 ans et plus.';

  @override
  String get signInToContinue => 'Se connecter pour continuer';

  @override
  String get marriageGateCaption =>
      'Un compte permet à l\'imam de vous joindre en privé.';

  @override
  String get dobTitle => 'Votre date de naissance';

  @override
  String get dobSubtitle => 'Demandée une seule fois, gardée privée';

  @override
  String get dobBody =>
      'Le service du mariage est réservé aux membres de 18 ans et plus. Votre date de naissance est enregistrée dans votre compte et ne pourra plus être modifiée : veuillez la vérifier avant de continuer.';

  @override
  String get dobField => 'Date de naissance';

  @override
  String get dobHint => 'Choisir une date';

  @override
  String get dobContinue => 'Enregistrer et continuer';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get dobSaveFailed =>
      'Impossible d\'enregistrer votre date de naissance. Veuillez réessayer.';

  @override
  String get notEligibleTitle => 'Réservé aux membres de 18 ans et plus';

  @override
  String get notEligibleBody =>
      'Le service du mariage est réservé aux membres majeurs. Votre compte et le reste de l\'application ne sont pas concernés.';

  @override
  String get uploadTitle => 'Transmettre votre document';

  @override
  String get uploadSubtitle => 'Un seul fichier, lu uniquement par l\'imam';

  @override
  String get chooseOneFile => 'Choisissez un fichier';

  @override
  String get fileRules => 'PDF, JPG ou PNG · 4 Mo maximum';

  @override
  String get files => 'Fichiers';

  @override
  String get photos => 'Photos';

  @override
  String get whatToInclude => 'Que mettre dans le document';

  @override
  String get whatToIncludeBody1 =>
      'Il n\'y a pas de modèle. Présentez-vous avec vos propres mots : votre parcours, votre famille, votre pratique religieuse et ce que vous espérez trouver chez votre futur conjoint ou future conjointe. Vous pouvez écrire en français, en turc ou en anglais.';

  @override
  String get whatToIncludeBody2 =>
      'Ne partagez que ce qui vous met à l\'aise. Si d\'autres informations sont nécessaires, l\'imam vous les demandera directement.';

  @override
  String get privacyStrip =>
      'Visible uniquement par vous et l\'imam de la mosquée. Jamais montré aux autres membres.';

  @override
  String get submit => 'Envoyer';

  @override
  String get chooseFileToContinue => 'Choisissez un fichier pour continuer.';

  @override
  String get uploadingPrivately => 'Envoi privé en cours…';

  @override
  String get uploading => 'Envoi…';

  @override
  String get keepAppOpen =>
      'Gardez l\'application ouverte jusqu\'à la fin de l\'envoi.';

  @override
  String get tooLarge => 'trop volumineux';

  @override
  String get tooLargeBody =>
      'Les fichiers doivent faire moins de 4 Mo. Essayez d\'exporter le PDF dans une taille plus petite, ou choisissez une seule photo au lieu de plusieurs.';

  @override
  String get unsupportedType => 'non pris en charge';

  @override
  String get unsupportedTypeBody =>
      'Seuls les fichiers PDF, JPG ou PNG peuvent être transmis.';

  @override
  String get unreadableFile =>
      'Impossible de lire ce fichier. Essayez-en un autre.';

  @override
  String get cantBeRead => 'illisible';

  @override
  String get preparingPrivately => 'Préparation privée en cours…';

  @override
  String get detailsUnavailable =>
      'Impossible de charger les informations de votre compte. Veuillez réessayer.';

  @override
  String get uploadFailed =>
      'L\'envoi n\'a pas abouti. Vérifiez votre connexion, puis réessayez.';

  @override
  String get receivedTitle => 'Bien reçu, merci';

  @override
  String get receivedBody =>
      'Votre document est conservé en privé. Seuls vous et l\'imam pouvez l\'ouvrir.';

  @override
  String get whatHappensNext => 'Et ensuite';

  @override
  String get nextImamReads => 'L\'imam le lit';

  @override
  String get nextImamReadsBody => 'En privé, dès que possible';

  @override
  String get nextContacted => 'L\'imam vous contacte en privé';

  @override
  String get nextContactedBody =>
      'Seulement si une personne semble vous convenir';

  @override
  String get nextYouDecide => 'Vous décidez';

  @override
  String get nextYouDecideBody => 'Rien ne se fait sans votre accord';

  @override
  String get done => 'Terminé';

  @override
  String get yourApplication => 'Votre demande';

  @override
  String get underReviewBody =>
      'L\'imam a reçu votre document et vous contactera en privé si une personne semble vous convenir. Vous n\'avez rien d\'autre à faire.';

  @override
  String get yourDocument => 'Votre document';

  @override
  String get view => 'Afficher';

  @override
  String get replace => 'Remplacer';

  @override
  String get withdrawTitle => 'Retirer ma demande';

  @override
  String get withdrawCaption =>
      'Supprime votre document des registres de la mosquée';

  @override
  String get openFailed =>
      'Impossible d\'ouvrir votre document. Veuillez réessayer.';

  @override
  String get openingPrivately => 'Ouverture privée en cours…';

  @override
  String get replaceSubtitle =>
      'Votre document actuel est conservé jusqu\'à l\'envoi du nouveau';

  @override
  String get applicationUnavailable =>
      'Impossible de charger votre demande. Veuillez réessayer.';

  @override
  String get withdrawSheetTitle => 'Retirer votre demande ?';

  @override
  String get withdrawSheetBody =>
      'Votre document sera définitivement supprimé et l\'imam n\'y aura plus accès. Vous pourrez refaire une demande à tout moment.';

  @override
  String get withdrawConfirm => 'Retirer et supprimer';

  @override
  String get withdrawing => 'Suppression…';

  @override
  String get withdrawKeep => 'Garder ma demande';

  @override
  String get withdrawFailed =>
      'Impossible de retirer votre demande. Veuillez réessayer.';

  @override
  String get withdrawn => 'Votre demande a été retirée.';

  @override
  String get theMosque => 'LA MOSQUÉE';

  @override
  String get openingHours => 'Heures d\'ouverture';

  @override
  String get dailyPrayers => 'Prières quotidiennes';

  @override
  String get dailyPrayersBody =>
      'Ouverte pour chaque prière, du Fajr à l\'Icha';

  @override
  String get jumuah => 'Prière du vendredi';

  @override
  String get fridays => 'Le vendredi';

  @override
  String get office => 'Bureau';

  @override
  String get callForHours => 'Appelez pour connaître les horaires';

  @override
  String get getInTouch => 'Nous joindre';

  @override
  String sizeMegabytes(String size) {
    return '$size Mo';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size Ko';
  }
}
