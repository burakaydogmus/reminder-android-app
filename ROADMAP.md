# Yol Haritası

Hatırlatıcı uygulamasının geliştirme planı. Her madde ayrı bir branch + worktree'de geliştirilir ve PR ile `master`'a alınır.

**Kararlar**

- **Platform:** Android + iOS (her özellik iki platformda doğrulanır)
- **Veri:** Drift (SQLite)
- **Bulut:** Şimdilik yerel; veri modeli ileride Firebase senkronuna hazır tasarlanır (UUID, `updatedAt`, soft delete)
- **Paket adı:** `com.burakaydogmus.reminder`
- **Tasarım yönü:** "Kor" — sıcak nötrler + tek vurgu rengi kor turuncusu (`#B8430F` / koyu `#FF9B63`), Google Sans Flex, Bugün ekranında zaman şeridi. Spesifikasyon: [`docs/design/kor-design-proposal.md`](docs/design/kor-design-proposal.md), ekran verisi: [`docs/design/kor-screens.json`](docs/design/kor-screens.json)
- **Navigasyon:** Bugün / Takvim / Listeler sekmeleri; Ayarlar dişli ikonunda
- **Dinamik renk:** Uygulama içinde isteğe bağlı ayar (varsayılan kapalı); Android widget'ları sistem renklerini kullanır
- **Cihaz içi yapay zekâ:** Şimdilik yok; hızlı yakalama kural tabanlı Türkçe ayrıştırıcıyla
- **Lisans:** MIT (`LICENSE`, repo public)
- **Kor kategori metni:** Açık temada "kor" renk anahtarlı kategori, kendi açık turuncu zemininde (`#FFDCC8`) metin olarak koyu kahve (`#4A1A00`, `onContainer`) kullanır; kor turuncusu (`#B8430F`) o zeminde yalnızca ikondur (4.24:1)
- **Takip:** Bu dosya; her PR ilgili maddeyi `[x]` yapar

**Durum işaretleri:** `[ ]` bekliyor · `[~]` devam ediyor · `[x]` tamamlandı

---

## Çalışma kuralları

- **Branch adı:** `<tür>/<kısa-ad>` — `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`
- **Commit:** [Conventional Commits](https://www.conventionalcommits.org/) — `feat(scope): ...`, `fix(scope): ...`
- **PR:** Açıklamada madde ID'si (örn. `F1.2`), yapılanlar, test adımları. CI geçmeden merge yok.
- **CI maliyeti (private repo):** `CI` (format + analyze + test) her kod PR'ında çalışır. `Android build` (release/R8) yalnızca `android/**` veya pubspec değişince, `iOS build` (macOS, 10× dakika) yalnızca `ios/**` veya pubspec değişince çalışır; ikisi de Actions sekmesinden elle başlatılabilir. Merge sonrası `master`'da CI çalışmaz. PR başına gereksiz push'tan kaçının (her push CI'ı yeniden başlatır).
- **Merge:** CI geçtikten sonra repo sahibi merge eder; branch merge sonrası silinir.
- **Çakışma riski:** `lib/bloc/reminder_cubit.dart`, `lib/services/notification_service.dart` ve veri modeli birçok maddeye dokunur — bu dosyalara dokunan maddeler **sıralı**, diğerleri paralel yürütülür.
- **iOS doğrulama:** Geliştirme ortamı Windows olduğundan iOS derlemesi CI'daki macOS runner'da yapılır; cihaz testi ayrıca planlanır.

---

## Faz 0 — Altyapı

Diğer tüm fazların temeli.

- [x] **F0.1 CI ve repo kuralları** · `chore/ci-setup`
  GitHub Actions: `flutter analyze`, `flutter test`, Android debug APK, iOS `--no-codesign` build (macOS runner). PR şablonu, `CLAUDE.md` (mimari + kurallar), `flutter_lints` güncellemesi.
- [x] **F0.2 Test altyapısı** · `test/baseline` · *bağımlı: F0.1*
  Model (`Reminder`, `Birthday` JSON, `nextOccurrence`, `daysUntilNext`) ve cubit unit testleri; `bloc_test`, `mocktail`. Mevcut davranışı kilitler.
