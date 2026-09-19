# Erişilebilirlik kontrol listesi (F4.5)

`docs/design/kor-design-proposal.md` §3.6'daki 12 kural, her birinin nasıl zorlandığı ve
cihazda elle yapılacak kontroller. **Erişilebilirlik her PR'ın kabul kriteridir:** arayüze
dokunan PR bu listeyi geçer, yeni ekran veya sheet `test/ui/a11y/` denetimine eklenir.

## Otomatik denetim (`test/ui/a11y/`)

```bash
flutter test test/ui/a11y                                   # yalnız denetim (155 test, ~15 sn)
flutter test test/ui/a11y --dart-define=A11Y_SHOTS=true     # + build/a11y_shots/*.png
```

`a11yAudit(açıklama, pump, platforms:, surface:)` (`a11y_audit.dart`) her ekranı
**açık/koyu × yazı ölçeği 1.0/2.0 × (Android, gerekirse iOS)** için ayrı bir test olarak çalıştırır
ve `expectAccessible` ile şunları doğrular (hepsi değerlendirilir, hata listesi tek seferde çıkar):

| Kontrol | Kaynak |
|---|---|
| Derleme/yerleşim hatası yok (RenderFlex taşması dahil); taşan flex'ler oluşturan widget'la listelenir | `tester.takeException()`, `overflowingFlexes` |
| Dokunma hedefi Android 48×48 dp / iOS 44×44 pt | `androidTapTargetGuideline` / `iOSTapTargetGuideline` |
| Dokunulabilir her düğümün etiketi var | `labeledTapTargetGuideline` |
| Metin kontrastı ≥ 4.5:1 (büyük metin ≥ 3:1), ekran görüntüsü üzerinden | `textContrastGuideline` |
| Semantics etiketlerinde çıplak `16:00` yok, `saat 16:00` | `unspokenTimes` |

Kapsanan ekranlar: Bugün (gecikmiş, tekrarlı, maddeli, sabitlenmiş, yüksek öncelikli, konumlu,
tamamlanmış örnek veriyle; boş durum), Takvim (hafta + gündem, ay ızgarası), Listeler, akıllı
listeler (Gecikmiş, Planlı, boş Konumlu), Arama (son aramalar, sonuçlar), Ayarlar, Doğum günleri,
konum seçici, hatırlatıcı editörü (yeni; tekrar + konum + maddelerle), hızlı yakalama
(`initialText` ile ayrıştırılmış metin), kategori editörü (yeni/mevcut), doğum günü editörü,
Ertele, Tekrar, onboarding 1–4. Kabuk sekmeleri, Arama sonuçları, Ayarlar, editör, yakalama ve
onboarding iOS kromuyla da çalışır.

Notlar:

- Testler kare "test fontu" ile çizer; harfler gerçek fonttan geniştir, yani taşma denetimi
  karamsardır (1.0'da bile sıkışan satırlar gerçek cihazda 1.3'te sıkışır).
- Kılavuzlar yalnız ekrandaki, kenara değmeyen düğümlere bakar. Sayfalar uzun bir yüzeyde
  (`surface:`) açılır; kabuk ekranları 390×2800, sheet'ler telefon yüksekliği 390×844.
- `link` düğümleri Flutter'ın dokunma hedefi kılavuzunca atlanır; OSM atfı için ayrı test var.
- `semantics_contract_test.dart` kılavuzların göremediğini sınar: kartın tek düğümü ve Türkçe
  etiketi, özel eylemler, "Gecikti" / "!!! Yüksek" metni, nav `selected`, filtre çipleri ve renk
  örnekleri `selected`, %200'de kart saati ve bölüm başlığı yerleşimi.

## 12 kural

