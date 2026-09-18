# İzinler ve mağaza politikası incelemesi

Durum: 13 Eylül 2026, `master` @ 4038806. Politika sayfaları bu tarihte kontrol edildi; Google Play
politikaları sık değişir, başvurudan hemen önce bağlantılar tekrar okunmalı.

## 1. Android — manifestteki izinler

Kaynak: `android/app/src/main/AndroidManifest.xml`. Eklentilerin (ör. `native_geofence` →
WorkManager, `flutter_local_notifications`) birleştirilmiş manifeste ekledikleri izin ve servisler
burada **yok**; release derlemesinden sonra
`build/app/intermediates/merged_manifests/release/.../AndroidManifest.xml` (veya
`aapt dump permissions app-release.apk`) ile *doğrulanmalı*.

| İzin | Tür | Neden kullanılıyor (kod) | Play politikası durumu | Karar |
|---|---|---|---|---|
| `ACCESS_FINE_LOCATION` | Tehlikeli (çalışma anı) | Harita "Konumuma git" (`Geolocator.getCurrentPosition`), geofence kaydı | Konum politikası; en az kapsam ilkesi | Tut |
| `ACCESS_COARSE_LOCATION` | Tehlikeli | Android 12+ ince konumla birlikte bildirilmek zorunda | — | Tut |
| `ACCESS_BACKGROUND_LOCATION` | Tehlikeli, kısıtlı | Uygulama kapalıyken geofence olayları (`geofenceEntryCallback`) | **Beyan formu + video + belirgin açıklama zorunlu; onay garanti değil** (§2) | Tut, beyan hazırla; B planı hazırla |
| `INTERNET` | Normal | OSM karoları, isteğe bağlı Places | Beyan yok | Tut |
| `RECEIVE_BOOT_COMPLETED` | Normal | `ScheduledNotificationBootReceiver` (bildirimleri yeniden kurar), `NativeGeofenceRebootBroadcastReceiver` (bölgeleri yeniden kaydeder) | Beyan yok; Android dokümanı yeniden başlatmada alarmların silindiğini ve bu yolla kurulmasını öneriyor | Tut |
| `VIBRATE` | Normal | Bildirim titreşimi | Beyan yok | Tut (kodda `KorHaptics` sistem haptiği kullanıyor; bildirim kanalı için gerekli olup olmadığı *doğrulanmalı*) |
| `POST_NOTIFICATIONS` | Tehlikeli (API 33+) | Tüm hatırlatmalar | Beyan yok; bağlamsal isteme önerilir (§4) | Tut — zaten bağlamsal |
| `SCHEDULE_EXACT_ALARM` | Özel erişim (kullanıcı verir) | İzin varsa `AndroidScheduleMode.exactAllowWhileIdle`, yoksa `inexactAllowWhileIdle` (F6.2c) | Beyan yok; Android 14+'da yeni kurulumlarda **varsayılan kapalı** | Tut — inexact yedeği var (§3) |
| ~~`USE_EXACT_ALARM`~~ | Normal ama **Play kısıtlı** | — | Yalnızca çalar saat/zamanlayıcı veya etkinlik bildirimi gösteren takvim uygulamaları | **Kaldırıldı** (F6.2c, §3) |

Diğer gözlemler:

- `android:allowBackup="false"` → Google hesap yedeği yok; gizlilik politikasıyla tutarlı.
  Android 12+ cihazdan cihaza aktarım için `dataExtractionRules` tanımlı değil — davranış
  *doğrulanmalı*.
- `USE_FULL_SCREEN_INTENT`, `FOREGROUND_SERVICE*`, `QUERY_ALL_PACKAGES`, `REQUEST_INSTALL_PACKAGES`
  yok (uygulama manifestinde).
- `targetSdk` = Flutter varsayılanı (CLAUDE.md: 36). Play'in hedef API şartı yeni uygulamalar için
  karşılanıyor olmalı — Play Console'da *doğrulanmalı*.

## 2. `ACCESS_BACKGROUND_LOCATION`