- [x] **F0.3 Mimari temizlik** · `refactor/di-and-models` · *bağımlı: F0.2*
  `Reminder.copyWith`; tekrarlanan elle kopyalamaların kaldırılması; servisler için arayüz + constructor injection (`GeofenceService.instance` doğrudan çağrılarının kaldırılması); ortak sıralama fonksiyonu.

## Faz 1 — Kritik düzeltmeler

*F1.4 dışındaki maddeler F4.0'dan sonra başlar: F4.0 bildirim paketini (18 → 22), iOS minimumunu ve native yapılandırmayı değiştirdiği için bu düzeltmelerin iki kez yazılmasını önler.*

- [x] **F1.1 Konum hatırlatmaları arka planda çalışmıyor** · `fix/background-geofence` · *bağımsız hat*
  `geo_fencing_android` receiver'ı olayı yalnızca canlı Flutter engine'e iletiyor; uygulama kapalıyken bildirim gelmiyor. Reboot sonrası bölgeler yeniden kaydedilmiyor. Paket değişimi (arka plan callback destekli alternatif) veya native receiver'da doğrudan bildirim + boot receiver. iOS'ta region monitoring doğrulaması.
- [x] **F1.2 Widget'tan tamamlama doğum günü bildirimlerini siliyor** · `fix/widget-callback-sync`
  Callback yalnızca `syncFromReminders` (→ `cancelAll`) çağırıyor; doğum günleri yeniden kurulmuyor. Tek bir "tüm zamanlamaları senkronla" giriş noktası.
- [x] **F1.3 Widget değişikliğini açık uygulama eziyor** · `fix/widget-app-state-sync` · *bağımlı: F1.2*
  Uygulama resume'da / widget etkileşiminde depodan yeniden yükleme.
- [x] **F1.4 Bozuk kayıtta tüm verinin silinmesi** · `fix/repository-data-loss`
  Parse hatasında `[]` dönüp sonraki kayıtta her şeyin üzerine yazılması. Kayıt bazlı hata toleransı + ham verinin yedeklenmesi.
- [x] **F1.5 Kararlı bildirim ID'leri** · `fix/stable-notification-ids` · *bağımlı: F0.3*
  `String.hashCode` yerine deterministik hash (FNV-1a) veya saklanan ID; çakışma testi.
- [x] **F1.6 İzin akışı** · `fix/permission-flow`
  Açılışta tüm izinleri (exact alarm dahil) istemek yerine ihtiyaç anında, açıklamalı istek. `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` Play politikası kararı. İzin reddedilmişse ayarlarda uyarı.
- [x] **F1.7 Senkronizasyon verimliliği ve yarış durumu** · `fix/sync-diffing` · *bağımlı: F1.2*
  Her değişiklikte tüm bildirim ve geofence'lerin silinip yeniden kurulması yerine fark bazlı güncelleme; eşzamanlı `_persistAndSync` çağrılarının sıraya alınması.
- [x] **F1.8a Küçük hatalar (model + cubit)** · `fix/misc-domain-bugs`
  Liste her değişiklikten sonra `compareReminders` ile sıralanıyor · 29 Şubat doğum günleri artık yıl olmayan yıllarda 28 Şubat'ta · yıllık tekrarlayan doğum günü bildirim metni yaştan bağımsız (yaş uygulama içinde) · `Birthday.copyWith(note: () => null)` · `ReminderCubit`/`ReminderState` için enjekte edilebilir saat.
- [x] **F1.8b Editörde geçmiş saat uyarısı** · `fix/editor-past-time` · *bağımlı: F4.1*
  Geçmiş tarih/saat artık sessizce "1 dk sonra" olmuyor: chip'ler `error` rengine dönüyor, "Bu saat geçti" + "Yarın HH:mm mı?" öneri chip'i gösteriliyor, kayıt engelleniyor. Saati değişmemiş gecikmiş mevcut hatırlatıcı kaydedilebiliyor (orijinal saat korunuyor).
