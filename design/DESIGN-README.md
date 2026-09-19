# Pape Mosque — iOS tasarım teslim notları

Bu dosya, tasarım koda dökülmeden önce okunmak için yazıldı. Aynı içerik tuvalde
`Teslim notları — README` artboard'unda da duruyor; orası görsel, burası repo içindir.

Hedef: iPhone, yalnızca dikey, açık tema. Sistem fontu (SF Pro). Marka yeşili merkezde,
altın yalnızca Cuma ve Bayram için ayrıldı.

---

## 1. Yapı — üç sekme

Uygulama üç sekmeye oturdu. Sekme sayısını az tutmak bilinçli bir karar: Wealthsimple
kadar içerik taşıyan uygulamalar bile üç sekmeyle idare ediyor.

**Prayer** uygulamanın kalbi. Kullanıcı uygulamayı on kez açıyorsa dokuzunda burayı
açıyor. Bugünün altı vakti (beş namaz + güneş), athan ve iqamah saatleri, bir sonraki
vakte geri sayım, Cuma ve Bayram kartı, hatırlatma anahtarı. Ayrı bir "günlük vakitler"
ekranı yok — ana ekranın kaydırması zaten o liste. Bu hem dürüst (gelecek veri yok) hem
de ekranı dolduran şey.

**Community** etkinlik ve duyuruyu tek listede, segmentli kontrolle tutuyor. Kullanıcı
açısından ikisi aynı şeydir: "cami bana ne söylüyor". Ayrı sekmelere bölmek, çoğu zaman
boş olan iki sekme demekti.

**Profile** hesap ve ayarlar. Oturum açık ya da kapalı olsun her hâlde dolu — ayarlar
hesaptan bağımsız var.

Cami bilgisi ayrı sekme almadı. Yeni gelen bir kez bakar, bir daha bakmaz; navigasyonun
üçte birini buna harcamak israf olurdu. Namaz sekmesinin altında kısa bir kart, Profile
içinde tam bir sayfa olarak duruyor.

---

## 2. Renk

```
--hero        #10412F   hero gradient tabanı
--action      #0E7550   buton, aktif sekme, NOW rozeti
--action-dark #0C5B3E   basılı hâl, koyu metin yeşili
--ground      #EEF1EF   sayfa arka planı
--card        #FFFFFF
--ink         #0F1C17   birincil metin
--ink-2       #4E5F58   ikincil metin
--ink-3       #67766F   açıklama metni (4.83:1, bundan açığa gitme)
--hairline    #EFF3F1
--secondary   #3C6E96   güneş doğuşu, duyuru işareti
--gold-text   #8A6516   YALNIZCA Cuma ve Bayram
--gold-bg     #F8F1DF
--danger      #A8332A   hesap silme
```

Hero gradient:

```css
background-image: linear-gradient(148deg, #135442 0%, #0F4538 56%, #072A26 100%);
```

Gradient tek bir yeşilin ton aralığında kalır. İkinci bir renge (maviye, altına) geçen
gradient kullanma — markayı dağıtır. Alttaki uç 148 derecede hafifçe teale kayar, bu
kasıtlı; renk değişimi değil, ton kayması.

---

## 3. Yüzey, tipografi, dokunma

Köşe yarıçapı: hero 28, kart 26, liste kartı 24, iç satır 16, hap 999.

Gölge iki katmanlıdır, tek katmanlı sert gölge kullanma:

```css
/* kart */  0 1px 2px rgba(10,50,34,.05), 0 12px 30px -10px rgba(10,50,34,.14)
/* hero */  0 2px 6px rgba(8,40,28,.18), 0 22px 46px -14px rgba(8,40,28,.45)
```

Boşluk: sayfa kenarı 20, kartlar arası 14–18, kart içi 18–20.

Tipografi sistem fontu üzerinden: büyük başlık 24–34/700, kart başlığı 16.5–17/700,
gövde 14.5/400, liste satırı 15.5/600, açıklama 12.5/400. Saatlerde `tabular-nums`
şart, yoksa geri sayım her saniye zıplar.

Koyu yeşil kart üzerinde renkli vurgu yok. Hiyerarşi opaklıkla kurulur: %100 / %80 /
%78. Yeşil zeminde yeşil vurgu yapmak rengi iki kez söylemektir.

Dokunma alanı en az 44px; segmentli kontrol 40. Sahte durum çubuğu veya sahte klavye
çizilmedi — üst 59px kasten boş bırakıldı, gerçek cihazda sistem oraya kendi çubuğunu
koyacak.

---

## 4. Veri gerçekleri — tasarımı bunlar belirledi

Aşağıdakiler estetik tercih değil, veri kısıtı. Koda dökerken bunlara uyulmazsa
tasarım bozulur.

**Sekme çubuğu ada (floating island).** Ekranın altına yapışık tam genişlikte bir bar
değil: 16px kenar boşluğu bırakan, 64px yüksekliğinde, 32px yarıçaplı, buzlu cam bir
hap. Sebebi tutarlılık — ekrandaki her şey yüzen yuvarlak bir kart, tam genişlikte bir
bar bu dilin dışında kalıyordu. İçerik adanın altından ve iki yanından akar, bu yüzden
liste ve kaydırma alanlarının sonuna 96px alt boşluk bırak, yoksa son kart adanın altında
kalır. Flutter tarafı: `Scaffold(extendBody: true)` + `bottomNavigationBar` içinde
`SafeArea`, `ClipRRect(borderRadius: 32)` ve `BackdropFilter(ImageFilter.blur(24, 24))`.