Kaynaklar:
- [Understanding location in the background permissions](https://support.google.com/googleplay/android-developer/answer/9799150)
- [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/9888170)
- [User Data policy — prominent disclosure](https://support.google.com/googleplay/android-developer/answer/10144311)

**Politikanın istediği:**

1. **Play Console beyan formu** (*App content → Sensitive app permissions → Location permissions*):
   arka planda konum gerektiren özellik ve neden yalnızca ön plan konumuyla çalışamayacağı.
2. **Video** (30 sn veya kısa; YouTube bağlantısı tercih edilir): özelliğin arka planda tetiklenmesi,
   uygulama içi belirgin açıklama ve sistem izin penceresi gösterilmeli.
3. **Belirgin açıklama (prominent disclosure):** izin isteğinden *önce*, uygulama içinde, "konum"
   kelimesini ve "uygulama kapalıyken" / "her zaman" gibi arka plan ifadesini içeren, konumu
   kullanan tüm özellikleri sayan metin.
4. Onaysız arka plan konumu kullanan uygulamalarda güncellemeler engellenebilir, uygulama
   kaldırılabilir.

**Risk:** Politika, arka plan konumunun "önemli kullanıcı faydası" sağlayan temel işlev için
olmasını istiyor ve "kolaylık (convenience)" türü faydaları *minimal* sayıyor. Konuma dayalı
hatırlatma bu uygulamanın ilan edilen temel özelliklerinden biri ve uygulama kapalıyken başka türlü
çalışamaz; ama politikada "konum tabanlı hatırlatıcı" açıkça onaylanan örnek olarak geçmiyor.
**Onay garanti değil** — reddedilirse izni kaldırıp yalnızca ön planda çalışan bir sürüm
yayınlamak gerekebilir.

**Mevcut uygulama durumu (F1.6):**

- İstek bağlamsal ve iki adımlı (`lib/ui/permissions/permission_flows.dart`):
  1/2 "Bir yere varınca hatırlatayım — Haritada yer seçmek ve oraya vardığında sana haber vermek
  için konum izni gerekiyor. Konumun yalnızca bu cihazda kullanılır."
  2/2 "Uygulama kapalıyken de çalışsın — … konum iznini “Her Zaman” yap …" → Ayarları aç.
- Metinler "konum" ve "uygulama kapalıyken" ifadelerini içeriyor, sistem ekranından önce
  gösteriliyor → politikaya büyük ölçüde uygun. Eksikler (*öneri*): 2/2 metninde özelliğin adı
  ("konuma varınca hatırlatma") açıkça geçmeli; İngilizce sürüm F6.1 ile gelmeli (inceleme ekibi
  videoyu İngilizce altyazı/açıklamayla daha kolay değerlendirir).
- İzin reddedilince kayıt ve harita çalışmaya devam ediyor (editörde uyarı) → iyi.

**Beyan için taslak metin (İngilizce, Play Console'a):**

> Hatırlatıcı lets users create location-based reminders ("remind me when I arrive at the
> supermarket"). The user picks a place on a map; the app registers a geofence with the Android
> Geofencing API and shows a local notification when the user enters that area. Users set these
> reminders precisely for moments when they are not looking at the app, so the feature cannot work
> with foreground-only location. Location is processed on the device only and never sent to a
> server; no location history is stored.

**Video planı:** (1) Market kategorisinde konumlu hatırlatıcı oluştur → 1/2 açıklama → sistem
"Uygulamayı kullanırken" → 2/2 açıklama → Ayarlar'da "Her zaman izin ver"; (2) uygulamayı kapat;
(3) emülatörde konumu bölge içine taşı → bildirim gelir.

## 3. `USE_EXACT_ALARM` ve `SCHEDULE_EXACT_ALARM`

Kaynaklar:
- [Permissions and APIs that Access Sensitive Information — Exact alarm](https://support.google.com/googleplay/android-developer/answer/9888170)
- [Schedule alarms (developer.android.com)](https://developer.android.com/develop/background-work/services/alarms/schedule)
- [Android 14: Schedule exact alarms are denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)

**Politika:** `USE_EXACT_ALARM` kurulumda otomatik verilir, kullanıcı kapatamaz; bu yüzden Play onu
yalnızca temel, kullanıcıya dönük işlevi hassas zamanlama gerektiren uygulamalara açıyor. Kabul
edilen kullanım durumları: **uygulamanın bir çalar saat veya zamanlayıcı uygulaması olması** ya da
**etkinlik bildirimleri gösteren bir takvim uygulaması olması**. Bu kapsama girmeyenler
`SCHEDULE_EXACT_ALARM` kullanmalı; `USE_EXACT_ALARM` için Play Console beyanı gerekiyor.

**Hatırlatıcı uygun mu?** Büyük olasılıkla **hayır**. Uygulama bir takvim gündemi (Takvim sekmesi)
gösterse de sistem takvimi / etkinlik uygulaması değil; çalar saat de değil. "Hatırlatıcı"
politikada ayrıca sayılmıyor. Beyanla denemek reddedilme ve yayın gecikmesi riski taşıyor.

**`SCHEDULE_EXACT_ALARM` davranışı:** Android 14+'da yeni kurulan uygulamalara varsayılan olarak
verilmez; kullanıcı *Ayarlar → Özel uygulama erişimi → Alarmlar ve hatırlatıcılar*dan açar ve
kapatabilir. İzin yokken `setExactAndAllowWhileIdle` `SecurityException` fırlatır. Önerilen
alternatifler `setAndAllowWhileIdle` / `setWindow` (inexact).

**Mevcut kod (F6.2c ile uygulandı):** `USE_EXACT_ALARM` manifestten **kaldırıldı**, yalnızca
`SCHEDULE_EXACT_ALARM` var. `NotificationService.syncSchedules` modu her senkronda bir kez
`canScheduleExactNotifications()` ile seçer: izin varsa `exactAllowWhileIdle`, yoksa
`inexactAllowWhileIdle` (`setAndAllowWhileIdle`; izin gerektirmez, birkaç dakika gecikebilir).
Doğrulandı: `flutter_local_notifications` 22.3.1 izin yokken exact modda
`exact_alarms_not_permitted` `PlatformException`'ı fırlatır; senkron bunu bildirim başına yakalar,
inexact'a düşer ve devam eder. Mod parmak izine girer (`_ScheduleSpec._version` 5), böylece izin
verilince/geri alınınca bir sonraki senkron (uygulama ön plana dönünce `AppStateReloader` →
`ReminderCubit.load`, ya da Ayarlar'daki "Ayarları aç"tan dönüşte durum değiştiyse) bildirimleri
yeni modla yeniden kurar. Birleştirilmiş manifest: eklentilerden yalnızca
`flutter_local_notifications` izin ekliyor (`POST_NOTIFICATIONS`, `VIBRATE`); hiçbiri
`USE_EXACT_ALARM`/`SCHEDULE_EXACT_ALARM` bildirmiyor (pub cache manifestleri, 19 Eylül 2026).

**Öneri (sıra önemli; 1–3 F6.2c ile yapıldı):**

1. **Önce kod (takip maddesi):** zamanlamadan önce `canScheduleExactNotifications()` kontrolü;
   `false` ise `AndroidScheduleMode.inexactAllowWhileIdle`. Mod değişince `_ScheduleSpec._version`
   artırılmalı veya izin durumu fingerprint'e eklenmeli ki izin verildiğinde bildirimler exact
   moda yeniden kurulsun (izin değişimi `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` /
   resume'da yeniden senkron). Test: sahte eklentiyle iki mod.
2. **Sonra manifest:** `USE_EXACT_ALARM` satırını kaldır, `SCHEDULE_EXACT_ALARM`'ı tut.
3. Ayarlar → İzinler'deki "Tam zamanlı alarmlar" satırı ve "Tam zamanında hatırlatma" açıklama
   sayfası bu davranışı anlatıyor ("İzin olmadan hatırlatmalar birkaç dakika gecikebilir");
   izin hiçbir şeyi engellemez.

**Alternatif (önerilmez):** `USE_EXACT_ALARM`'ı tutup beyanda "takvim gündemi olan hatırlatıcı"
olarak başvurmak. Reddedilirse yine 1–2 yapılmak zorunda.

## 4. `POST_NOTIFICATIONS`

Kaynak: [Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)

- Android 13+ (API 33) çalışma anı izni; hedef API 33+ uygulamalarda yeni kurulumda bildirimler
  izin verilene kadar kapalı. Android, izni kullanıcı bağlamı anladıktan sonra, bir eyleme bağlı
  istemeyi öneriyor.
- Uygulama: açılışta istemiyor; onboarding 3. adımda açıklamalı ön-izin sayfası ve ilk zamanlı
  hatırlatıcı/doğum günü kaydında `beforeScheduling` → **uygun**. Play beyanı gerekmez.

## 5. Ağ özellikleriyle ilgili politika bulguları

### OpenStreetMap karoları
Kaynak: [OSMF Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/)

- Atıf haritada açıkça görünmeli ("© OpenStreetMap contributors"). Kodda
  `SimpleAttributionWidget(source: Text('OpenStreetMap'))` var → metin **"© OpenStreetMap
  contributors"** olmalı ve telif sayfasına bağlanmalı (takip maddesi).
- Uygulamayı tanımlayan user agent zorunlu → `userAgentPackageName: 'com.burakaydogmus.reminder'`
  var; flutter_map'in gönderdiği tam dize *doğrulanmalı*.
- Karolar HTTP önbellek başlıklarına göre (en az 7 gün) önbelleğe alınmalı; toplu indirme/çevrimdışı
  kullanım yasak. `flutter_map` 8.x'in yerleşik önbelleği *doğrulanmalı*.
- Ticari/uygulama kullanımı serbest ama erişim önceden haber verilmeden kesilebilir. Kullanıcı sayısı
  artarsa ücretli/ayrı bir karo sağlayıcısı değerlendirilmeli.

### Google Places (yalnızca `GOOGLE_MAPS_KEY` ile)
Kaynaklar: [Places API policies](https://developers.google.com/maps/documentation/places/web-service/policies),
[Google Maps Platform Terms](https://cloud.google.com/maps-platform/terms)

- Places sonuçları haritada gösterilecekse Google haritasında gösterilmeli; Google Maps Platform
  koşulları Places içeriğinin Google olmayan bir haritayla kullanılmasını yasaklıyor (ilgili madde
  metni koşullar sayfasından *doğrulanmalı*). Uygulama seçilen marketi **OSM haritasına** taşıyor.
- Harita dışında gösterimde Google Maps logosu/atfı gerekli → liste sayfasında atıf yok.
- Places içeriği (`place_id` hariç) önbelleğe alınamaz/saklanamaz → seçilen yerin adı
  hatırlatıcıyla saklanıyor (*doğrulanmalı*: `LocationPickResult.label` kalıcı mı).
- **Öneri:** Mağaza sürümleri anahtarsız derlensin (düğme `mapsConfigured` false iken hiç
  görünmüyor, kod değişikliği gerekmez). Özellik istenirse ya kaldırılmalı ya da Google haritası +
  atıf + saklama kurallarıyla yeniden tasarlanmalı.

## 6. Ön plan servisi (foreground service)

Kaynaklar:
- [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821)
- [Preview: foreground service requirements (geofencing removal)](https://support.google.com/googleplay/android-developer/answer/16965181)

- Hedef API 34+ uygulamalar kullandıkları her FGS türünü manifestte ve Play Console'da (açıklama +
  video) beyan etmeli.
- Google, **geofencing'i onaylı FGS kullanım durumlarından çıkarıyor** ve Geofence API'yi öneriyor.
  Önizleme sayfası tarihi 27 Ocak 2027 olarak veriyor; `CLAUDE.md` 28 Ekim 2026 diyor — tarih
  *doğrulanmalı*, ama uygulamayı etkilemiyor.
- Uygulama **FGS kullanmıyor** (`NativeGeofenceBackgroundManager.promoteToForeground` çağrılmıyor,
  uygulama manifestinde FGS izni yok). WorkManager'ın birleştirilmiş manifeste `SystemForegroundService`
  / `FOREGROUND_SERVICE` ekleyip eklemediği kontrol edilmeli; eklenmişse ve kullanılmıyorsa
  `tools:node="remove"` ile çıkarmak Play Console'daki FGS sorusunu sadeleştirir (*doğrulanmalı*).

## 7. iOS

Kaynaklar: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) §2.5.4,
§5.1.1, §5.1.5; [`requestAlwaysAuthorization()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/requestalwaysauthorization())

- **§5.1.5 Konum:** konum yalnızca uygulamanın özelliğiyle doğrudan ilgiliyse kullanılmalı; toplama
  /iletme/kullanma öncesi bilgilendirme ve onay. → Harita ve bölge hatırlatması doğrudan ilgili.
- **"Her zaman" (Always):** Apple önce "Kullanırken", ihtiyaç doğunca "Her zaman" istemeyi öneriyor;
  sistem Always yükseltmesini ilk etapta geçici (provisional) verebilir ve kullanıcıya daha sonra
  sorar. Uygulamanın 2 adımlı akışı bununla uyumlu. İnceleme notuna (App Review Notes) konumlu
  hatırlatmanın nasıl test edileceği yazılmalı (Xcode/Simulator'da konum simülasyonu).
- **§5.1.1(iv):** izin verilmezse alternatif sunulmalı → harita elle seçim çalışıyor; iyi.
- **§2.5.4 arka plan modları:** `UIBackgroundModes` yok. Region monitoring için `location` arka plan
  modu gerekmez (sistem uygulamayı yeniden başlatır) → **ekleme**; eklenirse sürekli konum
  kullanımını gerekçelendirmek gerekir.
- **Purpose string'ler:** var, Türkçe; İngilizce `InfoPlist.strings` yok, hitap "siz". Bkz.
  [`app-store-privacy.md`](app-store-privacy.md).
- **Bildirim izni:** `flutter_local_notifications` ile bağlamsal; Info.plist anahtarı gerekmez.
- **Privacy manifest:** `ios/Runner/PrivacyInfo.xcprivacy` yok → *doğrulanmalı*.
- iOS'ta bölge sınırı 20 (uygulama zaten en yeni 20'yi kaydediyor).

## 8. Öncelikli yapılacaklar

Kod değişiklikleri bu PR'da **yapılmadı**; ayrı roadmap maddeleri/PR'lar olarak ele alınmalı.

| # | Öncelik | İş | Tür | Not |
|---|---|---|---|---|
| 1 | ~~Engelleyici~~ | ~~Exact alarm izni yokken `inexactAllowWhileIdle`'a düşen zamanlama + izin değişiminde yeniden senkron~~ | Kod (`notification_service.dart`, `permission_flows.dart`) | **Yapıldı** (F6.2c) |
| 2 | ~~Engelleyici~~ | ~~Manifestten `USE_EXACT_ALARM` kaldır (1'den sonra)~~ | Kod (manifest) | **Yapıldı** (F6.2c) |
| 3 | Engelleyici | Gizlilik politikasını herkese açık URL'de yayınla, iletişim adresini doldur | Repo ayarı + doküman | GitHub Pages önerisi politika dosyasında |
| 4 | Engelleyici | Ayarlar'a "Gizlilik politikası" bağlantısı (Play + App Store §5.1.1 zorunlu) | Kod (`settings_page.dart`) | `url_launcher` gerekebilir |
| 5 | Engelleyici | Release'i `GOOGLE_MAPS_KEY` olmadan derle (F6.3 pipeline'ında sabitle) | CI/süreç | Places koşulları + gizlilik formu |
| 6 | Yüksek | Arka plan konumu beyan metni + 30 sn video; 2/2 açıklamasında özellik adını netleştir | Play Console + küçük metin değişikliği | Reddedilme için B planı: `ACCESS_BACKGROUND_LOCATION`'sız sürüm |
| 7 | Yüksek | OSM atfını "© OpenStreetMap contributors" + bağlantı yap; karo önbelleğini doğrula | Kod (`location_picker_page.dart`) | OSMF politikası |
| 8 | Yüksek | Birleştirilmiş manifestte izin/servis dökümü; kullanılmayan FGS bileşenlerini çıkar | Doğrulama (+ gerekirse manifest) | |
| 9 | Orta | "Lisanslar" girişi (`showLicensePage`) + Google Sans Flex OFL'in `LicenseRegistry`'ye eklenmesi | Kod | bkz. `licensing.md` |
| 10 | Orta | iOS: `PrivacyInfo.xcprivacy` gerekliliğini doğrula; İngilizce `InfoPlist.strings`, "sen" hitabı | Kod (iOS) | F6.1 ile |
| 11 | Orta | Places özelliği kalacaksa: Google haritası/atıf/saklama kurallarına göre yeniden tasarım, yoksa kaldır | Kod | |
| 12 | Düşük | `VIBRATE` gerekliliğini ve `dataExtractionRules` davranışını doğrula | Doğrulama | |
