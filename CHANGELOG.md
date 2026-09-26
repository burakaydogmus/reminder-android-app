# Değişiklik Günlüğü

Bu projedeki önemli değişiklikler bu dosyada tutulur.

Biçim [Keep a Changelog](https://keepachangelog.com/tr-TR/1.1.0/) esas alınarak hazırlanır; sürüm
numaraları [Semantik Sürümleme](https://semver.org/lang/tr/) izler. Mevcut `pubspec.yaml` sürümü
`2.1.0+8`; mağazaya ilk yayında sürüm numarası F6.2 kapsamında belirlenecek.

## [Yayınlanmadı]

### ⚠️ Uyumsuz değişiklik

- **Paket kimliği değişti:** Android `applicationId` / `namespace` ve iOS bundle ID artık
  `com.burakaydogmus.reminder` (önceki: `com.fabirt.reminder`). İşletim sistemi bunu **yeni bir
  uygulama** olarak görür: eski kimlikle kurulu uygulamanın üzerine güncelleme olarak kurulmaz,
  **veriler eski uygulamadan taşınmaz**. Eski sürümdeki kayıtlar yeni sürüme elle aktarılmalıdır
  (eski sürümde yedekleme özelliği olmadığı için gerekirse yeniden girilmelidir). (#10)

### Eklendi

- **Gerçek emülatörde uçtan uca testler (F0.4):** `integration_test/` + `E2E (Android emulator)`
  iş akışı, uygulamayı gerçek bir Android emülatöründe (API 34, KVM, önbelleklenmiş AVD
  snapshot'ı) başlatıp sürüyor. Buraya kadarki ~2750 test Dart test ana bilgisayarında
  çalışıyordu: orada `Platform.isAndroid` `false`, bildirim eklentisi sahte, SQLite bellekte ve
  `home_widget` bir kabuk — yani **platform bütünleşmelerinin hiçbiri gerçekte hiç
  çalışmamıştı**. Artık çalışıyor: soğuk açılışta veritabanının cihazda oluşması ve onboarding'in
  tamamlanması, arayüzden eklenen hatırlatıcıların `sqlite3` dosyasına yazılması ve **uygulama
  gerçekten yeniden başlatıldıktan sonra** geri okunması, bildirimlerin işletim sistemine
  kurulduğunun `pendingNotificationRequests()` ile doğrulanması (tek seferlik, tekrarlayan,
  doğum günü; tam zamanlı alarm izni hem verilmiş hem verilmemişken), ana ekran widget'ı
  verisinin gerçek depoya yazılması, yedek al → sıfırla → geri yükle turunun gerçek dosya
  sistemi üzerinde dönmesi, `reminderwidget://` bağlantılarının doğru ekranı açması ve bir
  rutinin uygulanınca gerçek hatırlatıcı + gerçek alarm üretmesi. Native tarafta ayrıca
  kısayolların ve widget sağlayıcılarının gerçekten yayımlandığı, derin bağlantı intent'lerinin
  uygulamaya ulaştığı adb ile doğruluyor. Kullanıcıya görünen bir değişiklik yok; mevcut test
  paketine dokunulmadı. Emülatör işi dokümana özel PR'ları yavaşlatmıyor (yol filtreleri),
  gecelik de çalışıyor. Kapsam ve kapsam dışı kalanlar: `CLAUDE.md` → **End-to-end tests**.

- **İmzalı GitHub Release ve telefonda otomatik güncelleme:** Elle tetiklenen `Release APK` iş
  akışı, mimari başına sabit adlı APK'ları (`reminder-arm64-v8a.apk` …) imzalayıp doğruluyor ve
  `v<sürüm>+<numara>` etiketiyle release açıyor. `versionCode` artık tarihten üretiliyor
  (`date -u +%y%m%d%H`); önceden `pubspec.yaml`'daki sabit `+8` yüzünden her derleme aynı
  numarayı taşıyor ve hiçbir güncelleyici iki derlemeyi ayırt edemiyordu. Telefonda
  [Obtainium](https://github.com/ImranR98/Obtainium) release'leri izleyip güncellemeyi kuruyor
  (veriler korunur, imza aynı); kurulum [`docs/updates.md`](docs/updates.md). Release derlemesi,
  debug anahtarına **düşmek yerine hata veriyor** — kurulamayan bir release yayınlamaktansa
  hiç yayınlamamak iyidir. Artifact'lar 7 günde silindiği için eski sürümler de artık kalıcı.

- **Rutinler (hatırlatıcı şablonları):** Listeler sekmesindeki "Rutinlerim" bölümünde hazır
  paketler kurabiliyorsun: "Sabah rutini" = spor 07:00 + vitamin 07:30 + su (saatsiz). Rutine
  dokunmak onu seçtiğin güne uygular, yani adımlarından **gerçek hatırlatıcılar** oluşturur;
  varsayılan gün bugün, istersen başka bir gün seçiyorsun. Her adımın başlığı, isteğe bağlı saati,
  kategorisi, önceliği ve kendi maddeleri var; saat vermediğin adım, editörde "Zamanla ve bildir"
  kapalı bir hatırlatıcı gibi zamansız oluyor (Bugün bir ara).
  **Otomatik uygulama:** rutine "Her gün" ya da "Seçili günler" verdiğinde saatli adımları
  tekrarlayan hatırlatıcı olarak oluşuyor; sonraki günleri işletim sistemi kendi bildirim
  tekrarıyla getiriyor — uygulamanın arka planda çalışmasına gerek yok, bu yüzden "bazı sabahlar
  gelmedi" durumu yaşanmıyor. Saatsiz adımlar tekrar etmiyor (zamansız hatırlatıcı bildirim
  kurmaz).
  **Kopya koruması:** aynı rutini aynı gün için ikinci kez uygulamaya çalışırsan sessizce
  kopyalanmıyor: "Bugün bu rutini zaten uyguladın" uyarısıyla ya yalnızca yeni adımlar ekleniyor,
  ya (tekrarlayan rutinlerde) var olan hatırlatıcılar seçtiğin güne taşınıyor, ya da "Yine de
  hepsini ekle" ile bilerek ikinci set oluşturuluyor. Rutini silmek daha önce oluşturduğu
  hatırlatıcılara dokunmuyor; rutini düzenlemek de eski hatırlatıcıları geri dönük değiştirmiyor.
  Rutinler yedeklere de giriyor (aşağıdaki "Değişti" notuna bakın).

- **Rehberden doğum günü aktarma:** Doğum günleri sayfasındaki yeni **"Rehberden aktar"**
  düğmesi rehberindeki doğum günlerini elle yazmaktan kurtarıyor. Rehber **bir kez** okunuyor;
  doğum günü olan kişiler ad, tarih ve yıl bilinmiyorsa "yıl bilinmiyor" notuyla listeleniyor,
  seçtiklerin listeye ekleniyor. Hiçbir satır seçili başlamıyor — "Tümünü seç" bir dokunuş.
  Listede **zaten eklediğin** bir doğum günü varsa "zaten ekli" yazıp seçilemez oluyor, yani ikinci
  bir kayıt oluşmuyor ve satır sessizce kaybolmuyor (ad karşılaştırması Türkçe İ/ı kurallarına göre,
  `İLKAY` = `ilkay`). Aktarma bitince özet sayfası neyin eklendiğini ve neyin atlandığını
  gösteriyor, kapanınca sayılar bildirim çubuğunda tekrarlanıyor. Yılsız doğum günleri gerçekten
  yılsız aktarılıyor (yaş gösterilmez); aktarılanlar uygulamanın varsayılan bildirim saatini ve
  önbildirimlerini alıyor.
  **Rehberine hiçbir şey yazılmaz:** Android'de yalnızca `READ_CONTACTS` izni isteniyor,
  `WRITE_CONTACTS` hiç tanımlı değil; yalnızca ad ve tarih saklanıyor — kişi kimliği, fotoğraf,
  telefon ve e-posta hiç okunmuyor. İzin vermezsen (ya da sonradan geri alırsan) sayfa ne
  yapacağını anlatıp Ayarlar'a götürüyor; doğum günlerini elle eklemeye devam edebilirsin. (F7.3)
- **Mimari başına APK (CI):** Android iş akışı artık `--split-per-abi` ile derliyor ve iki
  artifact yüklüyor — `app-release-arm64-apk` (**indirilecek olan**, ~25 MB) ve armeabi-v7a +
  x86_64 için `app-release-other-abis-apk`. Önceden tek bir 76 MB'lık paket vardı ve içindeki
  üç mimariden ikisi her telefonda gereksizdi. İmza kontrolü her APK için ayrı yapılıyor.
  Flutter split'lere mimariye göre `versionCode` kaydırması verdiği için bir cihazda **aynı
  varyantta kalmak** gerekir (arm64 → tek parça APK'ya dönüş, Android'in engellediği bir sürüm
  düşürmesidir). Bkz. [`docs/android-signing.md`](docs/android-signing.md).

- **Cihaz takvimi etkinlikleri (salt okuma):** Cihazının takvimindeki etkinlikler artık Bugün
  ("Takvim etkinlikleri" bölümü) ve Takvim gündeminde hatırlatıcılarının yanında görünüyor.
  Etkinlik satırları hatırlatıcılardan ayrışıyor: soldaki renk şeridi, takvim ikonu ve "takvim
  etkinliği" yazan alt satırıyla; **tamamlanamaz, kaydırılamaz, düzenlenemez.** Tüm gün süren
  etkinlikler "Tüm gün" olarak, çok günlü olanlar gün aralığıyla gösteriliyor; tekrarlayan
  etkinlikler her tekrarında ayrı satır oluyor.
  **Varsayılan kapalı.** Ayarlar › "Takvim etkinlikleri" anahtarı açar; açarken takvimi yalnızca
  okuduğumuzu anlatan bir sayfa gösterilir ve izin bir kez istenir. Açıldıktan sonra hangi
  takvimlerin gösterileceğini tek tek seçebilirsin (kişisel, iş, tatiller, doğum günleri…);
  seçim saklanır. Etkinliğe dokunmak onu cihazın kendi takvim görünümünde açar; açılamazsa
  salt-okunur bir ayrıntı sayfası gelir. Satırın ⋮ menüsündeki **"Hatırlatıcı oluştur"**
  hatırlatıcı düzenleyicisini etkinliğin başlığı ve saatiyle doldurur — bu yalnızca uygulamanın
  kendi listesine yazar.
  **Takvimine hiçbir şey yazılmaz:** Android'de yalnızca `READ_CALENDAR` izni isteniyor,
  `WRITE_CALENDAR` hiç tanımlı değil. İzni geri alırsan anahtar kendiliğinden kapanır ve boş bir
  bölüm kalmaz. (F8.1)
- **"Tamamlandıktan sonra" tekrar:** Tekrar sayfasına **Tekrar ölçütü** seçimi geldi —
  *Takvime göre* (bugüne kadarki davranış: tarihler sabit, geç tamamlamak sıradakini
  kaydırmaz) ya da *Tamamlandıktan sonra*. İkincisinde sıradaki tekrar **tamamladığın
  günden** sayılır: "çarşafları yıkadıktan 14 gün sonra". 10:00'a kurulu 14 günlük bir
  hatırlatıcıyı ayın 3'ünde 23:40'ta tamamlarsan sıradakisi 17'si **10:00** olur —
  hatırlatıcının kendi saati korunur. Gün, hafta, ay ve yıl aralıklarıyla (1–99)
  çalışıyor, bitiş tarihi de verilebilir. Tamamlamadıkça hatırlatıcı **yerinde kalır ve
  gecikir** (özelliğin amacı bu); "Hepsini yarına al" tekrarlayanları zaten atlıyor.
  Bu modda haftanın günleri ve ayın günü anlamsız olduğu için gizlenir; Takvim sayfası
  **yalnızca mevcut tekrarı** gösterir (ileriki tarihler henüz belli değil, tahmin
  gösterilmez) ve bildirimi işletim sisteminin kendi tekrarı yerine her tamamlamadan
  sonra yeniden kurulur.
  **Geriye dönük uyumluluk:** ölçüt, hatırlatıcının JSON'unda **ek bir alan** olarak
  saklanır, bu yüzden **bu değişikliği bilmeyen eski bir sürüm** (ya da eski bir yedek
  okuyucusu) alanı yok sayar: tekrar çalışmaya devam eder ama **takvime göre** — artık
  tamamlama tarihini takip etmez. Tek istisna *aylık* ölçüt: eski okuyucu ayın gününü
  beklediği ve bu modda böyle bir gün olmadığı için o hatırlatıcı tekrarını kaybeder
  ("Tekrar yok" olur); hatırlatıcının kendisi, saati ve maddeleri her durumda korunur.
  Veritabanı şeması değişmedi (`reminders.recurrence` zaten nullable TEXT), yedek biçimi
  (v2) aynı kaldı ve kurulu bildirimler yeniden kurulmadı. (F3.1c)
- **CI'da kalıcı imzalama (kişisel kullanım):** `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` ve `ANDROID_KEY_PASSWORD` gizli
  değişkenleri tanımlıysa Android iş akışı `android/key.properties` dosyasını üretir ve
  release APK'yı o anahtarla imzalar; artifact adı `app-release-apk` olur ve APK'yı imzalayan
  sertifika koşu kaydına yazılır. Böylece her CI koşusundan indirilen APK öncekinin **üzerine
  güncelleme olarak** kurulur — gizli değişkenler yokken her koşucu kendi debug anahtarını
  üretiyordu ve imzalar uyuşmadığı için cihazda uygulamayı silmek (yani veriyi kaybetmek)
  gerekiyordu. Kurulum: [`docs/android-signing.md`](docs/android-signing.md). Gizli değişkenler
  tanımsızsa davranış eskisi gibi (debug anahtarı, uyarı).

- **Yıllık tekrar ("Her yıl"):** Tekrar sayfasına **Yıllık** seçeneği geldi — "Her yıl",
  "2 yılda bir" … (99'a kadar) ve istenirse bitiş tarihi. Tekrar, hatırlatıcının kendi
  ay/gününde çalışır; **29 Şubat'a kurulu bir tekrar, artık yıl olmayan yıllarda 28 Şubat'ta**
  hatırlatır (doğum günleriyle aynı kural). Hızlı yakalama iki dilde de anlıyor: "her yıl",
  "her sene", "yıllık", "senelik", "2 yılda bir", "iki senede bir" / "every year", "yearly",
  "annually", "every 2 years", "every other year". Bir isimden önce gelen "yıllık" / "yearly"
  metin olarak kalır ("yıllık rapor hazırla", "yearly budget review"); "annually" her zaman
  tekrar sayılır.
  **Geriye dönük uyumluluk:** tekrar kuralı hatırlatıcının JSON'unda saklanır ve okuma bilerek
  toleranslıdır — **yıllık tekrarı tanımayan eski bir sürüm** (ya da eski bir yedek okuyucusu)
  böyle bir hatırlatıcıyı açar ama **tekrarını kaybeder** ("Tekrar yok" olur); hatırlatıcının
  kendisi, saati ve maddeleri korunur. Veritabanı şeması değişmedi (`reminders.recurrence`
  zaten nullable TEXT) ve yedek biçimi (v2) aynı kaldı. (F3.1)
- **iOS ana ekran ve kilit ekranı widget'ları:** Dört widget geldi — **Sıradaki** (küçük: saat,
  başlık, tamamla dairesi, "+"), **Bugün** (orta: "Bugün · N" + üç satır + hap "+"), **Liste**
  (büyük: Kaçanlar / Bugün bölümleri, doğum günü satırı; uzun basıp "Yalnızca bugün"ü
  kapatabilirsin) ve **Kilit ekranı** (daire: bugünün açık iş sayısı; dikdörtgen ve satır:
  sıradaki iş). Daireye dokunmak hatırlatıcıyı tamamlar, satır anında kaybolur; "+" hızlı
  yakalamayı, satır hatırlatıcının kendisini, doğum günü satırı Doğum günleri'ni açar. Metinler
  uygulamanın dilini (Türkçe / English) izler, tonlu (tinted) ve koyu modlarda monokrom çizilir.
  Widget'lar iOS 17 ve üstünü gerektirir; uygulama iOS 15'te çalışmaya devam eder.
  **Sınır:** widget'tan tamamlanan bir hatırlatıcının bildirimi, uygulama bir kez açılana kadar
  iptal edilmez (Android'de anında olur). (F5.2)
- **Hızlı yakalamada İngilizce doğal dil:** Uygulama İngilizceyken yakalama alanı artık
  İngilizce yazılanları da anlıyor: "tomorrow at 9", "every monday", "in 2 hours",
  "next friday 18:00", "#groceries bread, milk and eggs", `!` öncelik, `@yer`. Gramer
  **uygulama diline** göre seçilir (Ayarlar › Görünüm › Dil), cihaz diline göre değil;
  Türkçe davranışı aynen korundu. Alanın altındaki not artık "yalnızca Türkçe" uyarısı
  yerine o dildeki örnek cümleleri gösteriyor. Sayısal tarihler İngilizcede ay/gün
  okunur (`5/3` = 3 Mayıs), noktalı biçim saattir (`9.30`). "every year" / "yearly"
  henüz desteklenmiyor (uygulamada yıllık tekrar türü yok, Türkçede "her yıl" da metin
  olarak kalıyor). (F4.6c)
- **Maddede "Geri al":** Hatırlatıcı düzenleyicisindeki "Maddeler" kartında bir maddeyi silince
  artık "“Süt” silindi · Geri al" çubuğu çıkıyor; geri alınca madde eski sırasına dönüyor,
  bu arada yaptığın düzenlemeler korunuyor. (F6.4)
- **iOS bildiriminde maddeler:** Açık maddeler Android'de olduğu gibi artık iOS bildiriminde de
  görünüyor (başlığın altında tek satır: "Süt · Ekmek · … ve 2 madde daha"). Güncellemeden sonra
  kurulu bildirimler bir kez yeniden kurulur. (F6.4)
- **Tamamlandı animasyonu:** Bir hatırlatıcı tamamlanınca başlığın üstündeki çizgi soldan sağa
  çiziliyor (Reduce Motion / animasyonlar kapalıyken anında son hâlini alıyor). (F6.4, §3.5)
- **İngilizce dil desteği:** Uygulama Türkçe ve İngilizce. Varsayılan olarak cihaz dilini izler
  (Türkçe cihazda Türkçe, diğer tüm dillerde İngilizce); Ayarlar › Görünüm › **Dil** ile
  Sistem / Türkçe / English seçilebilir, seçim anında uygulanır ve saklanır. Tarihler ve saatler
  seçilen dilde yazılır (Türkçe büyük harf kuralları korunur: "BUGÜN · PAZARTESİ"). Bildirimler,
  bildirim düğmeleri, konum bildirimleri, doğum günü bildirimleri, Android widget'ları ve
  uygulama simgesi kısayolları da aynı dildedir; dil değişince bekleyen bildirimler yeni dilde
  yeniden kurulur. Android 13+ uygulama dili ayarı ve iOS'ta konum izin metinleri (tr/en) de
  desteklenir. (F6.1)
- **Uygulama simgesi kısayolları:** Uygulama simgesine uzun basınca (Android kısayolları, iOS
  hızlı işlemleri) dört seçenek çıkar: **Yeni hatırlatıcı** hızlı yakalamayı açar, **Market
  listesi** hızlı yakalamayı `#market ` yazılı açar (yalnızca maddeleri yaz), **Bugün** Bugün
  sekmesine döner, **Yeni doğum günü** doğum günü ekleme sayfasını açar. Uygulama kapalıyken de
  çalışır; ilk açılışta tanıtım bitince hedef açılır. (F5.3)
- **Özel kategoriler:** Listeler › Kategorilerim'de "+ Yeni kategori" ile kendi kategorini
  oluştur: ad (en fazla 24 karakter), 12 renkten biri ve 18 ikondan biri, canlı önizlemeyle.
  "Düzenle" ile kategorileri sürükleyerek (ya da ekran okuyucunun "Yukarı/Aşağı taşı"
  eylemleriyle) sırala; kendi kategorilerini düzenle veya sil — silinen kategorinin
  hatırlatıcıları onaydan sonra "Diğer"e taşınır. Hatırlatıcı düzenleyicisindeki kategori
  chip'leri artık tüm kategorileri senin sıranla gösterir ve "+ Yeni" ile oradan da kategori
  eklenir; aramanın kategori filtresi ve takvim noktaları kendi kategorilerini de tanır. Hızlı
  yakalamada `#spor` kendi "Spor" kategorine eşleşir; bilinmeyen `#etiket` chip'ine dokununca
  kategori o adla oluşturulur. **Geçiş:** eski "Diğer + özel ad" kayıtları her farklı ad için
  (büyük/küçük harf ve Türkçe karakter farkı gözetmeden) bir kategoriye dönüşür (renk: Diğer,
  ikon: etiket); eski ad veritabanında korunur. Yedek biçimi sürüm 2 (kategoriler dahil); sürüm
  1 yedekler de aynı kuralla içe aktarılır. (F4.3)
- **Dört Android widget'ı:** **Bugün** (4×2: "Bugün · N", ilk iki iş, sağ üstte "+" hap),
  kaydırılabilir **Liste** (4×4, 3×3–5×6 arası boyutlanır: Kaçanlar, Bugün, Doğum günü, Sonra;
  8 satır sınırı kalktı), **Sıradaki** (2×2: sıradaki işin saati ve başlığı, "+N daha") ve
  **Hızlı ekle** (1×1, yalnız "+"). Daireye dokunmak uygulamayı açmadan tamamlar (tekrarlayanlar
  sonraki tarihe geçer), satıra dokunmak hatırlatıcıyı, doğum günü satırı Doğum günleri'ni, "+"
  hızlı yakalama sayfasını açar. Bildirimler kapalıysa "Bildirimler kapalı — açmak için dokun" şeridi
  Ayarlar'a götürür. Android 12+'da sistem dinamik renkleri ve köşe yarıçapı, koyu tema desteği;
  "Gecikti", "Yarın" ve bölümler uygulama açılmadan saat geçtikçe güncellenir. Ana ekrandaki
  eski widget kendiliğinden Liste olur. Ayarlar › "Widget ekle" dört widget'tan birini seçtirir.
  (F5.1)
- **Hızlı yakalama:** "cuma 18:00 ekmek ve süt al #market !!" gibi yazman yeterli. Android'de
  "+" düğmesi, iOS'ta sekme çubuğunun üstündeki cam **"Ne hatırlatayım?"** çubuğu hızlı ekleme
  sayfasını açar; tanınan tarih/saat, tekrar, `#kategori`, `!` öncelik ve `@yer` metnin içinde
  renklenir ve altta chip olarak görünür (chip'e dokununca seçici açılır, "×" o kelimeyi düz
  metne çevirir). Enter ya da ↑ kaydeder; alan temizlenir, sayfa açık kalır ve üstte
  "Eklendi: … · Geri al" görünür. `#market` listelerinde "Maddelere böl?" önerisi, geçmiş
  saatte uyarı ve "Yarın 09:00 mı?" önerisi, "Tüm ayrıntılar" ile dolu gelen tam düzenleyici.
  Bilinmeyen `#etiket` şimdilik "Diğer"e eklenir; `@yer` nota yazılır (konum bildirimi kurmaz).
  Uzun basınca: Hızlı ekle / Hatırlatıcı / Doğum günü. (F4.6b)
- **Hareket ve titreşim:** kartın tamamlama dairesi dokununca hafifçe basılıyor, 9 dilimli
  "kurabiye" şekline dönüşüp kategori rengiyle doluyor ve ✓ çiziliyor; kart yanlış dokunuşu fark
  etmen için 0,9 sn yerinde bekledikten sonra tamamlanıyor (bu sürede tekrar dokunmak iptal
  eder, "Geri al" her zamanki gibi çalışır). Sekme geçişleri yumuşak bir geçişle, düzenleyici
  yay (spring) hareketiyle açılıyor. Ayarlar › Görünüm'de **"Titreşim geri bildirimi"** anahtarı
  (varsayılan açık): tamamlama, kaydırma eşiği, geri alma, silme ve madde sıralamada kısa
  titreşimler. "Hareketi azalt" açıkken şekil dönüşümü ve bekleme olmadan kısa bir geçişle
  tamamlanır. (F4.7)
- **MIT lisansı eklendi** (kökte `LICENSE`, "Copyright (c) 2026 Burak Aydoğmuş"); üçüncü taraf
  atıfları `docs/store/licensing.md`'de. (#27)
- **Öncelik ve sabitleme:** editörde "Öncelik" seçimi (Yok / Düşük / Orta / Yüksek) ve üst
  çubukta 📌 sabitleme düğmesi. Sabitlenen hatırlatıcılar listelerin en üstünde; aynı saatteki
  ve zamansız hatırlatıcılar önceliğe göre sıralanır. Kartta sabitleme simgesi ve "!!! Yüksek"
  işareti, yüksek öncelikte onay dairesinde halka; uzun basma menüsünde ve ekran okuyucu
  eylemlerinde "Sabitle / Sabitlemeyi kaldır". Veritabanı şeması v4'e geçti (otomatik taşıma);
  yedekler iki alanı da içerir, eski yedekler öncelik yok / sabitlenmemiş olarak yüklenir. (F3.4)
- **Alt görevler (maddeler):** hatırlatıcıya madde listesi (ör. market listesi); editörde
  "Maddeler" kartı: ilerleme çubuğu, satır içi düzenleme, sürükleyerek veya menüden sıralama,
  çok satırlı yapıştırmayla toplu ekleme, "Tamamlanan N madde" bölümü. Kartta "2/6" ilerlemesi,
  bildirimde "N madde kaldı" (Android'de açık maddeler listelenir). Tekrarlayan hatırlatıcı bir
  sonraki tekrara geçerken maddeler sıfırlanır. Veritabanı şeması v3'e geçti (otomatik taşıma);
  yedekler maddeleri içerir. (F3.3)
- **Tekrarlayan hatırlatmalar:** günlük, haftalık (gün seçimiyle), aylık veya her N günde bir;
  isteğe bağlı bitiş tarihi. Tekrarlayan bir hatırlatıcı tamamlanınca bir sonraki tekrara geçer;
  kartta tekrar özeti görünür. Veritabanı şeması v2'ye geçti (otomatik taşıma). (#25)
- **Bildirim eylemleri:** hatırlatıcı bildiriminden doğrudan Tamamla ve Ertele (10 dk, 1 saat;
  iOS'ta ayrıca yarın sabah), uygulama kapalıyken de çalışır. Bildirime dokununca ilgili
  hatırlatıcı açılır. (#23)
- **Mağaza hazırlık dokümanları:** gizlilik politikası (tr/en), Play Data safety ve App Store
  gizlilik etiketi cevapları, izin ve politika incelemesi, mağaza metni taslakları, lisans notu
  (`docs/store/`). (F6.2a)
- **Yedekleme:** hatırlatıcıları, doğum günlerini ve ayarları sürümlü bir JSON dosyasına dışa
  aktarma (sistem paylaşım menüsü) ve dosyadan birleştirerek ya da değiştirerek geri yükleme. (#24)
- **Tanıtım (onboarding):** ilk açılışta 4 adımlı tanıtım; bildirim izni yalnızca açıklamayla,
  bağlam içinde istenir. Mevcut verisi olan kullanıcılar tanıtımı görmez. (#22)
- **Kaydırma eylemleri:** kaydırarak tamamla, ertele veya sil; her eylem için "Geri al"; aynı
  eylemler uzun basma menüsünde ve ekran okuyucu eylemlerinde. (#21)
- **Ayarlar → İzinler:** bildirim, tam zamanlı alarm ve konum izinlerinin canlı durumu; eksik izin
  için Bugün ekranında uyarı ve editörde satır içi uyarı. (#18)
- **Kor tasarım sistemi:** renk, tipografi, şekil, boşluk ve hareket token'ları; açık/koyu tema;
  Google Sans Flex değişken yazı tipi; kontrast testleri. (#8)
- **Yeni gezinme:** Bugün / Takvim / Listeler sekmeleri, Ayarlar dişli simgesinde. (#12)
- Birim, bloc ve widget test altyapısı; biçim denetimi. (#3)
- CI iş akışı, PR şablonu ve katkı rehberi (`CLAUDE.md`). (#2)
- Geliştirme yol haritası ve "Kor" tasarım yönü dokümanı. (#1, #4)

### Değişti

- **Yedek dosyası artık rutinleri de taşıyor** (JSON'daki `routines` anahtarı ve hatırlatıcıdaki
  `routineId` / `routineItemId` alanları). Biçim sürümü **2'de kaldı**: eklenen alanlar ek
  niteliğinde olduğu için **eski bir uygulama sürümü bu dosyayı yine açabiliyor** — yalnızca
  rutinleri yok sayıyor, hatırlatıcı/doğum günü/kategori/ayar verisinin tamamını olduğu gibi
  alıyor. Eski (sürüm 1 ve 2) yedekler de değişmeden içe aktarılıyor. Veritabanı şeması v7'ye
  çıktı (rutin tabloları); yükseltme mevcut verilere dokunmuyor.

- **Doğum yılı gerçekten isteğe bağlı saklanıyor:** "Yıl bilinmiyor" işaretli doğum günleri
  artık sahte bir yılla değil, boş yıl alanıyla kaydediliyor (veritabanı şeması v6). Güncelleme
  sırasında mevcut kayıtlar kendiliğinden dönüştürülür; eski yedek dosyaları da okunmaya devam
  eder ve yeni yedekler eski sürümlerle uyumlu kalır. Bildirimler, hatırlatma kimlikleri ve
  yaş gösterimi değişmiyor. (F6.4)
- Veritabanında yabancı anahtar kısıtlamaları artık uygulanıyor; hatırlatıcısı olmayan madde
  satırı oluşamıyor. Kullanıcı tarafında bir davranış değişikliği yok. (F6.4)
- **"Alarmlar ve hatırlatıcılar" izni artık isteğe bağlı:** izin yoksa (Android 14+'da yeni
  kurulumlarda varsayılan) hatırlatmalar yine gelir, yalnızca birkaç dakika gecikebilir; izin
  verilince bildirimler kendiliğinden tam zamanlıya geçer. Google Play'in kısıtladığı
  `USE_EXACT_ALARM` izni kaldırıldı. (F6.2c)
- iOS'ta cam efekti (Liquid Glass) gölgelendiricileri açılışta önceden yükleniyor; sekme
  çubuğu ilk karede boş görünmüyor. (F5.4 takip)
- **Depolama Drift (SQLite) veritabanına taşındı;** eski SharedPreferences verisi ilk açılışta
  bir kez, bozuk kayıtlar atlanıp yedeklenerek aktarılır. Taşıma başarısız olursa uygulama eski
  veriyle çalışmaya devam eder ve bir sonraki açılışta yeniden dener. (#20)
- **Arayüz Kor temasına geçti:** yeni hatırlatıcı kartı, gruplu Bugün ekranı, 30 günlük Takvim
  gündemi, Listeler ve filtreler. (#12)
- Bildirim zamanlamaları her değişiklikte hepsi silinip yeniden kurulmak yerine **fark bazlı**
  güncelleniyor; eşzamanlı senkronlar sıraya alınıyor. (#17)
- Araç zinciri: Flutter 3.47, Android Gradle Plugin 9, **iOS minimum sürümü 15.0**,
  `flutter_local_notifications` 22; konum hatırlatmaları için `native_geofence`. (#9, #7)
- Servisler `ReminderCubit`'e dışarıdan veriliyor; `Reminder.copyWith`. (#5)
- CI yalnızca ilgili dosyalar değişince platform derlemelerini çalıştırıyor. (#19)

### Düzeltildi

- **Erişilebilirlik denetimi:** Android'de alt gezinme çubuğundaki seçili sekmenin adı telefon
  genişliğinde kesiliyordu, artık tam görünüyor; çubuğun boş yerine dokunmak alttaki karta
  geçmiyor. Yazı boyutu %200'deyken kart saati başlığın altına iniyor, bölüm başlıklarındaki
  düğmeler ("Tamamlananları gizle", "Hepsini yarına al") sığmayınca alt satıra geçiyor, Tekrar
  sayfasındaki "Bitiş" satırı ve hızlı yakalamadaki "Tüm ayrıntılar / Kaydet" satırı taşmıyor.
  Haritadaki "© OpenStreetMap contributors" bağlantısının dokunma alanı 48 dp oldu; harita ekran
  okuyucuya "Harita" olarak adlandırılıyor. Ekran okuyucu "Şimdi" çizgisini ve düzenleyicilerdeki
  saatleri "saat 14:32" diye okuyor. (F4.5)