- [x] **F1.9 Release build** · `chore/release-build`
  `key.properties` yokken release build'in kırılması, R8/ProGuard kuralları, paket adı değişimi `com.fabirt.reminder` → `com.burakaydogmus.reminder` (Android `namespace`/`applicationId`, Kotlin paketleri, widget sınıf adı, App Group, iOS bundle ID).

## Faz 2 — Veri katmanı

- [x] **F2.1 Drift'e geçiş** · `feat/drift-storage` · *bağımlı: Faz 1 (F1.4, F1.5)*
  Tablolar: reminders, birthdays, settings. Senkrona hazır alanlar: `updatedAt`, `deletedAt`. `SharedPreferences` JSON'dan tek seferlik migration + migration testleri. Repository arayüzü korunur.
- [x] **F2.2 Yedekleme** · `feat/export-import` · *bağımlı: F2.1*
  JSON dışa/içe aktarma (paylaşım menüsü); sürümlü format.

## Faz 3 — Çekirdek özellikler

*F3.1–F3.3 veri modeline dokunur, sıralı ilerler.*

- [x] **F3.1 Tekrarlayan hatırlatmalar** · `feat/recurring-reminders`
  Günlük / haftalık (gün seçimi) / aylık / özel aralık; tamamlanınca bir sonraki tekrar.
- [x] **F3.2 Bildirim aksiyonları** · `feat/notification-actions`
  Bildirimde "Tamamla" ve "Ertele" (10 dk, 1 saat, yarın); bildirime dokununca ilgili hatırlatıcıyı açma.
- [ ] **F3.3 Alt görevler / checklist** · `feat/subtasks`
  Market listesi gibi kullanım için madde listesi; ilerleme göstergesi.
- [ ] **F3.4 Öncelik ve sabitleme** · `feat/priority-pin`
- [x] **F3.5 Liste etkileşimleri** · `feat/swipe-actions` · *bağımlı: F4.1*
  Kaydırarak tamamla (sağa) / ertele (sola kısa) / sil (sola uzun) + "Geri al" snackbar; her aksiyonun menü ve ekran okuyucu karşılığı.
- [x] **F3.6 Arama ve görünümler** · `feat/search-and-views` · *bağımlı: F4.1*
  Bugün zaman şeridi (Kaçanlar / şerit / Bugün bir ara), Takvim gündemi (Yaklaşan), Listeler › akıllı listeler (Zamansız dahil), Türkçe karakter duyarsız arama.

## Faz 4 — Arayüz ve deneyim ("Kor")

*Referans: [`docs/design/kor-design-proposal.md`](docs/design/kor-design-proposal.md) (§3 token'lar ve ekranlar, §5 Flutter notları) ve [`docs/design/kor-screens.json`](docs/design/kor-screens.json).*

- [x] **F4.0a Araç zinciri** · `chore/flutter-upgrade` · *bağımlı: F0.3, F1.1*
  **Önce doğrula:** araştırmadaki güncel sürüm iddiaları (Flutter 3.47, `material_ui`/`cupertino_ui` paketleri, iOS 15 minimumu, UIScene, `flutter_local_notifications` 22, `home_widget` 0.9.4) resmi kaynaklardan teyit edilir; tutmayan kısım o günkü kararlı sürüme göre uyarlanır. Kapsam: Flutter yükseltmesi + CI pin'i, `material_ui`/`cupertino_ui` geçişi, bağımlılık yükseltmeleri (F0.1'deki Android sürüm sabitlemelerinin gözden geçirilmesi dahil), native yapılandırma, `flutter_map` uyumu. **Görsel değişiklik yok.**
- [x] **F4.0b Kor tema token'ları + font** · `feat/kor-theme-tokens` · *bağımlı: F0.3*
  `lib/ui/theme/tokens/` (palet, `ColorScheme`, tipografi, şekil, boşluk, yükselti), `ThemeExtension`'lar (`KorColors`, `KorMotion`), `KorTheme.light/dark` (henüz bağlı değil), Google Sans Flex alt kümesi (latin + latin-ext; wght/opsz/ROND), kontrast testi. **Görsel değişiklik yok.**