| # | Kural | Nasıl zorlanıyor |
|---|---|---|
| 1 | Kontrast: metin ≥ 4.5, UI ≥ 3, alfa ile soluk metin yok | Token'lar: `test/ui/theme/contrast_test.dart`. Ekranlar: `textContrastGuideline` (denetim). Kod: renkler yalnız `colorScheme` / `context.korColors`; soluk metin `onSurfaceVariant`. |
| 2 | Dokunma hedefi 48 dp (görsel küçük olabilir) | `android/iOSTapTargetGuideline` (denetim); `KorSizes.minTouch`, `materialTapTargetSize.padded`; bağlantılar için `location_picker_page_test.dart` › "attribution has a 48 dp tap area". |
| 3 | Renk tek sinyal değil | `semantics_contract_test.dart` › "overdue card…" ("Gecikti" metni + ikon), "priority and pin are written…" ("!!! Yüksek"); kategori ikon + ad. |
| 4 | Semantics: kart tek düğüm, özel eylemler, nav `selected`, çip `checked`/`selected` | `semantics_contract_test.dart` (kart etiketi + Tamamla/Ertele/Sabitle/Düzenle/Sil, nav, takvim filtreleri, renk örnekleri); `labeledTapTargetGuideline`; `reminder_swipe_test.dart` › "semantics custom actions run the same handlers"; `subtasks_card_test.dart` / `category_list_section_test.dart` › "Yukarı taşı". |
| 5 | Sürükleme alternatifi (WCAG 2.5.7) | Kaydırma: kart menüsü + özel eylemler (`reminder_swipe_test.dart`); sıralama: `ReorderableListView` "Yukarı/Aşağı taşı" + satır menüsü; takvime sürükle-bırak: "Taşı…" (`calendar_page_test.dart` › "semantics: one node with a Taşı… custom action"). Yeni kart eylemi üç yola birden eklenir. |
| 6 | Yazı ölçeği %200 | Denetimin 2.0 varyantları (taşma yok). Kod: sabit metin yüksekliği yok (`minHeight`); `ReminderCard.stacksTime` (>1.3 saat başlığın altında), `SectionHeader` (sığmazsa eylem alta), `TimeRibbon.singleColumn`, sarılan satırlar (`OverflowBar`/`Wrap`), yatay kayan çip satırları. |
| 7 | Hareket azaltma | `MediaQuery.disableAnimationsOf` → `KorMotion.resolveOf`; testler: `kor_checkbox_test.dart`, `reminder_swipe_test.dart`, `kor_glass_tab_bar_test.dart`, `onboarding_flow_test.dart`, `quick_capture_sheet_test.dart` › "Reduce Motion…". |
| 8 | Şeffaflık/kontrast (iOS) | `A11yPrefs` (MethodChannel) → solid krom, `highContrastOf` → 2 px kenar: `home_shell_test.dart` › "Reduce Transparency renders solid chrome", `kor_glass_tab_bar_test.dart` › "high contrast: solid with a 2px outline". |
| 9 | Zaman sınırı: snackbar ≥ 5 sn, ekran okuyucuda 10 sn + odak "Geri al" | `UndoSnackBar`; `reminder_swipe_test.dart` › "screen reader: undo snackbar lasts 10 s…", "…hides after 5 s without a screen reader". Onaylar kendiliğinden kapanmaz. |
| 10 | Odak sırası; sheet açılınca ilk alan | Semantics sırası widget sırasıdır (başlık → özet → Kaçanlar → şerit → zamansız → yakalama → nav); `reminder_editor_sheet_test.dart` › "title comes first and is focused", `search_page_test.dart` › "…autofocus…". Kapanınca tetikleyiciye dönüş: elle (aşağıda). |
| 11 | Türkçe semantics, "saat 16:00" | `unspokenTimes` (denetim, tüm ekranlar); `KorFormat.spokenTime`; `KorFormat.upperTr`. |
| 12 | Haptik tek geri bildirim değil, kapatılabilir | Her haptiğin görsel karşılığı var; `KorHaptics.of(context)` yalnız; Ayarlar › "Titreşim geri bildirimi": `settings_page_test.dart`, `haptics_test.dart`, `kor_checkbox_test.dart` › "haptics off…". |

Yeni arayüz için kod kalıpları: ikon düğmelerine `tooltip`, özel dokunulabilirlere
`Semantics(button: true, label: …, selected:/checked: …)`, saat içeren etiketlerde
`KorFormat.spokenTime`, yan yana metin + eylem satırlarında `Expanded`/`Flexible` ya da
`OverflowBar`, kayan içerik üstünde yüzen yüzeylerde dokunuşun alttaki karta geçmemesi.

## Cihazda elle kontroller

Otomatik denetim ekran okuyucunun gerçek okuma sırasını, jestleri ve platform ayarlarını
sınayamaz. Sürüm öncesi (ve büyük arayüz PR'larında) Android'de TalkBack, iOS'ta VoiceOver ile:

| Ekran | Kontrol |
|---|---|
| Bugün | Okuma sırası başlık → özet → ilerleme → Kaçanlar → şerit (kronolojik, "Şimdi, saat 14:32") → Bugün bir ara → Tamamlananlar → yakalama/FAB → nav. Kart tek odak; "Eylemler" rotorunda / TalkBack eylemlerinde Tamamla, Ertele, Sabitle, Düzenle, Sil. Tamamlayınca 10 sn'lik "Geri al" odağı. |
| Takvim | Hafta şeridi günleri seçili durumuyla; ‹ › ile hafta değişimi; ▦ ile ay ızgarası; gündem satırında "Taşı…" eylemi ve tarih seçici. |
| Listeler | Akıllı liste kutuları sayılarıyla; Kategorilerim "Düzenle" kipinde "Yukarı/Aşağı taşı". |
| Arama | Alan otomatik odaklı; sonuç sayısı / "Notlarda" başlığı; filtre çiplerinin seçili durumu. |
| Ayarlar | Anahtarların açık/kapalı okunuşu, tema segmentleri, izin satırları. |
| Hatırlatıcı editörü | Açılınca odak başlıkta, kapanınca tetikleyen karta/FAB'a dönüyor; "Bu saat geçti" uyarısı okunuyor; maddelerde "Yukarı/Aşağı taşı". |
| Hızlı yakalama | Çipler "Zaman: yarın saat 09:00" gibi okunuyor; "Düz metne çevir"; "Eklendi … Geri al" duyuruluyor. |
| Kategori editörü | Renk adları + "seçili"; ikon adları. |
| Konum seçici | Harita erişilebilir değil (yalnız "Harita" düğümü): konum "Konumuma git" ve kayıtlı yer adıyla seçilebiliyor mu; OSM bağlantısı açılıyor mu. |
| Onboarding | "Adım n / 4" duyurusu, Atla, bildirim izni akışı. |

Ayrıca:

- **Switch Access (Android) / Switch Control (iOS):** her sekme, kart, sheet ve menü tek
  anahtarla dolaşılabiliyor; kaydırma eylemleri menüden de yapılabiliyor.
- **Yazı boyutu en büyük** (Android "Yazı tipi boyutu" + "Ekran boyutu", iOS Daha Büyük Metin):
  kesilen metin yok; iOS sekme etiketleri 1.3'te sabit (etiket semantics'te tam).
- **Hareket:** Android "Animasyonları kaldır", iOS "Hareketi Azalt": springler yerine kısa fade.
- **iOS:** Şeffaflığı Azalt, Kontrastı Artır, Düşük Güç Modu → solid tab bar ve yakalama çubuğu.
- **Klavye / harici giriş (tablet, Chromebook):** sekme sırası ve odak halkası görünür.
