# Telefonda otomatik güncelleme (Obtainium)

Dışarıdan kurulan (sideload) bir APK kendini güncellemez. Mağazaya çıkmadan
otomatik güncelleme almanın yolu, APK'yı **GitHub Release** olarak yayınlamak ve
telefonda release'leri izleyen bir güncelleyici kullanmak.

## Yayın tarafı (CI)

`.github/workflows/release.yml` → Actions → **Release APK** → *Run workflow*
(master üzerinde). İş akışı:

1. İmzalama anahtarını **zorunlu** tutar. Debug anahtarıyla imzalanmış bir
   release, kurulu uygulamanın üzerine kurulamayacağı için baştan reddedilir
   (bkz. [`android-signing.md`](android-signing.md)).
2. `versionCode` olarak `date -u +%y%m%d%H` kullanır (ör. `26092618`).
   `pubspec.yaml` sabit `+8` taşıdığı için her derleme aynı numarayı üretiyordu
   ve hiçbir güncelleyici iki derlemeyi ayırt edemiyordu. Tarih tabanlı numara
   zamanla artar ve iş akışı yeniden adlandırılsa bile bozulmaz.
3. Mimari başına APK üretip **sabit adlarla** yükler:
   `reminder-arm64-v8a.apk`, `reminder-armeabi-v7a.apk`, `reminder-x86_64.apk`.
   Güncelleyici dosyayı adına göre bulur, bu yüzden adlar değişmemeli.
4. Her APK'nın imzasını doğrular ve `v<sürüm>+<numara>` etiketiyle release açar;
   notlara önceki etiketten bu yana gelen commit'leri yazar.

## Telefon tarafı (bir kez)

1. [Obtainium](https://github.com/ImranR98/Obtainium) kur (GitHub'daki
   release'inden; F-Droid'de de var).
2. **Add App** → URL olarak depo adresini ver:
   `https://github.com/burakaydogmus/reminder-android-app`
3. APK filtresi olarak `arm64-v8a` yaz — yoksa üç APK arasından seçim sorar.
4. İstersen arka plan kontrolünü aç (Obtainium → Settings → Background updates)
   ve kontrol aralığını seç. Android, kurulum için her seferinde onay ister;
   Obtainium'a "bilinmeyen uygulama kurma" izni verirsen tek dokunuşa iner.

Bundan sonra yeni bir release yayınlandığında Obtainium bunu görür ve
güncellemeyi kurar; veriler korunur (imza aynı).

**Bir varyantta kal:** Flutter split APK'lara mimariye göre `versionCode`
kaydırması verir (armeabi-v7a +1000, arm64-v8a +2000, x86_64 +3000). Cihazda hep
`arm64-v8a` kurulu kalmalı; başka bir varyanta geçmek sürüm düşürmesi sayılabilir
ve Android engeller.

## Alternatifler

- **Elle:** release sayfasından APK'yı indirip kurmak. Aynı anahtarla
  imzalandığı için üzerine güncelleme olarak iner, veri kaybı olmaz.
- **Uygulama içi güncelleme kontrolü:** Ayarlar'a "güncelleme var mı" düğmesi
  eklenebilir; `REQUEST_INSTALL_PACKAGES` izni gerektirir ve ileride mağaza
  incelemesinde açıklama ister. Bu yüzden şimdilik yapılmadı (ROADMAP F6.3b).
- **Play Store iç test kanalı:** mağazaya çıkıldığında otomatik güncellemenin
  asıl yolu bu olur; o zaman AAB + Play App Signing gerekir (ROADMAP F6.3).