**Gradient yeşil yalnızca sekme köklerinde.** Prayer, Community ve Profile'ın kök
ekranlarında gradient bir kart var ve orada canlı içerik taşıyor: geri sayım, sıradaki
etkinlik, kimlik kartı. İçeri itilen ekranlar — giriş, kayıt, ayarlar, hesap silme,
etkinlik ve duyuru detayları, cami sayfası — düz iOS başlık çubuğu alır: açık zemin,
yuvarlak beyaz geri butonu, koyu başlık, yeşil sadece küçük üst etikette. Yalnızca bir
geri butonu ve bir başlık taşıyan yeşil bant dekorasyondur, yerini hak etmez; ayrıca her
ekranda kullanılırsa sekme köklerindeki yeşil de özel olmaktan çıkar.

**Gelecek namaz verisi yok.** Yalnızca bugün ve geçmiş günler var. Bu yüzden aylık ya da
yıllık takvim bilerek tasarlanmadı — veri gelene kadar da tasarlanmasın. Bugün kahraman
içerik. Sunucu haftalık veriyi verebilir hâle gelirse haftalık görünüm sonradan eklenir.

**Etkinlik ve duyuru çoğu zaman boş olabilir.** Ana ekran sıfır etkinlik ve sıfır
duyuruyla da dolu görünmek zorunda. Çözüm dekoratif dolgu değil: namaz içeriği — hero,
altı satır, hatırlatma satırı, Cuma kartı — ekranı zaten dolduruyor, topluluk bölümü
katlanarak küçülüyor ve kaybolduğunda ekranda delik bırakmıyor.

**Boş durum bir özür değil, bir karttır.** "Hiçbir şey yok" metninin altında çalışan bir
bildirim anahtarı var; ekran ölü bitmiyor. Gri kutu, kırık görsel ikonu, "veri yok"
yazısı kullanma.

**Fotoğraf bir katmandır, içerik değil.** Tarih, saat, yer ve başlık her zaman metin
alanlarından gelir. Görsel varsa kartın üstüne bant olarak eklenir; yoksa kart doğrudan
tarih rozetiyle başlar. Fotoğrafsız kart eksik değil, ayrı ve tamamlanmış bir tasarımdır.
Tutarsızlık yokluktan beterdir — yedi etkinlikten üçünde fotoğraf varsa liste bozuk
görünür, bu yüzden iki kart varyantı da bitmiş olmalı.

**Afiş yüklense bile alanlar doldurulmalı.** Cemaat afişlerinde bütün bilgi görselin
içine gömülüdür. Bunu kabul edersen TR/EN çevirisi imkânsız olur, ekran okuyucu
okuyamaz, arama çalışmaz, küçük ekranda yazı okunmaz. Afiş görsel olur, bilgi
alanlardan gelir.

**En boy oranını sunucu dayatır, merkezden kırpar.** Yükleyenin oranı layout'u
belirlemesin. Stok cami görseli kullanma — yalnızca gerçek fotoğraf veya cemaatin kendi
afişi. Aksi hâlde uygulama o an sahte hissettirir.

**Duyurularda görsel yok.** Duyuru metinsel bir bildirimdir (otopark kapalı, ofis
saatleri değişti). Görsel eklemek onu etkinlikten ayırt edilemez yapar; bu ayrımın
kendisi bilgi taşıyor.

**TR/EN sonradan gelecek.** Bütün metin alanlardan gelmeli, hiçbiri görsele veya ikona
gömülü olmamalı. Tarih ve saat biçimleri de yerelleştirilebilir olmalı.

**Altın yalnızca Cuma ve Bayram için.** Başka hiçbir yerde kullanma, yoksa özel gün
sinyali kaybolur.

**Erişilebilirlik.** Metin kontrastı en az 4.5:1 (24px üstü için 3:1). En sık hata yapılan
iki yer: açık gri açıklama metni ve beyaz yazılı renkli dolgular. İkonlu butonlara
`aria-label` ver. `div`'e `onClick` koyma — gerçek `button`, `a`, `input` kullan, yoksa
Tab atlar ve ekran okuyucu okuyacak bir şey bulamaz.

---

## 5. Yer tutucular

Uydurulmadı, gerçek veriyle doldurulacak:

`[STREET ADDRESS]`, `[POSTAL CODE]`, `[PHONE NUMBER]`, `[EMAIL ADDRESS]`, `[WEBSITE]`
— caminin gerçek bilgileri.

`[EVENT PHOTO]`, `[MAP]` — yerleşim ve oran doğru, içerik gerçek varlıkla değişecek.

**Hicri tarih yok.** Yaklaştırmak yerine hiç koymadım; bir namaz uygulamasında yanlış
hicri tarih gerçek bir hatadır. Doğru kaynaktan gelince başlığın altına ikinci satır
olarak eklenir.

**Namaz saatleri örnek.** Eylül sonu Toronto için makul değerler; gerçek API verisiyle
değişecek.

**Mock gün Çarşamba seçildi** ki hem normal gün hero'su (yeşil) hem de Cuma kartı
(altın) aynı ekranda görünsün.

---

## 6. Ekran envanteri

Prayer: ana ekran (cihazda), ana ekran (tam kaydırma), ana ekran (içerik yokken).

Community: etkinlikler, duyurular, boş durum, etkinlik detayı, kayıt formu, kayıt
onayı, duyuru detayı.

Profile: çıkış yapılmış, giriş yapılmış, giriş, kayıt ol, ayarlar, hesap silme,
cami ve iletişim.

Ayrıca: sekme çubuğu çalışması ve bu teslim notları.
