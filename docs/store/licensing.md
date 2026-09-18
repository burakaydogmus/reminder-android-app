# Lisans durumu ve üçüncü taraf atıfları

Durum: 19 Eylül 2026. **Bu belge hukuki görüş değildir;** kararlar repo sahibine aittir.

## 1. Repo lisansı: MIT

- Repo sahibi 13 Eylül 2026'da **MIT lisansını** seçti. Kökteki `LICENSE` dosyası
  "Copyright (c) 2026 Burak Aydoğmuş" bildirimiyle #27 (`chore/license-and-kor-text`) ile ekleniyor.
- MIT; kodun kopyalanmasına, değiştirilmesine, dağıtılmasına ve ticari kullanımına izin verir. Tek
  koşul, telif ve izin bildiriminin kodun tüm kopyalarında veya önemli kısımlarında korunmasıdır
  ([choosealicense.com — MIT](https://choosealicense.com/licenses/mit/)).
- Sonuç: başkaları uygulamanın kopyalarını da yayınlayabilir. Mağaza adı, simge ve ekran
  görüntüleri kod lisansıyla korunmaz; marka koruması isteniyorsa ayrıca değerlendirilmeli.
- MIT, mağazada yayına engel değildir; mağaza dağıtımı için ek lisans gerekmez.
- Repodaki MIT lisansı **üçüncü taraf bileşenlerin lisanslarını değiştirmez**. Aşağıdaki atıflar
  ayrıca verilmelidir:
  - **Google Sans Flex** yazı tipi: SIL Open Font License 1.1 (`fonts/GoogleSansFlex/OFL.txt`);
    Ayarlar → Lisanslar sayfasında gösteriliyor.
  - **liquid_glass_widgets içine gömülü kod:** `liquid_glass_renderer` ve `motor` (ikisi de MIT,
    Tim Lehmann for whynotmake.it); bildirimleri Lisanslar sayfasında.
  - **OpenStreetMap** harita verisi: haritada ve mağaza metninde "© OpenStreetMap contributors".
  - **pub.dev paketleri ve Flutter:** kendi lisansları; uygulamada Ayarlar → Diğer → Lisanslar
    (`showLicensePage`) ile gösteriliyor (F6.2b).
  - Ayrıntılar §3'te.

## 2. Proje kökeni (doğrulanmalı)

- Git geçmişinin ilk commit'leri (22 Mayıs 2026) `burakaydogmus` tarafından yazılmış; ancak paket
  kimliği F1.9'a (#10) kadar **`com.fabirt.reminder`** idi (ör. `434c747 feat(ui): OSM location
  picker page` içinde `userAgentPackageName: 'com.fabirt.reminder'`, Kotlin paketi
  `com/fabirt/reminder`). İlk sürümde Comfortaa yazı tipi de vardı (`6990055`).
- Bu, erken kodun **"fabirt" adlı bir geliştiricinin hatırlatıcı uygulamasından veya şablonundan
  türemiş** olabileceğini düşündürüyor. Repo sahibi şunu doğrulamalı: kaynak projenin lisansı
  nedir ve atıf gerekiyor mu? Kaynak MIT gibi izin verici bir lisanstaysa, onun telif bildirimi
  `LICENSE` dosyasına (ör. ikinci bir "Copyright (c) … fabirt" satırı) veya bir `NOTICE`
  dosyasına eklenmeli. Lisanssızsa, ilgili kısımlar için izin alınmalı veya bu kısımlar yeniden
  yazılmalı (büyük bölümü F1–F4'te zaten yeniden yazıldı). Uygulama simgesinin
  (`assets/launcher/icon.png`) kaynağı da aynı şekilde doğrulanmalı.

## 3. Uygulamada atıf verilmesi gerekenler

| Bileşen | Lisans / koşul | Nerede | Mevcut durum | Yapılacak |
|---|---|---|---|---|
| **Google Sans Flex** yazı tipi | SIL Open Font License 1.1 | `fonts/GoogleSansFlex/OFL.txt`, `GoogleSansFlex-Latin.ttf` (alt küme) | **Tamam (F6.2b):** `OFL.txt` uygulamaya asset olarak paketleniyor ve `registerAppLicenses()` (`lib/config/app_licenses.dart`) ile `LicenseRegistry`'ye ekleniyor; Lisanslar sayfasında "Google Sans Flex" altında görünüyor. | OFL alt kümeyi değiştirilmiş sürüm sayar; "Reserved Font Name" varsa alt küme o adla dağıtılamaz — `OFL.txt` başlığında RFN satırı yok, yine de font yükseltmelerinde kontrol edilmeli. |
| **OpenStreetMap** harita verisi ve karoları | ODbL veri lisansı; [OSMF Karo Kullanım Politikası](https://operations.osmfoundation.org/policies/tiles/), [Telif ve lisans](https://www.openstreetmap.org/copyright) | `location_picker_page.dart` | Haritada "OpenStreetMap" metni | Haritada görünür **"© OpenStreetMap contributors"** ve telif sayfasına bağlantı. Mağaza açıklamasına da eklendi. |
| **Google Places** (yalnızca anahtarlı derleme) | [Places API atıf politikası](https://developers.google.com/maps/documentation/places/web-service/policies), Google Maps Platform Koşulları | `places_nearby_service.dart` | Atıf yok | Mağaza sürümünde özelliği anahtarsız derleyerek kapatmak önerildi (bkz. `permissions-review.md` §5). |
| **pub.dev paketleri** (flutter_bloc, drift, sqlite3, flutter_map, flutter_local_notifications, native_geofence, home_widget, share_plus, file_selector, …) ve Flutter/Dart | Çoğunlukla BSD-3, MIT, Apache-2.0 | `pubspec.lock` | Flutter derleme sırasında paketlerin `LICENSE` dosyalarını `LicenseRegistry`'ye otomatik toplar; **Tamam (F6.2b):** Ayarlar → Diğer → Lisanslar (`showLicensePage`) hepsini gösteriyor. | — |
| **liquid_glass_renderer** (`liquid_glass_widgets` içine gömülü render motoru) ve **motor** (uyarlanmış yay animasyonu kodu) | MIT — Copyright 2025 / (c) 2024 Tim Lehmann for whynotmake.it | `liquid_glass_widgets` paketinin `THIRD_PARTY_NOTICES` dosyası | **Tamam:** Flutter yalnızca paketlerin `LICENSE` dosyasını topladığından bu bildirimler otomatik görünmüyordu; `assets/licenses/liquid_glass_renderer.txt` ve `assets/licenses/motor.txt` (paketten birebir kopya) `registerAppLicenses()` ile Lisanslar sayfasına ekleniyor. | Paket yükseltildiğinde `THIRD_PARTY_NOTICES` ile karşılaştırılıp güncellenmeli. |
| **SQLite** (sqlite3 build hook ile paketleniyor) | Kamu malı (public domain) | — | — | Atıf zorunlu değil; lisans ekranında görünmesi yeterli. |
| Apple / Google sistem servisleri (Core Location, Play Services Location) | Platform koşulları | — | — | Ek atıf gerekmez. |

## 4. Takip maddeleri

1. ~~Ayarlar → "Lisanslar" (`showLicensePage`) ve Google Sans Flex OFL'in `LicenseRegistry`'ye
   eklenmesi~~ — F6.2b'de yapıldı; `liquid_glass_widgets` içindeki üçüncü taraf bildirimleri de
   eklendi (F5.4/F6.2b takip).
2. OSM atıf metninin "© OpenStreetMap contributors" + bağlantı olarak güncellenmesi.
3. Repo sahibi: §2'deki köken ve simge doğrulaması; gerekirse `LICENSE`/`NOTICE`'a ek telif satırı.
