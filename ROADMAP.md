# Yol Haritası

Hatırlatıcı uygulamasının geliştirme planı. Her madde ayrı bir branch + worktree'de geliştirilir ve PR ile `master`'a alınır.

**Kararlar**

- **Platform:** Android + iOS (her özellik iki platformda doğrulanır)
- **Veri:** Drift (SQLite)
- **Bulut:** Şimdilik yerel; veri modeli ileride Firebase senkronuna hazır tasarlanır (UUID, `updatedAt`, soft delete)
- **Paket adı:** `com.burakaydogmus.reminder`
- **Takip:** Bu dosya; her PR ilgili maddeyi `[x]` yapar

**Durum işaretleri:** `[ ]` bekliyor · `[~]` devam ediyor · `[x]` tamamlandı

---

## Çalışma kuralları

- **Branch adı:** `<tür>/<kısa-ad>` — `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`
- **Commit:** [Conventional Commits](https://www.conventionalcommits.org/) — `feat(scope): ...`, `fix(scope): ...`
- **PR:** Açıklamada madde ID'si (örn. `F1.2`), yapılanlar, test adımları. CI (analyze + test + build) geçmeden merge yok.
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

- [ ] **F1.1 Konum hatırlatmaları arka planda çalışmıyor** · `fix/background-geofence` · *bağımsız hat*
  `geo_fencing_android` receiver'ı olayı yalnızca canlı Flutter engine'e iletiyor; uygulama kapalıyken bildirim gelmiyor. Reboot sonrası bölgeler yeniden kaydedilmiyor. Paket değişimi (arka plan callback destekli alternatif) veya native receiver'da doğrudan bildirim + boot receiver. iOS'ta region monitoring doğrulaması.
- [ ] **F1.2 Widget'tan tamamlama doğum günü bildirimlerini siliyor** · `fix/widget-callback-sync`
  Callback yalnızca `syncFromReminders` (→ `cancelAll`) çağırıyor; doğum günleri yeniden kurulmuyor. Tek bir "tüm zamanlamaları senkronla" giriş noktası.
- [ ] **F1.3 Widget değişikliğini açık uygulama eziyor** · `fix/widget-app-state-sync` · *bağımlı: F1.2*
  Uygulama resume'da / widget etkileşiminde depodan yeniden yükleme.
- [ ] **F1.4 Bozuk kayıtta tüm verinin silinmesi** · `fix/repository-data-loss`
  Parse hatasında `[]` dönüp sonraki kayıtta her şeyin üzerine yazılması. Kayıt bazlı hata toleransı + ham verinin yedeklenmesi.
- [ ] **F1.5 Kararlı bildirim ID'leri** · `fix/stable-notification-ids` · *bağımlı: F0.3*
  `String.hashCode` yerine deterministik hash (FNV-1a) veya saklanan ID; çakışma testi.
- [ ] **F1.6 İzin akışı** · `fix/permission-flow`
  Açılışta tüm izinleri (exact alarm dahil) istemek yerine ihtiyaç anında, açıklamalı istek. `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` Play politikası kararı. İzin reddedilmişse ayarlarda uyarı.
- [ ] **F1.7 Senkronizasyon verimliliği ve yarış durumu** · `fix/sync-diffing` · *bağımlı: F1.2*
  Her değişiklikte tüm bildirim ve geofence'lerin silinip yeniden kurulması yerine fark bazlı güncelleme; eşzamanlı `_persistAndSync` çağrılarının sıraya alınması.
- [ ] **F1.8 Küçük hatalar** · `fix/misc-reminder-bugs`
  Liste yalnızca yüklemede sıralanıyor · 29 Şubat doğum günleri 1 Mart'a kayıyor · yıllık bildirimde yaş metni bayat kalıyor · geçmiş zaman sessizce "1 dk sonra" oluyor · `Birthday.copyWith` notu temizleyemiyor.
- [ ] **F1.9 Release build** · `chore/release-build`
  `key.properties` yokken release build'in kırılması, R8/ProGuard kuralları, paket adı değişimi `com.fabirt.reminder` → `com.burakaydogmus.reminder` (Android `namespace`/`applicationId`, Kotlin paketleri, widget sınıf adı, App Group, iOS bundle ID).

## Faz 2 — Veri katmanı

- [ ] **F2.1 Drift'e geçiş** · `feat/drift-storage` · *bağımlı: Faz 1 (F1.4, F1.5)*
  Tablolar: reminders, birthdays, settings. Senkrona hazır alanlar: `updatedAt`, `deletedAt`. `SharedPreferences` JSON'dan tek seferlik migration + migration testleri. Repository arayüzü korunur.
- [ ] **F2.2 Yedekleme** · `feat/export-import` · *bağımlı: F2.1*
  JSON dışa/içe aktarma (paylaşım menüsü); sürümlü format.

## Faz 3 — Çekirdek özellikler

*F3.1–F3.3 veri modeline dokunur, sıralı ilerler.*

- [ ] **F3.1 Tekrarlayan hatırlatmalar** · `feat/recurring-reminders`
  Günlük / haftalık (gün seçimi) / aylık / özel aralık; tamamlanınca bir sonraki tekrar.
- [ ] **F3.2 Bildirim aksiyonları** · `feat/notification-actions`
  Bildirimde "Tamamla" ve "Ertele" (10 dk, 1 saat, yarın); bildirime dokununca ilgili hatırlatıcıyı açma.
- [ ] **F3.3 Alt görevler / checklist** · `feat/subtasks`
  Market listesi gibi kullanım için madde listesi; ilerleme göstergesi.
- [ ] **F3.4 Öncelik ve sabitleme** · `feat/priority-pin`
- [ ] **F3.5 Liste etkileşimleri** · `feat/swipe-actions`
  Kaydırarak tamamla/sil + "Geri al" snackbar.
- [ ] **F3.6 Arama ve görünümler** · `feat/search-and-views`
  Arama; Bugün / Yaklaşan / Gecikmiş / Zamansız grupları; sıralama seçenekleri.

## Faz 4 — Arayüz ve deneyim

- [ ] **F4.1 Material 3 geçişi** · `feat/material3`
  `useMaterial3: true`, renk şeması, bileşenlerin güncellenmesi.
- [ ] **F4.2 Onboarding** · `feat/onboarding` · *bağımlı: F1.6*
  İlk açılış tanıtımı + izin adımları.
- [ ] **F4.3 Özel kategoriler** · `feat/custom-categories` · *bağımlı: F2.1*
  Kullanıcı tanımlı kategori (ad, renk, ikon), sıralama; mevcut "Diğer + özel ad" yapısının migration'ı.
- [ ] **F4.4 Doğum günleri sekmesi / takvim görünümü** · `feat/calendar-view`
- [ ] **F4.5 Erişilebilirlik** · `feat/a11y`
  Semantik etiketler, dokunma alanları, yazı ölçeği, kontrast.

## Faz 5 — Widget ve platform

- [ ] **F5.1 Android widget v2** · `feat/android-widget-v2`
  `RemoteViewsService` ile kaydırılabilir liste (8 satır sınırı kalkar), hızlı ekle butonu, doğum günleri, tema uyumu.
- [ ] **F5.2 iOS widget** · `feat/ios-widget`
  WidgetKit extension + App Group; `home_widget` iOS entegrasyonu.
- [ ] **F5.3 Kısayollar** · `feat/app-shortcuts`
  Android app shortcuts / iOS quick actions ("Yeni hatırlatıcı", "Yeni doğum günü").

## Faz 6 — Yayın hazırlığı

- [ ] **F6.1 Yerelleştirme** · `feat/i18n`
  ARB tabanlı `tr` / `en`; sabit metinlerin taşınması; sistem diline göre seçim.
- [ ] **F6.2 Mağaza hazırlığı** · `chore/store-readiness`
  Gizlilik politikası, mağaza görselleri, iOS izin metinleri, sürümleme + `CHANGELOG.md`.
- [ ] **F6.3 Release pipeline** · `chore/release-workflow`
  Tag ile imzalı Android AAB ve iOS build; opsiyonel crash raporlama.

## Faz 7 — İleri (bulut)

- [ ] **F7.1 Firebase Auth + Firestore senkron** · `feat/cloud-sync` · *bağımlı: F2.1*
- [ ] **F7.2 Paylaşılan listeler** · `feat/shared-lists` · *bağımlı: F7.1*
- [ ] **F7.3 Rehberden doğum günü aktarma** · `feat/contacts-import`

---

## Önerilen yürütme sırası

```
F0.1 → F0.2 → F0.3
          ├─ F1.1 (paralel, bağımsız hat)
          ├─ F1.4 · F1.6 · F1.9 (paralel)
          └─ F1.2 → F1.3 → F1.7 → F1.5 → F1.8
                                   ↓
                          F2.1 → F2.2
                                   ↓
          F3.x (sıralı) ‖ F4.1 · F4.5 (paralel)
                                   ↓
                     F5.x ‖ F6.1 → F6.2 → F6.3
                                   ↓
                                  F7.x
```