- [x] **F4.1 Kor temel görünüm** · `feat/material3` · *bağımlı: F4.0a, F4.0b*
  `useMaterial3: true`, Kor `ColorScheme` (tüm roller elle), tipografi, bileşen temaları, yeni hatırlatıcı kartı, 3 sekmeli kabuk (Bugün / Takvim / Listeler) + Ayarlar dişliye, `Switch.adaptive`, editörde başlık önce + otomatik odak, kontrast testi.
- [x] **F4.2 Onboarding** · `feat/onboarding` · *bağımlı: F1.6, F4.1*
  4 adım: karşılama, "yazman yeterli" demosu, bildirim ön-izni, hazır; konum ve exact alarm izinleri ilk ihtiyaç anında bağlamsal sheet ile.
- [ ] **F4.3 Özel kategoriler** · `feat/custom-categories` · *bağımlı: F2.1, F4.1*
  Kullanıcı tanımlı kategori (ad, 12 renk anahtarından biri, ikon), sıralama; kategori hex değil `colorKey` saklar; zemin üzerindeki kategori metni `CategoryColors.onContainer`, ikon `fg` kullanır (kor anahtarı için zorunlu); mevcut "Diğer + özel ad" yapısının migration'ı.
- [ ] **F4.4 Takvim + doğum günleri** · `feat/calendar-view` · *bağımlı: F3.6*
  Hafta şeridi ⇄ ay ızgarası, sürükleyerek yeniden planlama (menü alternatifiyle), Doğum günleri ekranı, yılı bilinmeyen tarih.
- [ ] **F4.5 Erişilebilirlik** · `feat/a11y` · *F4.1'den itibaren her PR'ın kabul kriteri*
  Tasarım dokümanı §3.6'daki 12 kural (kontrast ≥4.5:1, 48 dp hedef, semantics aksiyonları, yazı ölçeği %200, Reduce Motion/Transparency); bu madde kapanış denetimi + golden testlerdir.
- [ ] **F4.6 Hızlı yakalama + Türkçe ayrıştırıcı** · `feat/quick-capture-nlp` · *bağımlı: F3.1, F3.4*
  iOS yakalama çubuğu / Android FAB, token vurgulu alan, `TurkishDateParser` (saf Dart, 200+ örnek cümlelik test tablosu, İ/ı testleri), "maddelere böl" önerisi.
- [ ] **F4.7 Hareket ve haptik** · `feat/motion-haptics` · *bağımlı: F4.1, F3.5*
  Spring token'ları, tamamlama "cookie" morph'u, şimdi çizgisi, container transform'lar, haptik ayarı, Reduce Motion yolları.

## Faz 5 — Widget ve platform

- [ ] **F5.1 Android widget v2** · `feat/android-widget-v2` · *bağımlı: F4.6*
  4 widget (Sıradaki 2×2, Bugün 4×2, kaydırılabilir Liste, Hızlı ekle 1×1); 8 satır sınırı kalkar, hap "+" düğmesi, doğum günleri, sistem dinamik renkleri.
