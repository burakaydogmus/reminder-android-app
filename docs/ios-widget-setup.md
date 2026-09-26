# iOS widget'ı: Xcode'da yapılacaklar (F5.2)

Bu depodaki iOS widget'ı (WidgetKit) **Mac olmadan** yazıldı: hedef, derleme
ayarları ve dosya referansları `ios/Runner.xcodeproj/project.pbxproj` içine elle
eklendi ve yalnızca CI'daki macOS runner'ında derlendi
(`.github/workflows/ios.yml`, "Verify the widget extension is embedded" adımı
`Runner.app/PlugIns/ReminderWidgetExtension.appex`'in gerçekten gömüldüğünü
doğrular).

Aşağıdakiler **cihazda** çalıştırmak için gereken, CI'ın doğrulayamadığı
adımlardır.

## 1. Projeyi aç

```bash
open ios/Runner.xcworkspace   # .xcodeproj değil: CocoaPods var
```

Xcode "ReminderWidgetExtension" hedefini ve `ReminderWidget` grubunu olduğu gibi
görmeli. Kırmızı (eksik) dosya referansı olmamalı. Şema olarak **Runner** yeterli;
extension, Runner'ın hedef bağımlılığı olduğu için onunla derlenir.

## 2. App Group capability'si (iki hedefte de)

Entitlement dosyaları hazır:

- `ios/Runner/Runner.entitlements`
- `ios/ReminderWidget/ReminderWidgetExtension.entitlements`

İkisi de `group.com.burakaydogmus.reminder` grubunu ister. Apple Developer
hesabında bu grubun **bir kez** oluşturulması ve her iki hedefte
Signing & Capabilities › **+ Capability › App Groups** altında işaretlenmesi
gerekir:

1. Runner hedefi › Signing & Capabilities › Team'i seç.
2. **+ Capability** › App Groups › listede `group.com.burakaydogmus.reminder`
   yoksa **+** ile ekle ve işaretle.
3. Aynısını **ReminderWidgetExtension** hedefinde yap.

Grup kimliği üç yerde geçer ve **aynı** olmalı — `test/services/
reminder_home_widget_sync_test.dart` içindeki sözleşme testi bunu kontrol eder:

| Yer | Sabit |
|---|---|
| Dart | `kHomeWidgetAppGroupId` (`lib/services/reminder_home_widget_sync.dart`) |
| Swift | `ReminderWidgetStore.appGroupId` |
| Entitlements | iki dosya da yukarıdaki grup |

## 3. İmzalama (extension'ın kendi bundle id'si var)

- Runner: `com.burakaydogmus.reminder`
- Extension: `com.burakaydogmus.reminder.ReminderWidget`

Automatic signing açıkken Xcode extension için ayrı bir provisioning profile
üretir; ilk seferde "Register bundle identifier" diyaloğunu onaylaman gerekir.
Sürüm numaraları `Flutter/Generated.xcconfig`'ten gelir
(`$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`), yani `pubspec.yaml` ile
kendiliğinden aynı kalır — App Store bunu şart koşar.

## 4. Minimum iOS sürümü

| Hedef | `IPHONEOS_DEPLOYMENT_TARGET` |
|---|---|
| Runner (uygulama) | **15.0** (Podfile ile aynı, değişmedi) |
| ReminderWidgetExtension | **17.0** |

Extension'ın daha yükseğe çekilmesi bilinçlidir: etkileşimli widget düğmeleri
(`Button(intent:)`), `AppIntentConfiguration` ve `containerBackground(for:)`
iOS 17 API'leridir. Uygulamanın minimumunu yükseltmek gerekmedi; iOS 15–16
kullanıcıları uygulamayı kullanır, widget galerisinde bu widget'ları görmez.
Extension'ın minimumu uygulamanınkinden yüksek olabilir (Apple bunu destekler);
tersi App Store doğrulamasında hata olurdu.

## 5. Cihazda test

1. `flutter run --release -d <cihaz>` (veya Xcode'dan Runner'ı çalıştır) ile
   uygulamayı kur ve **bir kez aç** — widget verisi App Group'a ancak
   uygulama bir senkron yaptığında yazılır (`ScheduleSync.syncAll`).
2. Ana ekranda boş bir yere uzun bas › **Düzenle** › **+** › "Hatırlatıcı" grubu:
   dört widget görünür — **Sıradaki** (küçük), **Bugün** (orta), **Liste**
   (büyük), **Kilit ekranı** (daire / dikdörtgen / satır).
3. **Tamamla:** bir satırın dairesine dokun. Satır **hemen** kaybolur
   (widget, App Group'taki `widget_completions_v1` kuyruğundaki id'leri
   çizmez), ama hatırlatıcı depoda ancak uygulama bir sonraki kez açıldığında
   (veya ön plana döndüğünde) tamamlanır. Bunu doğrulamak için: dokun →
   uygulamayı aç → hatırlatıcının tamamlanmış olduğunu gör.
