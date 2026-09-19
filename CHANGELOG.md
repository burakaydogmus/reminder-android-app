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

- iOS'ta arama iki kez sunulmuyor: Bugün ve Listeler başlığındaki arama simgesi kaldırıldı,
  arama cam sekme çubuğundaki "Ara" dairesinden açılıyor (akıllı listelerde simge duruyor).
  Android değişmedi. (F3.6 takip)
- Ayarlar → Lisanslar: `liquid_glass_widgets` içine gömülü `liquid_glass_renderer` ve `motor`
  kodunun MIT bildirimleri de listeleniyor. (F6.2b takip)
- Konum hatırlatmaları uygulama kapalıyken ve cihaz yeniden başladıktan sonra da çalışıyor. (#7)
- Tek bir bozuk kayıt yüzünden tüm hatırlatıcıların silinmesi engellendi; bozuk veri yedekleniyor. (#6)
- Ana ekran aracından hatırlatıcı tamamlamak doğum günü bildirimlerini silmiyor. (#11)
- Bildirim kimlikleri kararlı hale getirildi (sürümler arasında kaybolan/çakışan bildirimler). (#13)
- Değişikliklerden sonra liste sıralaması; 29 Şubat doğum günleri artık artık yıl olmayan yıllarda
  28 Şubat'ta; yıllık doğum günü bildirim metninde eskiyen yaş bilgisi kaldırıldı. (#14)
- Uygulama öne geldiğinde veri depodan yeniden yükleniyor; ana ekran aracında yapılan değişikliği
  açık uygulama artık ezmiyor. (#15)
- Editörde geçmiş bir saat sessizce değiştirilmiyor; uyarı ve "Yarın aynı saat" önerisi. (#16)
- İzinler açılışta topluca istenmiyor; ihtiyaç anında açıklamayla isteniyor. (#18)
- Release derlemeleri: `key.properties` yokken derlemenin kırılması ve R8 küçültme sorunları. (#10)

### Güvenlik

- İzinler (konum, bildirim, tam zamanlı alarm) artık yalnızca ilgili özellik kullanılırken ve
  gerekçesiyle isteniyor; reddedilmesi kaydı veya haritayı engellemiyor. (#18)
- Release imzalama anahtarları (`key.properties`, keystore) repoda tutulmuyor; anahtar yoksa
  derleme uyarı veriyor ve bu APK'nın yayınlanmaması gerektiği belgelendi. (#10)