- [ ] **F5.2 iOS widget** · `feat/ios-widget` · *bağımlı: F1.9*
  WidgetKit extension + App Group + App Intents (widget'tan tamamla); small/medium/large ve kilit ekranı aileleri, tinted/clear uyumu.
- [ ] **F5.3 Kısayollar** · `feat/app-shortcuts` · *bağımlı: F4.6*
  Android app shortcuts / iOS quick actions ("Yeni hatırlatıcı", "Market listesi", "Bugün", "Yeni doğum günü").
- [ ] **F5.4 iOS cam kromu** · `feat/ios-glass-chrome` · *bağımlı: F4.1*
  Cam tab bar, ayrı arama düğmesi, yakalama çubuğu; Reduce Transparency'de solid. Resmi Cupertino cam bileşeni çıkarsa onunla yeniden değerlendirilir.

## Faz 6 — Yayın hazırlığı

- [ ] **F6.1 Yerelleştirme** · `feat/i18n`
  ARB tabanlı `tr` / `en`; sabit metinlerin taşınması; sistem diline göre seçim.
- [x] **F6.2a Mağaza dokümanları** · `docs/store-readiness`
  [`docs/store/`](docs/store/): gizlilik politikası (tr/en), Play Data safety ve App Store gizlilik etiketi cevapları, izin/politika incelemesi, mağaza metni taslakları, lisans notu; kökte `CHANGELOG.md`. Kod değişikliği yok; takip maddeleri `docs/store/permissions-review.md` §8'de.
- [x] **F6.2b Mağaza uyumluluğu (atıf, gizlilik bağlantısı, lisanslar)** · `fix/store-compliance`
  Haritada tıklanabilir "© OpenStreetMap contributors" (telif sayfası); Ayarlar › Diğer: "Gizlilik politikası" (`lib/config/app_links.dart`) ve "Lisanslar" (`showLicensePage`); Google Sans Flex OFL `LicenseRegistry`'de. §8 madde 4, 7 (atıf), 9.
- [ ] **F6.2c Tam zamanlı alarm yedeği** · *bağımlı: F3.3*
  İzin reddedilince inexact zamanlama + izin değişince yeniden senkron; sonra `USE_EXACT_ALARM` kaldırılır.
- [ ] **F6.2 Mağaza hazırlığı** · `chore/store-readiness` · *bağımlı: F6.2a*
  Kalanlar: gizlilik politikasının herkese açık URL'de yayınlanması (+ `AppLinks.privacyPolicy` güncellemesi), arka plan konumu beyanı + video, mağaza görselleri, iOS izin metinleri, sürümleme, Play Console / App Store Connect kurulumu.
- [ ] **F6.3 Release pipeline** · `chore/release-workflow`
  Tag ile imzalı Android AAB ve iOS build; opsiyonel crash raporlama.

## Faz 7 — İleri (bulut)

- [ ] **F7.1 Firebase Auth + Firestore senkron** · `feat/cloud-sync` · *bağımlı: F2.1*
- [ ] **F7.2 Paylaşılan listeler** · `feat/shared-lists` · *bağımlı: F7.1*
- [ ] **F7.3 Rehberden doğum günü aktarma** · `feat/contacts-import`

---

## Önerilen yürütme sırası

```
F0.1 → F0.2 → F0.3 ─┬─ F1.1 (bağımsız hat) → F4.0a (araç zinciri)       F1.4 (paralel)
                    └─ F4.0b (tema token'ları + font; F1.1 ile paralel)
                                   ↓ F4.0a + F4.0b
                        ├─ F1.6 · F1.9 (paralel)
                        ├─ F1.2 → F1.3 → F1.7 → F1.5 → F1.8
                        └─ F4.1 Kor temel görünüm (Faz 1 ile paralel; lib/ui)
                                   ↓
                          F2.1 → F2.2
                                   ↓
          F3.1 → F3.2 → F3.3 → F3.4 → F4.6 (hızlı yakalama)
                                   ↓
          F3.5 · F3.6 → F4.4   ‖   F4.2 · F4.3 · F4.7 · F5.4
                                   ↓
          F5.1 · F5.2 → F5.3   ‖   F6.1 → F6.2 → F6.3
                                   ↓
                                  F7.x
```

- **F4.5 erişilebilirlik** tek seferlik bir adım değil: F4.1'den itibaren her PR'ın kabul kriteri, sonda kapanış denetimi.
- **F4.1 ile Faz 1 paralelliği:** F1.6 (izin arayüzü) ve F1.8 (editörde geçmiş saat) `lib/ui` dosyalarına da dokunur; hangisi önce merge edilirse diğeri rebase eder.
- **F1.6 artık F4.1'den sonra yürütülür:** izin durumu arayüzü yeni Ayarlar gruplu kartlarına (İzinler) ve yeni editörün "Nerede" kartına yerleşir; F4.1 bu bölümleri bilerek boş bıraktı.
