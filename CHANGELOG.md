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
