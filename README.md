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
- **Arayüz:** Material 3 + "Kor" teması (`lib/ui/theme/`), **Google Sans Flex** değişken fontu, `animations`.

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
- **Android:** `compileSdk 35`, `minSdk 26` (`namespace` / `applicationId`: `com.burakaydogmus.reminder`)
- **iOS:** bundle ID `com.burakaydogmus.reminder` (widget App Group için planlanan: `group.com.burakaydogmus.reminder`)
- **iOS:** Geofence ve konum akışı için cihaz / izin beklentileri platform dokümantasyonuna göre ayarlanmalıdır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Web ve masaüstü hedefleri projede mevcut olabilir; asıl hedef ve özellik seti **Android / iOS** odaklıdır (widget ve geofence davranışı platforma göre değişir).

### Release imzalama (Android)

`android/key.properties` varsa release derlemesi onunla imzalanır:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/mutlak/yol/upload-keystore.jks
```

Dosya yoksa (yeni klon) release derlemesi **debug anahtarıyla** imzalanır ve Gradle bir uyarı yazar; bu APK yayınlanmamalıdır. `key.properties` ve `.jks` / keystore dosyaları repoda tutulmaz (`.gitignore`).

CI'da `key.properties` gizli değişkenlerden üretilir; kurulum ve nedenleri
[`docs/android-signing.md`](docs/android-signing.md) içinde. Gizli değişkenler
yoksa CI yine derler, ama APK her koşuda **farklı** bir debug anahtarıyla
imzalanır ve cihazda üst üste kurulamaz.

Release derlemesinde R8 (`minifyEnabled`) ve kaynak küçültme (`shrinkResources`) açıktır; eklentiler için keep kuralları `android/app/proguard-rules.pro`, çalışma anında adla bulunan kaynaklar `android/app/src/main/res/raw/keep.xml` içindedir. CI, Android yapılandırması veya bağımlılıklar değiştiğinde `flutter build apk --release --split-per-abi` çalıştırır ve mimari başına APK yükler (indirilecek olan `app-release-arm64-apk`).

### Uygulama simgesi

`pubspec.yaml` içinde `flutter_launcher_icons` tanımlıdır; ikon değişince:

`dart run flutter_launcher_icons`

## Proje yapısı (kısa)

- `lib/` — UI, `ReminderCubit`, depolar, servisler (bildirim, geofence, Places, home widget)
- `android/`, `ios/` — platform yapılandırması
- `assets/`, `fonts/` — varlıklar
