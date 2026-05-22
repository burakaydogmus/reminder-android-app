# Hatırlatıcı

Flutter ile yazılmış genel amaçlı hatırlatıcı uygulaması: alınacaklar, yapılacaklar, isteğe bağlı zamanlı bildirimler ve konumla tetiklenen hatırlatmalar. Yerel depolama ile çalışır; arayüz Türkçe ağırlıklıdır (`tr_TR`).

**Sürüm (pubspec):** `2.1.0+8`

## Özellikler

- **Durum yönetimi:** `flutter_bloc` / `Cubit` ile listeler ve ayarlar.
- **Kategoriler:** Market, ev, iş, sağlık, günlük işler ve özelleştirilebilir **Diğer**.
- **Zamanlı bildirim** (isteğe bağlı): `flutter_local_notifications` + `timezone` / `flutter_timezone`.
- **Konum hatırlatması** (isteğe bağlı): Haritadan nokta + yarıçap; bölgeye girince `flutter_geofence_manager` ile bildirim. `geolocator` ve `permission_handler` ile izinler.
- **Harita:** `flutter_map` + OpenStreetMap; ek Google Maps **native SDK** anahtarı gerekmez.
- **Yakındaki marketler** (isteğe bağlı): Market kategorisinde Google Places (Nearby) ile arama — yalnızca HTTP; API anahtarı aşağıdaki gibi `dart-define` ile verilir, anahtar yoksa harita ve manuel pin yine çalışır.
- **Ana ekran aracı (Android):** `home_widget` ile widget senkronu ve etkileşim.
- **Veri:** `shared_preferences` (JSON), `uuid` ile kimlikler.
- **Arayüz:** `animations`, **Comfortaa** fontu, Material 3 teması.

### Google Places (sadece “yakındaki market” araması)

Harita kireleri OSM’dir. Places sadece isteğe bağlı ayardır:

1. [Google Cloud Console](https://console.cloud.google.com/)’da proje oluşturun; **Places API** (ve kullanımınıza göre faturalandırma) etkin olsun.
2. API anahtarını kısıtlayın (IP / uygulama kısıtları, üretimde sıkılaştırın).
3. Derleme veya çalıştırma sırasında:

   `flutter run --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY`

   veya release için aynı `--dart-define` değerini CI / IDE run configuration’a ekleyin.

Anahtar, `lib/config/maps_config.dart` içinde `String.fromEnvironment('GOOGLE_MAPS_KEY', …)` ile okunur; `local.properties` veya iOS `GMSApiKey` **bu proje haritası için gerekli değildir**.

## Gereksinimler

- Flutter `>= 3.24`
- Dart `>= 3.5` (`< 4.0`)
- **Android:** `compileSdk 35`, `minSdk 26` (`namespace` / `applicationId`: `com.fabirt.reminder`)
- **iOS:** Geofence ve konum akışı için cihaz / izin beklentileri platform dokümantasyonuna göre ayarlanmalıdır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Web ve masaüstü hedefleri projede mevcut olabilir; asıl hedef ve özellik seti **Android / iOS** odaklıdır (widget ve geofence davranışı platforma göre değişir).

### Release imzalama (Android)

Release derlemesi `android/app/build.gradle` içinde `key.properties` ve keystore yolları kullanacak şekilde ayarlanabilir. `key.properties` ve `.jks` / keystore dosyaları repoda tutulmamalı; `.gitignore` buna göre doldurulmuştur.

### Uygulama simgesi

`pubspec.yaml` içinde `flutter_launcher_icons` tanımlıdır; ikon değişince:

`dart run flutter_launcher_icons`

## Proje yapısı (kısa)

- `lib/` — UI, `ReminderCubit`, depolar, servisler (bildirim, geofence, Places, home widget)
- `android/`, `ios/` — platform yapılandırması
- `assets/`, `fonts/` — varlıklar
