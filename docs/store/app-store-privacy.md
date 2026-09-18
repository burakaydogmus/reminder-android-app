# App Store — Gizlilik etiketi (App Privacy) cevapları

Durum: 13 Eylül 2026, `master` @ 4038806. Veri akışlarının kod dökümü için bkz.
[`play-data-safety.md`](play-data-safety.md) → "Koddan tespitler".

Kaynaklar:
- [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines §5.1.1, §5.1.5](https://developer.apple.com/app-store/review/guidelines/)

## Apple'ın tanımı

- **Collect:** Veriyi cihaz dışına, sizin ve/veya üçüncü taraf ortaklarınızın isteği gerçek zamanlı
  karşılamak için gerekenden **daha uzun süre** erişebileceği şekilde aktarmak.
- Yalnızca cihazda işlenen veri ve "sunucu çağrısında gönderilip saklanmayan IP adresi" toplama
  sayılmaz.
- Uygulamaya eklenen üçüncü taraf kodun (SDK) topladığı veriden geliştirici sorumludur.
- **Precise Location:** enlem/boylamın üç veya daha fazla ondalık basamak çözünürlüğü.

## Önerilen cevap — `GOOGLE_MAPS_KEY` olmadan derlenen iOS sürümü (önerilen)

**"Data Not Collected"** (Veri toplanmıyor)

Gerekçe:

| Akış | Neden "collect" değil |
|---|---|
| Hatırlatıcılar, doğum günleri, ayarlar | Drift/SQLite ve UserDefaults; cihaz dışına çıkmaz. |
| Konum (harita "Konumuma git", geofence) | Core Location üzerinden cihazda işlenir; uygulama koordinatı ağ üzerinden göndermez. |
| Yerel bildirimler | `UNUserNotificationCenter` yerel zamanlama; push yok. |
| OpenStreetMap karoları | İstek kullanıcı konumu parametresi içermez; IP ve user agent sunucu çağrısında gider, geliştirici tarafından saklanmaz. OSMF'nin kendi günlük kayıtları (IP kısaltılarak, 180 gün) üçüncü taraf *ortak* SDK'sı değil, harici bir içerik sunucusudur — bu yorum *doğrulanmalı*. |
| JSON yedek | Kullanıcının başlattığı paylaşım; geliştiriciye aktarım yok. |

## `GOOGLE_MAPS_KEY` ile derlenen sürüm (önerilmez)

Kullanıcı Market kategorisinde "Yakındaki marketleri göster"e bastığında seçili noktanın
koordinatları tam hassasiyetle Google Places API'ye gider. Google'ın bu isteği ne kadar sakladığı
geliştiricinin kontrolünde değil; temkinli beyan:

| Veri türü | Kullanım amacı | Kimliğe bağlı mı (Linked)? | İzleme (Tracking)? |
|---|---|---|---|
| Location → **Precise Location** | App Functionality | Hayır | Hayır |

"İsteğe bağlı beyan" (optional disclosure) istisnası dört koşulun **hepsini** gerektirir; bunlardan
"kullanıcının her seferinde kullanıcı arayüzünde açıkça sağladığı veri" koşulu kısmen sağlansa da
(kullanıcı düğmeye basıyor) istisnanın geçerliliği *doğrulanmalı*. Temkinli yol beyan etmektir;
daha iyi yol iOS sürümünü anahtarsız yayınlamaktır.

## Etiket dışında App Store gereklilikleri

- **Privacy Policy URL** App Store Connect'te zorunlu; ayrıca §5.1.1 gereği **uygulama içinde
  kolay erişilebilir bir bağlantı** olmalı → uygulamada henüz yok (bkz.
  [`permissions-review.md`](permissions-review.md) yapılacaklar).
- **Purpose string'ler** (§5.1.1(ii)) kullanımı açık ve eksiksiz anlatmalı. Mevcut `Info.plist`:
  - `NSLocationWhenInUseUsageDescription`: "Konum hatırlatmaları ve haritada konum seçmek için gerekli."
  - `NSLocationAlwaysAndWhenInUseUsageDescription`: "Seçtiğiniz yere yaklaştığınızda hatırlatma göndermek için konum gerekir."
  Öneri: "uygulama kapalıyken de" ve "konumun cihazdan çıkmaz" vurgusu; uygulama dili "sen" iken
  metinler "siz" kullanıyor; `CFBundleLocalizations` `en` içerdiği halde İngilizce
  `InfoPlist.strings` yok (F6.1/F6.2 kapsamında).
- **Privacy manifest (`PrivacyInfo.xcprivacy`)**: `ios/Runner` altında yok. Gerekli-gerekçeli API
  kullanan eklentiler (ör. `shared_preferences` → UserDefaults, `path_provider`, `package_info_plus`)
  kendi manifestlerini getiriyor olabilir; uygulama hedefi için ayrı manifest gerekip gerekmediği
  bir Xcode arşivi "Generate Privacy Report" ile *doğrulanmalı*.
- **Tracking (ATT)**: İzleme yok → `NSUserTrackingUsageDescription` gerekmez.
