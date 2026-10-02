// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Pape Camii';

  @override
  String get tabPrayer => 'Namaz';

  @override
  String get tabCommunity => 'Topluluk';

  @override
  String get tabProfile => 'Profil';

  @override
  String prayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'İmsak',
      'sunrise': 'Güneş',
      'dhuhr': 'Öğle',
      'asr': 'İkindi',
      'maghrib': 'Akşam',
      'isha': 'Yatsı',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String prayerSalah(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Sabah namazı',
      'sunrise': 'Güneş',
      'dhuhr': 'Öğle namazı',
      'asr': 'İkindi namazı',
      'maghrib': 'Akşam namazı',
      'isha': 'Yatsı namazı',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Sabah namazından sonra',
      'sunrise': 'Güneş doğduktan sonra',
      'dhuhr': 'Öğle namazından sonra',
      'asr': 'İkindi namazından sonra',
      'maghrib': 'Akşam namazından sonra',
      'isha': 'Yatsı namazından sonra',
      'other': '$prayer sonrası',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerInline(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'sabah namazından sonra',
      'sunrise': 'güneş doğduktan sonra',
      'dhuhr': 'öğle namazından sonra',
      'asr': 'ikindi namazından sonra',
      'maghrib': 'akşam namazından sonra',
      'isha': 'yatsı namazından sonra',
      'other': '$prayer sonrası',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerTitle(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Sabah namazından sonra',
      'sunrise': 'Güneş doğduktan sonra',
      'dhuhr': 'Öğle namazından sonra',
      'asr': 'İkindi namazından sonra',
      'maghrib': 'Akşam namazından sonra',
      'isha': 'Yatsı namazından sonra',
      'other': '$prayer sonrası',
    });
    return '$_temp0';
  }

  @override
  String get mosqueEyebrow => 'PAPE CAMİİ';

  @override
  String get nextPrayer => 'SIRADAKİ NAMAZ';

  @override
  String get city => 'Toronto';

  @override
  String get todayAtTheMosque => 'Bugün camide';

  @override
  String get athanIqamah => 'Ezan · Cemaat';

  @override
  String get iqamah => 'CEMAAT';

  @override
  String athanAt(String time) {
    return 'Ezan $time';
  }

  @override
  String iqamahAt(String time) {
    return 'Cemaat $time';
  }

  @override
  String prayerNow(String prayer) {
    return '$prayer · şimdi';
  }

  @override
  String get fajrWindowCloses => 'Sabah namazının vakti çıkar';

  @override
  String get prayerReminders => 'Namaz hatırlatıcıları';

  @override
  String get prayerRemindersDetail => 'Her cemaat vaktinden 5 dakika önce';

  @override
  String get reminderBody => 'Cemaate 5 dakika kaldı';

  @override
  String get timesUnavailable => 'Vakitler alınamadı';

  @override
  String get pullToRefresh => 'Yenilemek için aşağı çekin';

  @override
  String get timesUnavailableTitle => 'Bugünün vakitleri alınamadı';

  @override
  String get timesUnavailableBody =>
      'Caminin takvimine ulaşılamadı. Bu cihazda daha önce kurulan hatırlatıcılar çalışmaya devam eder.';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get jumuahThisFriday => 'Cuma namazı · bu Cuma';

  @override
  String get jumuahEveryFriday => 'Her Cuma camide';

  @override
  String get everyFriday => 'Her Cuma';

  @override
  String salahAt(String time) {
    return 'Namaz $time';
  }

  @override
  String get eidFitr => 'Ramazan Bayramı';

  @override
  String get eidAdha => 'Kurban Bayramı';

  @override
  String eidTimes(String first, String second) {
    return 'Namaz $first · İkinci cemaat $second';
  }

  @override
  String get directions => 'Yol tarifi';

  @override
  String get call => 'Ara';

  @override
  String get callOffice => 'Ofisi ara';

  @override
  String get hijriMonth1 => 'Muharrem';

  @override
  String get hijriMonth2 => 'Safer';

  @override
  String get hijriMonth3 => 'Rebiülevvel';

  @override
  String get hijriMonth4 => 'Rebiülahir';

  @override
  String get hijriMonth5 => 'Cemaziyelevvel';

  @override
  String get hijriMonth6 => 'Cemaziyelahir';

  @override
  String get hijriMonth7 => 'Recep';

  @override
  String get hijriMonth8 => 'Şaban';

  @override
  String get hijriMonth9 => 'Ramazan';

  @override
  String get hijriMonth10 => 'Şevval';

  @override
  String get hijriMonth11 => 'Zilkade';

  @override
  String get hijriMonth12 => 'Zilhicce';

  @override
  String get datePatternTitle => 'd MMMM EEEE';

  @override
  String get datePatternLong => 'd MMMM EEEE';

  @override
  String get datePatternShort => 'd MMMM EEEE';

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
      other: '$count dakika önce',
      one: '1 dakika önce',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hafta önce',
      one: '1 hafta önce',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ay önce',
      one: '1 ay önce',
    );
    return '$_temp0';
  }

  @override
  String postedAgo(String ago) {
    return '$ago paylaşıldı';
  }

  @override
  String get today => 'Bugün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String get repeatsWeekly => 'Her hafta tekrarlanır';

  @override
  String get repeatsBiweekly => 'İki haftada bir tekrarlanır';

  @override
  String get repeatsMonthly => 'Her ay tekrarlanır';

  @override
  String everyWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Her Pazartesi',
      'tue': 'Her Salı',
      'wed': 'Her Çarşamba',
      'thu': 'Her Perşembe',
      'fri': 'Her Cuma',
      'sat': 'Her Cumartesi',
      'sun': 'Her Pazar',
      'other': 'Her Pazartesi',
    });
    return '$_temp0';
  }

  @override
  String everyOtherWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'İki haftada bir Pazartesi',
      'tue': 'İki haftada bir Salı',
      'wed': 'İki haftada bir Çarşamba',
      'thu': 'İki haftada bir Perşembe',
      'fri': 'İki haftada bir Cuma',
      'sat': 'İki haftada bir Cumartesi',
      'sun': 'İki haftada bir Pazar',
      'other': 'İki haftada bir Pazartesi',
    });
    return '$_temp0';
  }

  @override
  String get everyTwoWeeks => 'İki haftada bir';

  @override
  String get monthly => 'Her ay';

  @override
  String everyMonthOnDay(String day) {
    return 'Her ayın $day. günü';
  }

  @override
  String get weeklyProgrammeEyebrow => 'HAFTALIK PROGRAM';

  @override
  String get biweeklyProgrammeEyebrow => 'İKİ HAFTALIK PROGRAM';

  @override
  String get monthlyProgrammeEyebrow => 'AYLIK PROGRAM';

  @override
  String get eventEyebrow => 'ETKİNLİK';

  @override
  String get weeklyProgramme => 'Haftalık program';

  @override
  String get biweeklyProgramme => 'İki haftada bir program';

  @override
  String get monthlyProgramme => 'Aylık program';

  @override
  String nextOn(String date) {
    return 'sonraki: $date';
  }

  @override
  String aboutTime(String time) {
    return 'yaklaşık $time';
  }

  @override
  String beginsAboutOn(String begins, String time, String date) {
    return '$begins — $date, yaklaşık $time';
  }

  @override
  String registerAt(String url) {
    return 'Kayıt: $url';
  }

  @override
  String get events => 'Etkinlikler';

  @override
  String get announcements => 'Duyurular';

  @override
  String get noEventsTitle => 'Planlanmış etkinlik yok';

  @override
  String get noEventsBody =>
      'Caminin duyurduğu etkinlikler burada görünür. Cuma namazı her hafta olduğu gibi kılınır.';

  @override
  String get noAnnouncementsTitle => 'Duyuru yok';

  @override
  String get noAnnouncementsBody => 'Cami ofisinin duyuruları burada görünür.';

  @override
  String get notifyMe => 'Yeni bir şey paylaşılınca bana haber ver';

  @override
  String get newBadge => 'Yeni';

  @override
  String get announcementEyebrow => 'DUYURU';

  @override
  String get register => 'Kaydol';

  @override
  String get registerFree => 'Kaydol · ücretsiz';

  @override
  String get aboutThisEvent => 'Etkinlik hakkında';

  @override
  String get shareThisEvent => 'Etkinliği paylaş';

  @override
  String get shareThisAnnouncement => 'Duyuruyu paylaş';

  @override
  String get questions => 'Sorunuz mu var?';

  @override
  String get callTheOffice => 'Cami ofisini arayın';

  @override
  String get mosqueOffice => 'Cami ofisi';

  @override
  String get everyoneWelcome => 'Herkes davetlidir';

  @override
  String get freeToAttend => 'Katılım ücretsiz';

  @override
  String get ticketed => 'Biletli';

  @override
  String get map => 'Harita';

  @override
  String get dropIn => 'Kayıt gerekmez, doğrudan gelebilirsiniz';

  @override
  String get nextSession => 'Sonraki buluşma';

  @override
  String get startTime => 'Başlangıç saati';

  @override
  String get date => 'Tarih';

  @override
  String get beginsAfterJamaah => 'Cemaatle namaz bitince başlar';

  @override
  String get notSignedIn => 'Giriş yapmadınız';

  @override
  String get notSignedInBody =>
      'Etkinliklere kaydolmak ve hatırlatıcılarınızı tüm cihazlarınızda kullanmak için giriş yapın.';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signingIn => 'Giriş yapılıyor…';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get createAccountButton => 'Hesabı oluştur';

  @override
  String get creatingAccount => 'Oluşturuluyor…';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsRowSubtitle => 'Hatırlatıcılar, dil, hesap';

  @override
  String get yourDetails => 'Bilgileriniz';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get app => 'Uygulama';

  @override
  String get account => 'Hesap';

  @override
  String get accountEyebrow => 'HESAP';

  @override
  String signedInAs(String email) {
    return '$email ile giriş yapıldı';
  }

  @override
  String get notSignedInShort => 'Giriş yapılmadı';

  @override
  String get language => 'Dil';

  @override
  String get deviceLanguage => 'Cihaz dili';

  @override
  String get deviceLanguageDetail => 'Telefonunuzun ayarını izler';

  @override
  String get languageAuto => 'Otomatik';

  @override
  String get mosqueAndContact => 'Cami ve iletişim';

  @override
  String get aboutThisApp => 'Uygulama hakkında';

  @override
  String versionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String get worksWithoutAccount =>
      'Namaz vakitleri, etkinlikler ve duyurular hesap olmadan da kullanılabilir.';

  @override
  String get member => 'Üye';

  @override
  String memberSince(String date) {
    return 'Üyelik: $date';
  }

  @override
  String get name => 'Ad soyad';

  @override
  String get email => 'E-posta';

  @override
  String get phone => 'Telefon';

  @override
  String get website => 'Web sitesi';

  @override
  String get notAdded => 'Eklenmedi';

  @override
  String get password => 'Şifre';

  @override
  String get emailHint => 'siz@ornek.com';

  @override
  String get welcomeBack => 'Tekrar hoş geldiniz';

  @override
  String get signInSubtitle => 'Etkinliklere kaydolmak için giriş yapın';

  @override
  String get noAccountYet => 'Henüz hesabınız yok mu?';

  @override
  String get accountOptional =>
      'Hesap isteğe bağlıdır. Namaz vakitleri, etkinlikler ve duyurular hesap olmadan da kullanılabilir.';

  @override
  String get signUpSubtitle => 'Ofis kimlerin geleceğini bilsin diye';

  @override
  String get fullName => 'Ad soyad';

  @override
  String get yourName => 'Adınız ve soyadınız';

  @override
  String get phoneOptional => 'Telefon (isteğe bağlı)';

  @override
  String get detailsSharedOnlyWithOffice =>
      'Bilgileriniz yalnızca cami ofisiyle paylaşılır.';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? Giriş yapın';

  @override
  String get enterName => 'Lütfen adınızı girin.';

  @override
  String get enterValidEmail => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get chooseDob => 'Lütfen doğum tarihinizi seçin.';

  @override
  String get errorUnexpected => 'Beklenmeyen bir hata oluştu.';

  @override
  String get errorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get errorEmailTaken => 'Bu e-posta adresiyle zaten bir hesap var.';

  @override
  String get errorWeakPassword =>
      'Bu şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';

  @override
  String get errorEmailNotConfirmed =>
      'Lütfen önce size gönderdiğimiz bağlantıyla e-postanızı onaylayın.';

  @override
  String get errorRateLimited =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.';

  @override
  String get errorNetwork =>
      'Sunucuya ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get errorSessionExpired =>
      'Oturumunuzun süresi doldu. Tekrar giriş yapıp yeniden deneyin.';

  @override
  String get errorAdminAccount =>
      'Yönetici hesapları uygulamadan silinemez. Başka bir yöneticiyle iletişime geçin.';

  @override
  String get errorDeleteFailed =>
      'Hesabınız silinemedi. Lütfen tekrar deneyin.';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteMyAccount => 'Hesabımı sil';

  @override
  String get deleting => 'Siliniyor…';

  @override
  String get keepMyAccount => 'Hesabımı koru';

  @override
  String get cannotBeUndone => 'Bu işlem geri alınamaz';

  @override
  String get deleteAccountBody1 =>
      'Hesabınızı silmek; adınızı, e-posta adresinizi, telefon numaranızı ve doğum tarihinizi, evlilik hizmetiyle paylaştığınız belgeyle birlikte caminin kayıtlarından kaldırır.';

  @override
  String get deleteAccountBody2 =>
      'Uygulama hesap olmadan da çalışır: namaz vakitleri, etkinlikler ve duyurular giriş yapmadan da kullanılabilir.';

  @override
  String get whatStays => 'Silinmeyenler';

  @override
  String get remindersStay => 'Bu cihazda kalır, hesabınıza bağlı değildir';

  @override
  String get attendanceRecorded => 'Önceden kaydedilen katılımlar';

  @override
  String get attendanceStays => 'Adınız olmadan, yalnızca sayı olarak tutulur';

  @override
  String get confirm => 'Onay';

  @override
  String get deleteConfirmWord => 'SİL';

  @override
  String typeWordToConfirm(String word) {
    return 'Onaylamak için $word yazın';
  }

  @override
  String get accountDeleted => 'Hesabınız silindi.';

  @override
  String get mosqueServices => 'Cami hizmetleri';

  @override
  String get marriageService => 'Evlilik hizmeti';

  @override
  String get marriageServiceRow => 'Gizlilik içinde aracılık';

  @override
  String get marriageEyebrow => 'EVLİLİK HİZMETİ';

  @override
  String get underReview => 'İnceleniyor';

  @override
  String submittedOn(String date) {
    return '$date tarihinde gönderildi';
  }

  @override
  String get marriageGateTitle => 'Gizlilik içinde evlilik aracılığı';

  @override
  String get marriageGateSubtitle => 'Pape Camii\'nin bir hizmeti';

  @override
  String get marriageGateBody =>
      'Evlenmeyi düşünüyorsanız, kendinizi anlatan bir belgeyi caminin imamıyla paylaşabilirsiniz. İmam belgenizi mahremiyet içinde okur ve uygun bir kişi olursa doğrudan sizinle iletişime geçer. Hiçbir şey yayımlanmaz, belgenizi başka kimse görmez.';

  @override
  String get yourPrivacy => 'Gizliliğiniz';

  @override
  String get privacyOnlyImam => 'Yalnızca siz ve imam';

  @override
  String get privacyOnlyImamBody =>
      'Belgeniz hiçbir zaman diğer üyelere gösterilmez';

  @override
  String get privacyNoProfiles => 'Profil yok, göz atma yok';

  @override
  String get privacyNoProfilesBody =>
      'Başvuranların listesi ya da rehberi yoktur';

  @override
  String get privacyWithdraw => 'İstediğiniz zaman geri çekin';

  @override
  String get privacyWithdrawBody =>
      'Başvurunuzu geri çektiğinizde belgeniz silinir';

  @override
  String get marriageAgeNote => '18 yaş ve üzeri üyelere açıktır.';

  @override
  String get signInToContinue => 'Devam etmek için giriş yapın';

  @override
  String get marriageGateCaption =>
      'Hesabınız, imamın size özel olarak ulaşmasını sağlar.';

  @override
  String get dobTitle => 'Doğum tarihiniz';

  @override
  String get dobSubtitle => 'Bir kez istenir, gizli tutulur';

  @override
  String get dobBody =>
      'Evlilik hizmeti 18 yaş ve üzeri üyelere açıktır. Doğum tarihiniz hesabınıza kaydedilir ve sonradan değiştirilemez; lütfen devam etmeden önce kontrol edin.';

  @override
  String get dobField => 'Doğum tarihi';

  @override
  String get dobHint => 'Tarih seçin';

  @override
  String get dobContinue => 'Kaydet ve devam et';

  @override
  String get saving => 'Kaydediliyor…';

  @override
  String get dobSaveFailed =>
      'Doğum tarihiniz kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get notEligibleTitle => '18 yaş ve üzeri üyelere açıktır';

  @override
  String get notEligibleBody =>
      'Evlilik hizmeti yalnızca reşit üyelere açıktır. Hesabınız ve uygulamanın geri kalanı bundan etkilenmez.';

  @override
  String get uploadTitle => 'Belgenizi paylaşın';

  @override
  String get uploadSubtitle => 'Tek dosya, yalnızca imam okur';

  @override
  String get chooseOneFile => 'Bir dosya seçin';

  @override
  String get fileRules => 'PDF, JPG veya PNG · en fazla 4 MB';

  @override
  String get files => 'Dosyalar';

  @override
  String get photos => 'Fotoğraflar';

  @override
  String get whatToInclude => 'Belgede neler olmalı';

  @override
  String get whatToIncludeBody1 =>
      'Hazır bir şablon yoktur. Kendinizi kendi cümlelerinizle anlatın: geçmişiniz, aileniz, dinî yaşantınız ve eşinizde aradığınız özellikler. Fransızca, Türkçe veya İngilizce yazabilirsiniz.';

  @override
  String get whatToIncludeBody2 =>
      'Yalnızca paylaşmak istediklerinizi yazın. Başka bir bilgi gerekirse imam doğrudan size sorar.';

  @override
  String get privacyStrip =>
      'Yalnızca siz ve caminin imamı görebilir. Diğer üyelere asla gösterilmez.';

  @override
  String get submit => 'Gönder';

  @override
  String get chooseFileToContinue => 'Devam etmek için bir dosya seçin.';

  @override
  String get uploadingPrivately => 'Gizli olarak yükleniyor…';

  @override
  String get uploading => 'Yükleniyor…';

  @override
  String get keepAppOpen => 'Yükleme bitene kadar uygulamayı açık tutun.';

  @override
  String get tooLarge => 'çok büyük';

  @override
  String get tooLargeBody =>
      'Dosyalar 4 MB\'tan küçük olmalıdır. PDF\'i daha küçük bir boyutta kaydetmeyi deneyin ya da birkaç fotoğraf yerine tek bir fotoğraf seçin.';

  @override
  String get unsupportedType => 'desteklenmiyor';

  @override
  String get unsupportedTypeBody =>
      'Yalnızca PDF, JPG veya PNG dosyaları paylaşılabilir.';

  @override
  String get unreadableFile => 'Bu dosya okunamadı. Başka bir dosya deneyin.';

  @override
  String get cantBeRead => 'okunamıyor';

  @override
  String get preparingPrivately => 'Gizli olarak hazırlanıyor…';

  @override
  String get detailsUnavailable =>
      'Hesap bilgileriniz yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get uploadFailed =>
      'Yükleme tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get receivedTitle => 'Alındı, teşekkür ederiz';

  @override
  String get receivedBody =>
      'Belgeniz gizli olarak saklanır. Yalnızca siz ve imam açabilirsiniz.';

  @override
  String get whatHappensNext => 'Bundan sonra ne olacak';

  @override
  String get nextImamReads => 'İmam belgenizi okur';

  @override
  String get nextImamReadsBody => 'Mahremiyet içinde, ilk uygun zamanda';

  @override
  String get nextContacted => 'Sizinle özel olarak iletişime geçilir';

  @override
  String get nextContactedBody => 'Yalnızca uygun bir kişi olursa';

  @override
  String get nextYouDecide => 'Karar sizindir';

  @override
  String get nextYouDecideBody => 'Onayınız olmadan hiçbir adım atılmaz';

  @override
  String get done => 'Tamam';

  @override
  String get yourApplication => 'Başvurunuz';

  @override
  String get underReviewBody =>
      'Belgeniz imama ulaştı. Uygun bir kişi olursa sizinle özel olarak iletişime geçecek. Yapmanız gereken başka bir şey yok.';

  @override
  String get yourDocument => 'Belgeniz';

  @override
  String get view => 'Görüntüle';

  @override
  String get replace => 'Değiştir';

  @override
  String get withdrawTitle => 'Başvurumu geri çek';

  @override
  String get withdrawCaption => 'Belgenizi caminin kayıtlarından siler';

  @override
  String get openFailed => 'Belgeniz açılamadı. Lütfen tekrar deneyin.';

  @override
  String get openingPrivately => 'Gizli olarak açılıyor…';

  @override
  String get replaceSubtitle => 'Yenisi yüklenene kadar mevcut belgeniz kalır';

  @override
  String get applicationUnavailable =>
      'Başvurunuz yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get withdrawSheetTitle => 'Başvurunuzu geri çekmek istiyor musunuz?';

  @override
  String get withdrawSheetBody =>
      'Belgeniz kalıcı olarak silinir ve imam artık göremez. İstediğiniz zaman yeniden başvurabilirsiniz.';

  @override
  String get withdrawConfirm => 'Geri çek ve sil';

  @override
  String get withdrawing => 'Siliniyor…';

  @override
  String get withdrawKeep => 'Başvurumu koru';

  @override
  String get withdrawFailed =>
      'Başvurunuz geri çekilemedi. Lütfen tekrar deneyin.';

  @override
  String get withdrawn => 'Başvurunuz geri çekildi.';

  @override
  String get theMosque => 'CAMİ';

  @override
  String get openingHours => 'Açık olduğu saatler';

  @override
  String get dailyPrayers => 'Vakit namazları';

  @override
  String get dailyPrayersBody =>
      'Sabah namazından yatsıya kadar her vakit açık';

  @override
  String get jumuah => 'Cuma namazı';

  @override
  String get fridays => 'Cuma günleri';

  @override
  String get office => 'Ofis';

  @override
  String get callForHours => 'Güncel saatler için arayın';

  @override
  String get getInTouch => 'İletişim';

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }
}
