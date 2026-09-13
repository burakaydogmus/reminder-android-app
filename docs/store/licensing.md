# Lisans durumu ve üçüncü taraf atıfları

Durum: 13 Eylül 2026. **Bu belge hukuki görüş değildir;** kararlar repo sahibine aittir. Bu PR
bilinçli olarak **LICENSE dosyası eklemez.**

## 1. Repo lisansı

- `github.com/burakaydogmus/reminder-android-app` **herkese açık** ve kökte `LICENSE` dosyası
  **yok**.
- Lisans belirtilmeyen kod varsayılan olarak **"tüm hakları saklıdır"** kapsamındadır: başkaları
  kodu görebilir ve GitHub Hizmet Şartları gereği GitHub arayüzünde görüntüleyip fork'layabilir,
  ancak kopyalama, değiştirme, dağıtma veya kendi uygulamasında kullanma hakkı almaz
  ([choosealicense.com — No License](https://choosealicense.com/no-permission/),
  [GitHub Docs — Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)).
- Mağazada yayın için açık kaynak lisansı **gerekmez**. Seçenekler:
  1. **Lisanssız bırakmak** (tüm hakları saklı) — kod görünür ama kullanılamaz. İsteniyorsa README'ye
     "All rights reserved" notu eklenebilir.
  2. **İzin verici lisans** (MIT / Apache-2.0) — başkaları kodu serbestçe kullanabilir; mağazadaki
     uygulamanın kopyalarının yayınlanmasını da mümkün kılar.
  3. **Copyleft** (GPL-3.0) — türev işler açık kalmalı. App Store dağıtımıyla GPL uyumu tartışmalı;
     *doğrulanmalı*.
  4. **Repoyu gizliye almak** — yayın öncesi en basit koruma.

## 2. Proje kökeni (doğrulanmalı)

- Git geçmişinin ilk commit'leri (22 Mayıs 2026) `burakaydogmus` tarafından yazılmış; ancak paket
  kimliği F1.9'a (#10) kadar **`com.fabirt.reminder`** idi (ör. `434c747 feat(ui): OSM location
  picker page` içinde `userAgentPackageName: 'com.fabirt.reminder'`, Kotlin paketi
  `com/fabirt/reminder`). İlk sürümde Comfortaa yazı tipi de vardı (`6990055`).
- Bu kimlik, projenin **"fabirt" adlı bir geliştiricinin önceki bir hatırlatıcı uygulamasından veya
  şablonundan türemiş** olabileceğini düşündürüyor. Repo sahibinin doğrulaması gerekenler:
  - Kod gerçekten başka bir projeden mi alındı? Alındıysa kaynağın lisansı nedir?
  - İzin verici bir lisansa (ör. MIT) tabiyse, telif ve lisans bildirimi dağıtılan uygulamada ve
    repoda **korunmalı**; lisanssızsa kodun kullanım izni sahibinden alınmalı veya ilgili kısımlar
    yeniden yazılmalı.
  - Uygulama simgesinin (`assets/launcher/icon.png`) kaynağı ve kullanım hakkı.
- Bu doğrulama yapılmadan projeye kendi lisansını eklemek (özellikle izin verici bir lisans)
  başkasına ait kodu yeniden lisanslamak anlamına gelebilir.

## 3. Uygulamada atıf verilmesi gerekenler

| Bileşen | Lisans / koşul | Nerede | Mevcut durum | Yapılacak |
|---|---|---|---|---|
| **Google Sans Flex** yazı tipi | SIL Open Font License 1.1 | `fonts/GoogleSansFlex/OFL.txt`, `GoogleSansFlex-Latin.ttf` (alt küme) | Lisans dosyası repoda; uygulama paketine ve lisans ekranına **dahil değil** | OFL, yazı tipiyle birlikte telif bildirimi ve lisans metninin dağıtılmasını ister (ayrı metin dosyası veya font içindeki meta veri). Güvenli yol: `LicenseRegistry.addLicense` ile `OFL.txt`'yi lisans ekranına eklemek. OFL alt kümeyi değiştirilmiş sürüm sayar; "Reserved Font Name" varsa alt küme o adla dağıtılamaz — `OFL.txt` başlığında RFN olup olmadığı *doğrulanmalı*. |
| **OpenStreetMap** harita verisi ve karoları | ODbL veri lisansı; [OSMF Karo Kullanım Politikası](https://operations.osmfoundation.org/policies/tiles/), [Telif ve lisans](https://www.openstreetmap.org/copyright) | `location_picker_page.dart` | Haritada "OpenStreetMap" metni | Haritada görünür **"© OpenStreetMap contributors"** ve telif sayfasına bağlantı. Mağaza açıklamasına da eklendi. |
| **Google Places** (yalnızca anahtarlı derleme) | [Places API atıf politikası](https://developers.google.com/maps/documentation/places/web-service/policies), Google Maps Platform Koşulları | `places_nearby_service.dart` | Atıf yok | Mağaza sürümünde özelliği anahtarsız derleyerek kapatmak önerildi (bkz. `permissions-review.md` §5). |
| **pub.dev paketleri** (flutter_bloc, drift, sqlite3, flutter_map, flutter_local_notifications, native_geofence, home_widget, share_plus, file_selector, …) ve Flutter/Dart | Çoğunlukla BSD-3, MIT, Apache-2.0 | `pubspec.lock` | Flutter derleme sırasında paketlerin `LICENSE` dosyalarını `LicenseRegistry`'ye otomatik toplar, ancak uygulamada **gösteren bir ekran yok** | Ayarlar'a "Lisanslar" satırı → `showLicensePage(context: …, applicationName: 'Hatırlatıcı', applicationVersion: …)`. |
| **SQLite** (sqlite3 build hook ile paketleniyor) | Kamu malı (public domain) | — | — | Atıf zorunlu değil; lisans ekranında görünmesi yeterli. |
| Apple / Google sistem servisleri (Core Location, Play Services Location) | Platform koşulları | — | — | Ek atıf gerekmez. |

## 4. Takip maddeleri (kod — bu PR'da yapılmadı)

1. Ayarlar → "Lisanslar" (`showLicensePage`) ve Google Sans Flex OFL'in `LicenseRegistry`'ye eklenmesi
   (`OFL.txt` asset olarak `pubspec.yaml`'a eklenmeli).
2. OSM atıf metninin "© OpenStreetMap contributors" + bağlantı olarak güncellenmesi.
3. Repo sahibinin kararı: lisans seçimi (veya bilinçli olarak lisanssız) ve §2'deki köken doğrulaması.