4. **Derin bağlantılar:** "+" hızlı yakalamayı açar, satır o hatırlatıcının
   düzenleyicisini, doğum günü satırı Doğum günleri'ni, "Bildirimler kapalı"
   şeridi Ayarlar › İzinler'i açar.
5. **Liste widget'ının ayarı:** Liste widget'ına uzun bas › **Widget'ı düzenle**
   › "Yalnızca bugün" anahtarı (kapalıyken "Sonra" bölümü de görünür).
6. **Dil:** Ayarlar › Görünüm › Dil'i değiştir, uygulamaya dön, widget'ın
   metinleri o dile geçer (galerideki ad ve açıklama **cihaz** dilindedir —
   Android'de widget seçicinin davranışının aynısı).
7. **Tinted / clear:** Ana ekranda uzun bas › **Düzenle** › **Özelleştir** ›
   "Renkli / Koyu / Tonlu". Tonlu modda yalnız onay daireleri vurgu grubundadır
   (`widgetAccentable()`); geri kalan grafik monokromdur. "Gecikti" gibi
   durumlar renge değil metne bağlıdır, bu yüzden her modda okunur.
8. **Kilit ekranı:** Kilit ekranında saate uzun bas › Özelleştir › widget
   alanına "Hatırlatıcı"yı ekle.
9. **VoiceOver:** Dairelerin etiketi "Tamamla: <başlık>", "+" için "Yeni
   hatırlatıcı", daire widget'ı için "Bugün, N açık iş."

## 6. Bilinen sınırlar (cihazda kontrol edilmeli)

- **Widget'tan tamamlama gecikmeli işlenir.** Android'de widget dokunuşu arka
  plan isolate'inde anında depoyu güncellerken (`handleReminderHomeWidgetToggle`),
  iOS'ta widget extension'ında Flutter motoru yoktur. `home_widget`'ın iOS
  etkileşim desteği (`HomeWidgetBackgroundWorker`) extension'a Flutter'ı
  bağlamayı gerektirdiği için kullanılmadı — widget'ların bellek sınırı düşüktür
  ve bu, Mac'te doğrulanamayacak bir risk olurdu. Sonuç: tamamlanan bir
  hatırlatıcının **bildirimi**, uygulama açılana kadar iptal edilmez.
  Bunu değiştirmek istenirse `docs/ios-widget-setup.md` ve
  `CompleteReminderIntent.swift` başlangıç noktasıdır.
- **Görsel doğrulama yapılmadı:** hiçbir ekran görüntüsü alınamadı. Boşluklar,
  satır sayıları ve taşma davranışı cihazda gözden geçirilmeli (özellikle
  büyük yazı ölçeğinde).
- **Kilit ekranı dairesi** tasarımdaki "2/8 tamamlandı" göstergesi yerine
  bugünün açık iş sayısını gösterir: paylaşılan veri bilinçli olarak yalnız
  açık hatırlatıcıları taşır, tamamlanan sayısı çizim anında yeniden
  hesaplanamadığı için bayatlardı.
- **systemExtraLarge** (tasarımda opsiyonel) yapılmadı.
- `flutter build ios --no-codesign` entitlement'ları doğrulamaz
  (`CODE_SIGNING_ALLOWED=NO`), yani App Group'un gerçekten çalıştığı ilk kez
  cihazda görülür. En hızlı kontrol: widget veri bekliyorsa "Bugün boş"
  yazması **değil**, gerçek satırların görünmesi.

## 7. Veri sözleşmesi (değiştirirken)

Tek JSON, App Group `UserDefaults`'ta `widget_payload_v2` anahtarında; üç yerde
okunur/yazılır:

| Taraf | Dosya |
|---|---|
| Yazan (Dart) | `lib/home/widget_payload.dart` + `lib/services/reminder_home_widget_sync.dart` |
| Android | `android/app/src/main/kotlin/com/burakaydogmus/reminder/WidgetPayload.kt` |
| iOS | `ios/ReminderWidget/WidgetPayload.swift` |

Alan eklemek geriye uyumludur; anlamı değişen bir değişiklikte sürüm **ve**
anahtar artırılır ve üç taraf birlikte güncellenir. Zamana bağlı hiçbir şey
veriden okunmaz: bölümler, "Gecikti", "Yarın", sayılar ve sıradaki her çizimde
`dueAt` / `date` ile yeniden hesaplanır (widget, uygulama açılmadan günlerce
yaşar).

iOS'a özel **ek** anahtar: `widget_completions_v1` (widget → uygulama, "tamamla"
kuyruğu). Android bu anahtarı hiç okumaz.
