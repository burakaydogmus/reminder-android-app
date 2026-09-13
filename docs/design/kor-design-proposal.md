# Hatırlatıcı — Yeni Tasarım Yönü Önerisi: **"Kor"**

*Tarih: 13 Eylül 2026 · Kapsam: araştırma + tasarım önerisi (kod değişikliği yok) · Eşlik eden dosya: `screens.json`*

> **Karar durumu (13 Eylül 2026, repo sahibi onayı):**
> 1. Kimlik: **Kor** turuncusu kabul edildi.
> 2. Navigasyon: **Bugün / Takvim / Listeler**, Ayarlar dişli ikonunda.
> 3. Araç zinciri: F4.0 **F0.3'ten hemen sonra**, Faz 1 bildirim düzeltmelerinden önce. Bu dokümandaki sürüm iddiaları F4.0'ın ilk adımında doğrulanır.
> 4. Dinamik renk: uygulama içinde **isteğe bağlı** (varsayılan kapalı).
> 5. Cihaz içi yapay zekâ: **şimdilik yok**.
>
> Roadmap eşlemesi için güncel kaynak `ROADMAP.md`'dir; §5.4'teki tablo öneri aşamasındaki halidir.

---

## 1. Araştırma özeti

Aşağıdaki 12 bulgu bu uygulamaya doğrudan etki ediyor. Genel trend listesi değil; her biri tasarım kararına dönüştürüldü.

### B1. Flutter'da Material ve Cupertino artık ayrı paketler; önce araç zinciri güncellenmeli
- Flutter 3.47 (12 Ağustos 2026) ile `material_ui` ve `cupertino_ui` 1.0'a ulaştı. Bunlar SDK'dan bağımsız, haftalık sürümlenebilen paketler. Güncel sürümler: `material_ui` 1.2.0, `cupertino_ui` 1.0.2. Aynı sürümde iOS minimumu 15'e çıktı ve iOS 27 uyumluluğu için UIScene yaşam döngüsü zorunlu hale geldi.
- **Karar:** Repo Flutter 3.29.2'ye sabitli. Tasarım geçişinden önce yeni bir "F4.0 araç zinciri + tema altyapısı" adımı gerekiyor (bkz. §5).
- Kaynaklar:
  - https://flutter.dev/blog/whats-new-in-flutter-3-47 — 3.47 sürüm notları: paketler 1.0, iOS 15 minimumu, UIScene zorunluluğu, Android yüksek kontrast algılama.
  - https://flutter.dev/blog/decoupling-material-cupertino — `dart fix` ile geçiş; Liquid Glass ve M3 Expressive'in resmi uygulamaları üzerinde "çalışma başladı".
  - https://pub.dev/packages/material_ui · https://pub.dev/packages/cupertino_ui — güncel sürümler; `cupertino_ui` içinde Liquid Glass bileşeni yok.

### B2. Material 3 Expressive Flutter'da resmi olarak henüz yok
- Bileşenler (button group, FAB menu, loading indicator, split button, toolbar) ve 35 yeni şekil SDK'da yok. Topluluk paketi `m3e_collection` 0.3.7 sürümünde, 10 aydır güncellenmemiş ve 33 beğenide.
- **Karar:** M3E'nin *ilkelerini* (şekil, spring hareket, vurgulu tipografi) kendi token'larımızla uygulayacağız. Bileşen paketine bağımlı olmayacağız.
- Kaynaklar:
  - https://github.com/flutter/flutter/issues/168813 — "aktif geliştirilmiyor"; yeni işler ayrılmış paketlerde yapılacak.
  - https://pub.dev/packages/m3e_collection — bakım sinyali zayıf.

### B3. Expressive tasarımın ölçülmüş faydası var: ana aksiyon daha hızlı bulunuyor
- Google 46 çalışma ve 18.000+ katılımcıyla, expressive tasarımda kilit öğelerin 4 kata kadar daha hızlı bulunduğunu raporladı. Daha büyük dokunma alanları ve yüksek kontrast yaşlı kullanıcılara da yardımcı oluyor.
- Hareket sistemi spring tabanlı. androidx `ExpressiveMotionTokens` değerleri: spatial fast 0.6/800, default 0.8/380, slow 0.8/200; effects damping 1.0 ile 3800/1600/800. Standard şema ise spatial damping 0.9 ile 1400/700/300.
- **Karar:** Yakalama düğmesi ve "şimdi" çizgisi tek, belirgin vurgu olacak. Hareket token'ları doğrudan bu değerler.
- Kaynaklar:
  - https://design.google/library/expressive-material-design-google-research — araştırma verisi.
  - https://raw.githubusercontent.com/androidx/androidx/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExpressiveMotionTokens.kt — spring değerleri (StandardMotionTokens.kt ile birlikte).

### B4. Liquid Glass iOS 27'de de sürüyor, ama okunurluk ve erişilebilirlik yönünde törpülendi
- iOS 27 (WWDC 2026) değişiklikleri:
  - Ayarlar'a şeffaflık kaydırıcısı eklendi (çok şeffaftan tamamen renkliye).
  - Karmaşık içeriğin arkası daha iyi dağıtılıyor.
  - Cam kenarları koyulaştı.
  - Kaydırılan içerik altında tek tip toolbar zemini geliyor.
  - Reduce Transparency ve Increase Contrast ayarlarına uyum sağlanıyor.
- iOS 26 kalıpları: tab bar içeriğin üstünde yüzüyor ve kaydırınca küçülüyor, ayrı bir arama sekmesi var, tab bar üstünde "accessory" alanı var.
- **Karar:** Cam yalnızca yüzen kontrollerde (tab bar, yakalama çubuğu, harita üstü düğmeler) kullanılacak. İçerik kartları opak kalacak.
- Kaynaklar:
  - https://www.macrumors.com/2026/06/10/how-liquid-glass-is-changing-in-ios-27/ — iOS 27 cam değişiklikleri.
  - https://medium.com/design-bootcamp/dont-design-junk-in-the-new-ios-26-tab-bar-4de8e842da89 ve https://www.learnui.design/blog/ios-design-guidelines-templates.html — yüzen tab bar, search tab, bottom accessory.

### B5. Flutter'da native Liquid Glass yok; iki topluluk yolu var ve ikisinin de maliyeti var
- Flutter'ın iOS dokümanında Liquid Glass hâlâ "uygulanmadı" (#170310) olarak geçiyor.
- `liquid_glass_widgets` 1.5.0: çok aktif, shader tabanlı. Reduce Motion ve High Contrast için otomatik fallback'i var, Flutter ≥3.41 istiyor.
- `adaptive_platform_ui` 0.1.111: platform view ile gerçek UIKit çiziyor. Bazı parçaları "yalnızca prototip" olarak işaretli.
- **Karar:** Platform view yoluna gitmeyeceğiz (gesture ve navigasyon riski). Yüzen kontrollerde shader tabanlı cam, altında solid fallback kullanılacak. Resmi `cupertino_ui` cam bileşenleri gelince değiştirilecek.
- Kaynaklar:
  - https://docs.flutter.dev/platform-integration/ios/ios-latest — desteklenmeyen iOS 26+ özellikleri.
  - https://github.com/flutter/flutter/issues/170310 — Cupertino'da cam çalışması paketlere taşındı.
  - https://pub.dev/packages/liquid_glass_widgets · https://pub.dev/packages/adaptive_platform_ui

### B6. Doğal dille hızlı yakalama artık temel beklenti, Türkçe dahil
- Todoist Mayıs 2026'da Türkçe tarih ayrıştırmayı ekledi, sonra dotless "I" hatasını düzeltti. Ağustos 2026'da Quick Add sadeleşti: proje/tarih aksiyonları yazmaya başlayınca çıkıyor.
- iOS 27 Reminders "get groceries at 6pm tonight" gibi girdiden tarih, saat ve konumu dolduruyor.
- TickTick NLP ve widget'tan hızlı ekleme sunuyor.
- **Karar:** Türkçe kural tabanlı ayrıştırıcıyla "yazman yeterli" yakalama deneyimi. Ürünün imza özelliği olacak.
- Kaynaklar:
  - https://www.todoist.com/help/articles/2026-changelog-HD3jJAtLd — Türkçe NLP, Quick Add yenilemesi, Android M3 Expressive UI (18 Haziran).
  - https://www.macrumors.com/guide/ios-27-calendar-reminders/ — iOS 27 Reminders NLP ve extra-large widget.
  - https://ticktick.com/features — NLP, timeline, widget'tan ekleme.

### B7. Tekrarlayan görevlerde asıl zorluk istisnalar
- Things 3.23 (19 Ağustos 2026) en çok istenen iki şeyi getirdi: tekrarlayan bir görevi *erken tamamlama* ve *yalnızca bu seferlik yeniden planlama*.
- **Karar:** F3.1 tasarımı bu iki senaryoyu baştan destekleyecek. Tamamlanan tekrarlayan kart kaybolmayacak, "Sonraki: …" gösterecek.
- Kaynak: https://culturedcode.com/things/blog/ — "Repeating To-Dos, Refined".

### B8. Zaman çizelgesi odaklı planlama yükselişte
- Tiimo, renk kodlu görsel gün çizelgesiyle 2025 iPhone Yılın Uygulaması seçildi. TickTick'in timeline görünümünde süreler sürüklenerek ayarlanıyor.
- **Karar:** "Bugün" ekranı düz liste yerine dikey zaman şeridi olacak ve "şimdi" çizgisi taşıyacak.
- Kaynaklar:
  - https://techcrunch.com/2025/12/04/ai-finds-its-way-into-apples-top-apps-of-the-year
  - https://www.howtogeek.com/productivity-app-is-a-iphone-app-of-the-year-heres-why-i-love-it/
  - https://ticktick.com/features

### B9. Widget'lar birinci sınıf yüzey
- Google Tasks widget'ı Haziran 2026'da M3 Expressive'e geçti: sağ üstte renkli hap şeklinde "+" düğmesi, koyu temada doğru dinamik renk.
- iOS 27, Reminders ve Calendar için ekranın tamamını kaplayan extra-large widget getirdi.
- Apple widget'larında tinted/clear/accented render modları var; tasarımın monokrom çalışabilmesi gerekiyor.
- Android'de canonical layout'lar ve renk token'ları rehberi mevcut.
- **Karar:** F5.1 ve F5.2 için ayrıntılı widget spec'i hazırlandı (§3.8).
- Kaynaklar:
  - https://9to5google.com/2026/06/04/google-tasks-expressive-widget/
  - https://developer.apple.com/design/human-interface-guidelines/widgets
  - https://developer.android.com/design/ui/widget
  - https://pub.dev/packages/home_widget (0.9.4; widget'lar yine native yazılıyor)

### B10. Live Updates ve Live Activities bu uygulama için moda, kullanılmamalı
- Android dokümanı Live Updates için "yaklaşan takvim etkinlikleri" ve "uyarıları" açıkça *uygunsuz kullanım* olarak listeliyor. Uygun olanlar yalnızca devam eden, başı ve sonu belli aktiviteler (navigasyon, teslimat).
- **Karar:** Hatırlatıcıda Live Update veya Live Activity yok. Güç, bildirim aksiyonları ve widget'larda.
- Kaynak: https://developer.android.com/develop/ui/views/notifications/live-update

### B11. Erişilebilirlik artık yasal zorunluluk
- European Accessibility Act 28 Haziran 2025'ten beri yürürlükte. AB tüketicisine yönelik mobil uygulamalardan EN 301 549, yani WCAG 2.2 AA bekleniyor. WCAG 2.2'nin yeni kriterleri arasında dragging alternatifi (2.5.7) ve hedef boyutu (2.5.8) var.
- Flutter 3.47 Android yüksek kontrast ve renk ters çevirmeyi algılıyor.
- **Karar:** Her swipe ve sürükleme için menü/semantics alternatifi, 48dp hedef, tüm token'larda AA kontrast.
- Kaynaklar:
  - https://www.levelaccess.com/compliance-overview/european-accessibility-act-eaa/
  - https://flutter.dev/blog/whats-new-in-flutter-3-47

### B12. Değişken fontlar ve cihaz içi AI: biri bugün kullanılır, diğeri sonraya kalır
- **Font:** Google Sans Flex, Google Fonts'ta açık lisansla yayında. Eksenleri: wght, wdth, opsz, slnt, GRAD ve **ROND** (yuvarlaklık). `latin-ext` alt kümesi Türkçe karakterleri (ş, ğ, İ, ı) kapsıyor. Tek dosyadan hem samimi (yuvarlak) hem okunaklı (düz) stil çıkıyor. Bugünkü Comfortaa'nın "yumuşak" karakteri korunurken okunurluk sorunu çözülüyor.
- **Cihaz içi AI:** `flutter_local_ai` / `edge_gen_ai` Apple Foundation Models ve Gemini Nano'ya erişiyor. Ama iOS 26+ Apple Intelligence (iPhone 15 Pro+) veya Pixel 8+ / S23+ gibi cihazlarla sınırlı.
- **Karar:** Font hemen kullanılacak. AI yalnızca ileride, opsiyonel "cümleyi maddelere böl" yardımcısı olarak düşünülecek. Temel ayrıştırıcı kural tabanlı ve her cihazda çalışan olacak.
- Kaynaklar:
  - https://design.google/library/google-sans-flex-font · https://fonts.google.com/specimen/Google+Sans+Flex (metadata: latin-ext, ROND 0–100)
  - https://github.com/kekko7072/flutter_local_ai · https://pub.dev/packages/edge_gen_ai

**Moda / düşük değer olarak elenenler:**
- Her yerde glassmorphism (okunurluk ve performans maliyeti, iOS 27 bile geri adım attı).
- Ana sayfada bento: yalnızca "Akıllı listeler" sayaç ızgarasında kullanılacak, çünkü orada sayıyı bir bakışta göstermek işe yarıyor.
- Live Activities.
- Zorunlu AI.
- Aşırı konfeti ve animasyon: yalnızca "hepsi tamam" anında, bir kez.

---

## 2. Mevcut tasarımın eleştirisi

### 2.1 Görsel sistem (`lib/ui/theme/app_theme.dart`)
- **`useMaterial3: false`.** M2 bileşenleri (dialog, date/time picker, SnackBar, Switch) 2026'da hem Android hem iOS'ta eski görünüyor. `ColorScheme`'de yalnızca 6 rol tanımlı. `surfaceContainer*`, `outline*`, `tertiary`, `inverse*` gibi roller varsayılana düşüyor ve light/dark tutarlılığı kopuyor.
- **`TextTheme` eksik.** Yalnızca `displayLarge`, `headlineMedium`, `bodyLarge/Medium/Small` tanımlı. `titleSmall`, `titleLarge` ve `labelLarge` kullanılıyor (liste başlıkları, editör başlıkları) ama tanımsız, bu yüzden boyut ve ağırlık rastgele geliyor. `bodyLarge` 20px tanımlanmış ve her kullanımda `fontSize: 16` ile eziliyor.
- **Comfortaa** bir display fontu. Geniş, geometrik yapısı nedeniyle 11–14px'de okunurluğu düşük (l/I/1 benzerliği, dar alanda erken kesilme). Uygulama bunu gövde ve etiket metninde bile kullanıyor.
- **Renkler koda gömülü ve kontrastları yetersiz.** Beyaz zemin üzerinde metin/ikon olarak (ölçülen oranlar):

  | Renk | Kullanım | Beyaz üstünde | %12 tint üstünde ikon |
  |---|---|---|---|
  | `#FB8C00` Günlük | kategori etiketi, seçili chip beyaz ikon | **2.37** | **2.14** |
  | `#43A047` Market | 〃 | **3.30** | **2.92** |
  | `#1E88E5` İş | 〃 | **3.68** | 3.20 |
  | `#EC407A` Sağlık/Doğum günü | seçili chip beyaz metin, geri sayım | **3.76** | 3.22 |
  | `#8762FF` Diğer | 〃, dark nav beyaz ikon | **4.02** | 3.48 |
  | `#E53935` Ev | 〃 | **4.23** | 3.57 |

  AA metin eşiği 4.5, UI bileşeni eşiği 3.0. Satır alt başlığı (kategori rengi %85, tint'li kart üzerinde) **2.52**, "Zamansız" (%38 siyah) **2.64**, tamamlanan başlık (%45 siyah) **3.31**. Hepsi AA metin eşiğinin altında.
- **Kategori ve öncelik rengi tek sinyal.** Kırmızı "Ev" kategorisi ile hata/gecikme rengi karışabilir. Gecikmiş öğe için metin veya ikon ipucu da yok.

### 2.2 Navigasyon (`lib/ui/home/bottom_nav_bar.dart`, `home_page.dart`)
- **Nav bar yalnızca 2 hedef taşıyor** (liste ve ayarlar). Seyrek kullanılan Ayarlar birincil nav slotunu işgal ediyor. Bugün/Yaklaşan/Takvim/Doğum günleri için yer yok.
- **İkonlar `GestureDetector` içinde,** `Semantics`, `tooltip` ve görünür etiket yok. Ekran okuyucu "düğme" bile demiyor.
- **Seçili pill'in konumu `GlobalKey` ve `localToGlobal` ile ölçülüyor.** Döndürme, yazı ölçeği veya RTL durumunda kayabilir. `easeInOutSine` sabit süreli; spring değil.
- **`PopScope` geri tuşunu ele geçiriyor.**
- **Nav 64px bar + 32px alt boşluk + SafeArea tutuyor ve içerik bunu sabit kodla telafi ediyor.** `reminder_list_page.dart` alt padding `32 + 64 + 24`, `settings_page.dart` `32 + 64 + 40`. Ölçü değişince içerik altta kalıyor.

### 2.3 Liste ekranı (`lib/ui/reminders/reminder_list_page.dart`)
- **İlk hatırlatıcıdan önce ~300px dikey alan harcanıyor:** başlık, alt başlık, 84px kategori şeridi, 96px doğum günü şeridi ve boşluklar. Ekranın ~%40'ı "filtre ve süs" oluyor.
- **Zaman boyutu yok.** Yalnızca "Açık / Tamamlandı" bölümleri var: Bugün, Gecikmiş, Yaklaşan veya zamansız ayrımı yapılmıyor. Liste yalnızca yüklemede sıralanıyor (ROADMAP F1.8). Gecikmiş öğe görsel olarak normal öğeyle aynı.
- **Tamamlama gizli ve belirsiz.** Kategori ikon rozetine dokunmak tamamlıyor (`GestureDetector(onTap: toggleDone)`). Kullanıcı rozeti "kategori" sanıyor, onay kutusu değil. Hedef 44px (<48dp).
- **Silme gizli ve geri alınamaz.** Uzun bas → "Silinsin mi?" diyaloğu → kalıcı silme. Undo yok, sürükleme alternatifi yok.
- **İki üst üste FAB** (pembe küçük pasta + ana "+"). Hangisinin ne yaptığı etiketsiz; liste içeriğinin sağ altını örtüyor.
- **Kategori filtre "chip"leri** 52px daire ikon, 11px etiket ve 10px sayaç rozetinden oluşuyor. `selected` durumu semantics'e yansımıyor.
- **Performans:** `ListView(children: …map)` builder değil; yüzlerce öğede tüm satırlar bir kerede kuruluyor.

### 2.4 Editörler (`reminder_editor_sheet.dart`, `birthday_editor_sheet.dart`)
- **Öncelik sırası ters.** Sheet önce 88px kategori seçici gösteriyor, başlık alanı sonra geliyor ve `autofocus` yok. En sık aksiyon olan "yaz, kaydet" 3 dokunuş istiyor.
- **"Diğer" seçilince özel ad zorunlu.** Boşsa kayıt engelleniyor. Varsayılan kategori zaten "Diğer" olduğundan her yeni hatırlatıcı bu engele takılıyor.
- **Zaman seçimi dağınık:** "Zamanla / bildir" switch'i, ardından ayrı tarih ve saat `ListTile`'ları. **Geçmiş saat sessizce "şimdi + 1 dk"** oluyor ve kullanıcı fark etmiyor.
- **Hatalar Snackbar ile bildiriliyor,** inline değil. Konum hatası 5 saniyelik uzun bir paragraf.
- **Konum özeti ham koordinat gösteriyor** (`41.00820, 28.97840 · 150 m`).
- **Tutarsızlık:** Doğum günü editöründe Sil düğmesi var, hatırlatıcı editöründe yok (yalnızca listede uzun basma).
- **Doğum günü offset chip'leri** 12px metin, seçili halde beyaz/`#EC407A` = 3.76. Yıl bilinmiyorsa girilemiyor.

### 2.5 Ayarlar (`lib/ui/settings/settings_page.dart`)
- **Başlık ortalı, bölüm stilleri tutarsız.** "Görünüm" ikonlu başlık, "Bildirimler" düz `Text`.
- **`RollingSwitchButton` özel bir switch.** Platform switch'i değil; semantics ve dokunma alanı doğrulanmalı. İzin *durumu* gösterilmiyor: bildirim veya konum izni reddedilmişse kullanıcı bunu hiçbir yerde görmüyor (F1.6 ile uyumsuz).
- **"Tüm verileri sıfırla"** yalnızca tek onaylı ve öncesinde yedek önerisi yok.

### 2.6 Konum seçici (`lib/ui/maps/location_picker_page.dart`)
- **İzin açıklamasız isteniyor.** `initState` → `_initCenter()` sayfa açılır açılmaz sistem diyaloğunu tetikliyor; ön açıklama yok. Reddedilirse İstanbul varsayılanına sessizce düşülüyor.
- **Kullanıcıya geliştirici mesajı gösteriliyor:** "`--dart-define=GOOGLE_MAPS_KEY=...`".

### 2.7 Android widget (`android/app/src/main/res/layout/reminder_widget_layout.xml`)
- 8 sabit, elle kopyalanmış satır var, kaydırma yok.
- Onay kutusu bir `TextView` karakteri (`@string/widget_check_unchecked`).
- 13sp metin, hızlı ekle düğmesi yok, tarih/saat yok, gecikme yok, doğum günü yok.
- Dinamik renk ve Android 12+ sistem köşe yarıçapı kullanılmıyor.

### 2.8 UX sürtünme özeti
1. Yakalama yavaş (kategori → başlık → switch → tarih → saat).
2. "Ne zaman ne var?" sorusuna cevap yok.
3. Tamamlama ve silme gizli, geri alınamaz.
4. İzinler ya hep birden ya açıklamasız isteniyor, durumu görünmüyor.
5. Kontrast ve semantik eksikleri EAA/WCAG 2.2 AA'yı karşılamıyor.

---

## 3. Yeni tasarım yönü: **"Kor"**

### Konsept
**Gün, sakin ve sıcak bir kâğıt üzerinde akan bir zaman şeridi. Tek canlı renk olan "kor" turuncusu yalnızca *şimdi*yi, *kaçanları* ve *ekle*yi işaretliyor.** Her şey önce yazıyla yakalanıyor ("yarın 18:00 ekmek al #market"). Uygulama anlamı çözüp zaman şeridine yerleştiriyor. Tamamlanan her iş, şeritte küçük bir sönmüş kor düğüme dönüşüyor.

### Neden bu, neden 2026
- **Hatırlatıcının asıl malzemesi zaman ve dikkat.** Mor marka rengi dekoratif, "kor" ise *anlamlı*: dikkat gereken tek şey. Bu, M3 Expressive araştırmasındaki "kilit aksiyonu hızlı bulma" bulgusunu (B3) doğrudan uyguluyor.
- **Zaman şeridi (B8) + Türkçe doğal dil yakalama (B6)** en iyi uygulamaların birleştiği iki kalıp. İkisi de mevcut iki büyük acıyı (ne zaman ne var, yavaş ekleme) çözüyor.
- **Tek codebase'de iki platformda doğal hissettiriyor.** İçerik tamamen bizim token'larımızla opak ve markalı. Yalnızca "krom" platforma uyuyor: iOS'ta cam tab bar ve arama düğmesi, Android'de M3E yüzen nav ve FAB. M3E ve Liquid Glass'ın resmi Flutter uygulamaları henüz yok (B2, B5); içerik katmanını onlara bağlamamak geçiş riskini düşürüyor.
- **Sıcak nötrler** (`#FAF7F2` kâğıt ve `#14120F` gece kömürü) saf beyaz/siyaha göre göz yormuyor. Kategori renkleri hem açık hem koyu zeminde AA geçiyor.

---

### 3.1 Design token'ları

#### Renk — Light

| Rol | Hex | Kullanım | Kontrast |
|---|---|---|---|
| background | `#FAF7F2` | ekran zemini (sıcak kâğıt) | — |
| surface | `#FFFFFF` | kartlar, sheet | — |
| surfaceContainerLow | `#F6F2EC` | tamamlanan kart | — |
| surfaceContainer | `#F1ECE3` | chip, input zemini | — |
| surfaceContainerHigh | `#EAE4D9` | nav bar, arama alanı | — |
| onSurface | `#1F1B16` | ana metin | bg 16.0 · surface 17.1 · container 14.6 |
| onSurfaceVariant | `#5C554C` | ikincil metin, saat | bg 6.9 · surface 7.4 · container 6.2 |
| outline | `#8C8479` | checkbox kenarı, ayraç (UI ≥3) | bg 3.45 · surface 3.69 · container 3.14 |
| outlineVariant | `#DDD5CA` | dekoratif ayraç, rail | (dekoratif) |
| **primary (Kor)** | `#B8430F` | şimdi çizgisi, gecikme metni, ana buton | bg 5.1 · surface 5.5 · container 4.6 |
| onPrimary | `#FFFFFF` | primary üstü | 5.46 |
| primaryContainer | `#FFDCC8` | seçili chip, nav göstergesi | — |
| onPrimaryContainer | `#4A1A00` | primaryContainer üstü | 11.3 (Kor rengi bu zeminde yalnız ikon: 4.24) |
| tertiary | `#2F5A8A` | ertele, bilgi | bg 6.7 |
| tertiaryContainer / on | `#D6E4F7` / `#0F2A47` | izin banner'ı | — |
| success | `#2F6B34` | tamamla swipe, izin "açık" | bg 6.0 |
| error | `#B3261E` | sil, hata | bg 6.1 |
| errorContainer / on | `#F9DEDC` / `#410E0B` | — | — |
| inverseSurface / onInverse | `#33302B` / `#EDE6DC` | snackbar | 10.6 |
| inversePrimary | `#FF9B63` | snackbar "Geri al" | 6.33 |

#### Renk — Dark

| Rol | Hex | Kontrast |
|---|---|---|
| background | `#14120F` | — |
| surface | `#1D1B17` | — |
| surfaceContainerLow | `#221F1B` | — |
| surfaceContainer | `#2A2621` | — |
| surfaceContainerHigh | `#35302A` | — |
| onSurface | `#EDE6DC` | bg 15.1 · surface 13.9 · container 12.1 |
| onSurfaceVariant | `#B9B0A4` | bg 8.7 · container 7.0 |
| outline | `#857D72` | bg 4.6 · container 3.7 · containerHigh 3.2 |
| outlineVariant | `#4A443C` | dekoratif |
| **primary (Kor)** | `#FF9B63` | bg 9.0 · container 7.2 |
| onPrimary | `#3B1500` | 7.83 |
| primaryContainer / on | `#6A2A08` / `#FFDCC8` | 8.38 |
| tertiary | `#9CC3F0` | bg 10.2 |
| success | `#8FD08F` | bg 10.3 |
| error | `#FFB4AB` | bg 11.0 |
| inverseSurface / onInverse | `#EDE6DC` / `#1F1B16` | 13.8 |
| inversePrimary | `#9A380B` | 5.76 |

**Cam (yalnız iOS yüzen kontroller):**
- Light: tint `rgba(255,255,255,.72)`, 1px `rgba(31,27,22,.08)` kontur.
- Dark: tint `rgba(29,27,23,.64)`, 1px `rgba(237,230,220,.10)` kontur.
- Blur σ = 24.
- Reduce Transparency, Increase Contrast veya düşük güç modunda cam yerine solid `surfaceContainerHigh`.

#### Kategori renkleri

`fg` ikon, metin ve dolu zemin için; `container` tonlu zemin için. Tabloda `fg`'nin **arka plan / surface / kendi container'ı** üzerindeki oranları var. Light'ta `fg` üzerine beyaz, dark'ta `fg` üzerine `#14120F` metin yazılıyor.

| Kategori | İkon | Light fg / container | Light oranlar | Beyaz metin fg üstünde | Dark fg / container | Dark oranlar | `#14120F` fg üstünde |
|---|---|---|---|---|---|---|---|
| Market | shopping_basket | `#2E7031` / `#DDEFD9` | 5.65 / 6.04 / 5.01 | 6.04 | `#8ED68A` / `#1E3B1E` | 10.8 / 9.9 / 7.1 | 10.8 |
| Ev | home | `#00696B` / `#D2EEEC` | 6.08 / 6.50 / 5.31 | 6.50 | `#6FD6D2` / `#0F3534` | 10.9 / 10.0 / 7.7 | 10.9 |
| İş | work | `#2D5EA8` / `#DDE7F7` | 5.99 / 6.41 / 5.14 | 6.41 | `#9EC2F7` / `#1A2C47` | 10.3 / 9.4 / 7.7 | 10.3 |
| Sağlık | favorite | `#B0265E` / `#FADCE7` | 5.98 / 6.39 / 5.01 | 6.39 | `#FF9EC2` / `#48182C` | 9.7 / 8.9 / 7.6 | 9.7 |
| Günlük | wb_sunny | `#8A5300` / `#F8E6C8` | 5.92 / 6.33 / 5.17 | 6.33 | `#F2BE6B` / `#3F2C0E` | 11.0 / 10.1 / 7.8 | 11.0 |
| Diğer | label | `#6546C8` / `#E7E0FA` | 6.02 / 6.43 / 5.04 | 6.43 | `#C2B1FF` / `#2D2450` | 9.8 / 9.0 / 7.5 | 9.8 |
| Doğum günü | cake | `#9A2A8A` / `#F6DDF1` | 6.40 / 6.84 / 5.38 | 6.84 | `#F2A3E4` / `#44193D` | 9.9 / 9.1 / 7.7 | 9.9 |

- **Değişiklikler:** "Ev" kırmızıdan teal'e geçti (hata/gecikme rengiyle çakışmasın). "Diğer" eski marka morunu yaşatıyor.
- **Kullanıcı kategori paleti** (F4.3) 12 renk: yukarıdaki 7 renk + kor `#B8430F`, lacivert `#3A4A9C`, zeytin `#5B6300`, kiremit `#9C3B2E`, arduvaz `#4F5B66`. Dark karşılıkları `screens.json` içinde. Bu ek beşi aynı yöntemle üretildi; F4.3'te otomatik kontrast testiyle kilitlenmeli.
- **Veri modeli:** Kategori hex değil **renk anahtarı** (`colorKey: "lacivert"`) saklamalı, yoksa light/dark eşlemesi yapılamaz.

#### Dinamik renk tutumu
- **Uygulama içi:** Varsayılan marka paleti ("Kor" kimliği ve kontrast garantisi). Android 12+'da Ayarlar'da opsiyonel **"Duvar kâğıdı renkleri"** anahtarı var. Açıkken yalnızca `primary*` ve `surface*` rolleri `dynamic_color` ile sistemden alınıyor. Kategori renkleri `harmonize` ile hafifçe sistem tonuna çekiliyor ama fg/container kontrast testi korunuyor.
- **Android widget'ları:** Varsayılan olarak dinamik sistem renkleri (B9: Google Tasks yaklaşımı). Ana ekranda uyum, uygulama içinden daha önemli.
- **iOS:** Dinamik renk yok. Widget'lar tinted/clear modlarda monokrom template.

#### Tipografi — Google Sans Flex (değişken, bundle edilen asset)
Alt küme: latin + latin-ext. Eksenler: wght, opsz, ROND. Fallback: Android Roboto Flex → sans-serif, iOS SF Pro. Saat ve sayaçlarda `FontFeature.tabularFigures()`.

| Stil | Boyut/Satır | wght | ROND | Kullanım |
|---|---|---|---|---|
| displayTime | 44/48 | 620 | 100 | geri sayım, widget saati |
| headlineLarge | 32/40 | 650 | 70 | ekran başlığı "Bugün" |
| headlineSmall | 24/32 | 600 | 50 | editör başlığı, boş durum başlığı |
| titleLarge | 20/28 | 600 | 30 | sheet başlığı |
| titleMedium | 16/22 | 560 | 20 | kart başlığı |
| bodyLarge | 16/24 | 400 | 0 | input, açıklama |
| bodyMedium | 14/20 | 400 | 0 | ikincil metin |
| labelLarge | 14/20 | 600 | 30 | buton, bölüm başlığı |
| labelMedium | 12/16 | 600 | 30 | kart meta |
| labelSmall | 11/16 | 650 | 30 | pill, "SIRADAKİ" (minimum boyut) |
| timeLabel | 13/16 | 600 | 60 | şerit saatleri (tabular) |

Kural: **başlıklar yuvarlak (samimi), gövde düz (okunaklı).** Comfortaa'nın sıcaklığı başlıklarda yaşıyor. Türkçe büyük harf dönüşümünde `toUpperCase()` yerine locale'e duyarlı dönüşüm kullanılmalı ("SIRADAKİ" doğru İ ile yazılmalı).

#### Şekil / köşe yarıçapı
`xs 6` (inline token) · `sm 10` (chip) · `md 16` (input, snackbar, harita önizleme) · `card 20` (hatırlatıcı kartı) · `lg 24` (gruplu kart, FAB squircle) · `xl 32` (hero kart, sheet üst köşeleri) · `full` (nav, yakalama çubuğu, pill).
- iOS'ta `ContinuousRectangleBorder` eşdeğeri (squircle) tercih ediliyor.
- **M3E şekil vurgusu:** Tamamlanan checkbox daireden 9 kenarlı "cookie" şekline morph ediyor. Bu tek "expressive şekil" imzası; başka yerde süs şekil yok.

#### Boşluk
4pt taban: `2, 4, 8, 12, 16, 20, 24, 32, 40, 56`.
- Ekran kenarı 16.
- Kartlar arası 8, bölümler arası 24.
- Kart iç padding 12–16.
- Zaman şeridi gutter'ı 56.

#### Yükselti ve bulanıklık
| Seviye | Değer | Kullanım |
|---|---|---|
| 0 | düz | tamamlanan kart, liste satırı |
| 1 | `0 1 2 rgba(31,27,22,.06)` + light'ta 1px `outlineVariant` | kartlar |
| 2 | `0 8 24 rgba(31,27,22,.12)` (dark: `rgba(0,0,0,.40)`) | nav, yakalama çubuğu, FAB |
| 3 | `0 16 40 rgba(31,27,22,.18)` | sürüklenen kart, açık menü |
| glass | σ 24 + tint + kontur | yalnız iOS yüzen krom |

Dark temada gölgeler zayıf kaldığından ayrım `surfaceContainer*` basamaklarıyla sağlanıyor.

#### Hareket (spring, androidx Expressive token'ları)
| Token | damping / stiffness | Kullanım |
|---|---|---|
| spatialFast | 0.6 / 800 | checkbox morph, press, chip "pop" |
| spatialDefault | 0.8 / 380 | kart yer değiştirme, swipe geri dönüş, nav göstergesi, reorder |
| spatialSlow | 0.8 / 200 | sheet açılışı, yakalama → editör genişlemesi |
| effectsFast | 1.0 / 3800 | küçük renk/opaklık |
| effectsDefault | 1.0 / 1600 | fade, tint |
| effectsSlow | 1.0 / 800 | ekran crossfade |

- Süre fallback'i (spring kullanılamayan yerler): 120 / 240 / 400 ms, `easeOutCubic`.
- **Reduce Motion** (`MediaQuery.disableAnimationsOf`): Tüm spatial springler 150 ms fade'e dönüşüyor. Parlama, parçacık ve morph kapanıyor; checkbox doğrudan dolu görünüyor.
- Opaklık ve renk asla zıplamıyor (effects her zaman kritik sönümlü).

#### Haptik
| Olay | Flutter |
|---|---|
| Tamamla | `HapticFeedback.mediumImpact` |
| Swipe eşiği geçildi, token tanındı | `selectionClick` |
| Geri al, reorder bırak | `lightImpact` |
| Sil | `heavyImpact` |
| Reorder kaldır | `mediumImpact` |

Ayarlar'da "Titreşim geri bildirimi" anahtarı var (varsayılan açık). Haptik hiçbir zaman tek geri bildirim değil; her zaman görsel karşılığı eşlik ediyor.

---

### 3.2 Bilgi mimarisi ve navigasyon

```
Bugün  ─┬─ Kaçanlar (gecikmiş)            ← "Hepsini yarına al"
        ├─ Doğum günü banner'ı (bugün/yarın)
        ├─ Zaman şeridi (saatli, ŞİMDİ çizgisi)
        ├─ Bugün bir ara (zamansız, bugüne atanmış)
        └─ Tamamlananlar (katlanır)
Takvim ─┬─ Hafta şeridi ⇄ ay ızgarası
        ├─ Filtre: Tümü · Hatırlatıcılar · Doğum günleri · Konumlu
        └─ Gün gün gündem (Yaklaşan)
Listeler┬─ Akıllı listeler (bento 2×3): Gecikmiş · Bugün · Planlı · Zamansız · Doğum günleri · Konumlu
        ├─ Kategorilerim (sıralanabilir) → Liste detayı (checklist modu)
        └─ Tamamlananlar
Arama   ─ iOS: tab bar yanında ayrı cam düğme · Android: Bugün/Listeler üst barında ikon
Ayarlar ─ Bugün başlığındaki dişli (ileride hesap avatarı; F7.1)
Ekle    ─ iOS: tab bar üstünde "Ne hatırlatayım?" yakalama çubuğu (accessory)
          Android: nav'ın yanında 64px squircle FAB; uzun bas → Hatırlatıcı / Checklist / Doğum günü
```

ROADMAP eşlemesi:
- F3.6 Today/Upcoming/Overdue/No-date: Bugün (Today + Overdue), Takvim (Upcoming), Listeler › Zamansız (No-date).
- F4.4 doğum günleri: hem Takvim filtresi hem Listeler › Doğum günleri ekranı.

| Konu | Android | iOS |
|---|---|---|
| Nav | Yüzen hap nav (296×64, `surfaceContainerHigh`, level2), 3 hedef. Aktif öğe `primaryContainer` göstergesi içinde ikon+etiket yatay (M3E), pasifler yalnız ikon (etiket semantics'te) | Cam tab bar (290×62), 3 sekme ikon+etiket, ayrı cam arama dairesi (62). Kaydırınca küçülüyor |
| Ekle | Nav sağında FAB (64, `radius.lg`, primary) | Tab bar üstünde yakalama çubuğu (accessory), küçülünce birlikte iniyor |
| Arama | Üst barda ikon → M3 SearchView | Ayrı arama sekme düğmesi → tam ekran arama |
| Editör | Tam ekran route, karttan container transform | Large detent sheet |
| Geri | Sistem geri / predictive back | Kenardan kaydırma |
| Switch, date/time picker | `Switch`, M3 date picker | `Switch.adaptive`, `CupertinoDatePicker` (wheel) |
| Bağlam menüsü | Uzun bas → M3 menu | Uzun bas → `CupertinoContextMenu` önizlemeli |
| Widget | RemoteViews, dinamik renk | WidgetKit + App Intents, tinted/clear uyumu |
| Bildirim aksiyonları | 3 buton: Tamamla, 10 dk, 1 saat | Uzun bas: Tamamla, 10 dk, 1 saat, Yarın sabah |

---

### 3.3 Ekran ekran spesifikasyon

> Çerçeve: iPhone 16, 390×844 pt (safe top 54, bottom 34). Android için 412×915 dp; yatay ölçüler 16px kenarla genişliyor. Tüm koordinatlar ve bileşen ölçüleri `screens.json` içinde; burada özet wireframe'ler var.

#### 3.3.1 Onboarding (4 adım, F4.2 + F1.6)

```
┌──────────────────────────────┐  1/4 KARŞILAMA
│                              │
│         ○ 09:00  ✓           │  Zaman şeridi illüstrasyonu (340h):
│         │                    │  düğümler sırayla spatialDefault ile oturur,
│  ━━━━━━━●━━ 14:32 ŞİMDİ ━━   │  şimdi çizgisi bir kez parlar
│         │                    │
│         ○ 18:30              │
│                              │
│  Aklında kalmasın.           │  headlineLarge
│  Yaz, zamanını ya da yerini  │  bodyLarge / onSurfaceVariant
│  söyle; gerisini Hatırlatıcı │
│  takip etsin.                │
│                              │
│  ● ━ ○ ○                     │  PageDots (aktif 24×8)
│ ┌──────────────────────────┐ │
│ │          Başla           │ │  FilledButton 342×56, radius.full
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

- **2/4 "Yazman yeterli":**
  - Canlı demo: alan kendi kendine "yarın 9'da eczaneye uğra #sağlık" yazıyor.
  - "yarın 9'da" `primaryContainer` token'ına, "#sağlık" kategori container'ına dönüşüyor.
  - Altında ayrıştırılmış kart beliriyor: "Eczaneye uğra · Sağlık · Yarın 09:00".
  - Sağ üstte "Atla".
- **3/4 Bildirim ön-izni:**
  - Gerçekçi bildirim maketi: "Market alışverişi — Migros Kadıköy'e yaklaştın · 2/6 madde" + [Tamamla] [10 dk ertele].
  - 3 madde: zamanında bildirim, bildirimden tamamla/ertele, doğum günleri.
  - "Bildirimlere izin ver" (sistem diyaloğunu açar) + "Şimdi değil".
  - **Exact alarm (Android) ve konum izinleri burada istenmez**; ilk ihtiyaç anında bağlamsal sheet ile istenir.
- **4/4 Hazır:**
  - Kor burst (96, bir kez oynar).
  - "Hazırsın." başlığı.
  - 3 öneri satırı (56h): Market listesi oluştur · Bir doğum günü ekle · Ana ekrana widget ekle.
  - "Uygulamaya geç" butonu.

#### 3.3.2 Bugün (ana ekran)

```
┌──────────────────────────────┐
│ Cumartesi, 13 Eylül     🔍 ⚙ │ labelLarge · 48px ikon butonları (🔍 yalnız Android)
│ Bugün                        │ headlineLarge
│ 6 açık · 1 gecikmiş · 2 tamam│ bodyMedium
│ ▰▰▰▱▱▱▱▱▱▱▱▱ (6px ilerleme)  │ primary / surfaceContainerHigh
│┌────────────────────────────┐│
││(ZA) Zeynep Aydın yarın 30   ││ BirthdayCard 358×72, doğum günü container
││     yaşına · Hediye: ayraç  ││ sağda "Yarın" pill
│└────────────────────────────┘│
│ ↺ Kaçanlar    Hepsini yarına al│ SectionHeader (ikon primary)
│┌────────────────────────────┐│
││◯ Elektrik faturasını öde    ││ halka 2.5px primary (yüksek öncelik)
││  Ev · ⏱ Gecikti · Dün 18:00 ││ "Gecikti" metni primary + ikon
││  !!! Yüksek                 ││
│└────────────────────────────┘│
│ Zaman çizelgesi  Tamamlananları gizle│
│ 09:00 ●┊ ✓ Vitamin iç (düz)   │ tamamlanan: compact 56h, level0
│ 11:30 ●┊ ✓ Kargoyu teslim al  │
│ 14:32━━●━━━━━━━━━━━━━━━━━━━━━│ ŞİMDİ: 2px primary + "14:32" pill
│ 16:00 ○┊┌───────────────────┐ │
│        ┊│◯ Ali'yi kurstan al│ │ gutter 56 · rail x=64 · kart x=80 w=278
│        ┊│ Günlük · 1 sa 28dk│ │
│        ┊└───────────────────┘ │
│ 18:30 ○┊┌───────────────────┐ │
│        ┊│📌◯ Market alışverişi│
│        ┊│ Market·Migros·☑2/6│ │
│        ┊│ ▰▰▱▱▱▱ (market fg)│ │
│        ┊└───────────────────┘ │
│ 20:00 ○┊ ◯ Sunum slaytları… !!│
│ Bugün bir ara             2  │
│ ◯ Kütüphane kitabını iade et │
│ ◯ Bitkileri sula · ↻ 3 günde │
│ ░░░░ (24px kenar gradyanı) ░░│
│ (⊕  Ne hatırlatayım?     🎤) │ CaptureBar 358×52 (iOS cam)
│ (Bugün|Takvim|Listeler)  (🔍) │ iOS cam tab bar + arama dairesi
└──────────────────────────────┘
Android altı: [ (▣ Bugün)  ▢  ▢ ]  [ + ]  ← 296×64 hap nav + 64 squircle FAB
```

- **Sıralama:** pinned → saat → öncelik. Zamansız bölümde pinned → öncelik → oluşturulma.
- **Gecikme:** `primary` renk + "Gecikti" metni + saat ikonu. Renk tek sinyal değil.
- **Varyantlar:**
  - *Boş:* tek kor düğümlü şerit illüstrasyonu, "Bugün boş" / "Keyfine bak ya da aklındakini aşağıya yaz." / [Yarını planla].
  - *Hepsi tamam:* "Hepsi tamam." / "Bugünkü 8 hatırlatmanın hepsini bitirdin." (burst bir kez) / [Tamamlananları göster].
  - *İzin reddedildi:* başlık altında `tertiaryContainer` banner, "Bildirimler kapalı — Hatırlatmalar zamanında gelmeyecek." [Ayarları aç].
- **Yazı ölçeği >1.3:** Gutter kalkıyor, saat kartın üst satırına taşınıyor; rail gizleniyor.

#### 3.3.3 Hızlı yakalama (yeni imza özellik)

```
┌──────────────────────────────┐ scrim %32
│ ───                          │ sheet radius 32, surface
│┌────────────────────────────┐│
││[Cuma 18:00] ekmek ve süt al ││ TextField 56h, autofocus
││ [#market] [!!]              ││ inline token'lar radius 6, weight 600
│└────────────────────────────┘│
│ [📅 Cuma 19 Eyl, 18:00✓][🧺 Market✓][⚑ Orta✓][↻ Tekrar][📍 Konum][☑ Madde] │ ← kaydırılabilir chip satırı
│ ⤢ Tüm ayrıntılar          [↑]│ 48px kor kaydet düğmesi (radius 16)
├──────────────────────────────┤
│         (klavye)             │
└──────────────────────────────┘
```

- **Açılış:** CaptureBar'dan container transform ile genişliyor (spatialSlow).
- **Kaydet:** Enter veya ↑. Alan temizleniyor, sheet **açık kalıyor** (art arda giriş). Üstte 3 sn "Eklendi: Ekmek ve süt al · Geri al" gösteriliyor.
- **Ayrıştırıcı (Türkçe, kural tabanlı):**
  - Günler: `bugün`, `yarın`, `öbür gün`, `haftaya`, `pazartesi…pazar`, `ayın 17'si`.
  - Saatler: `18:00`, `18.30`, `9'da`, `sabah` (Ayarlar › sabah saati), `akşam`, `öğlen`.
  - Tekrar: `her gün/hafta/ay`, `her pazartesi`, `3 günde bir`, `hafta içi`.
  - Etiketler: `#kategori` (bulanık eşleşme, yoksa "Yeni kategori oluştur?"), `!`/`!!`/`!!!`, `@ev` (kayıtlı yerler).
- **Token davranışı:** Token'a dokununca ilgili picker açılıyor. Token silinirse chip de kalkıyor. Yanlış algılama "×" ile düz metne çevriliyor.
- **Liste algılama:** "#market" ve virgül/"ve" varsa "Maddelere böl?" öneri chip'i çıkıyor. Kabul edilirse başlık "Market alışverişi", maddeler ekmek ve süt oluyor.

#### 3.3.4 Hatırlatıcı detayı / tam editör

```
┌──────────────────────────────┐
│ ✕                  📌  ⋮  Bitti│ 56h üst bar
│ ◯  Market alışverişi         │ CheckboxMorph + headlineSmall (düzenlenebilir)
│    Kasada kart puanını kullan│ bodyLarge not
│┌ ⏱ Ne zaman ────────────────┐│ gruplu kart radius 24
││ [📅 Bugün, 13 Eyl] [🕕 18:30] ✕│
││ ↻ Tekrar        Her Cumartesi ›│
││ 🔔 Uyarı            Zamanında ›│
│└────────────────────────────┘│
│┌ 📍 Nerede ─────────── [●━]┐│ Switch.adaptive
││ ┌────────────────────────┐ ││ harita önizleme 326×112, radius 16
││ │   ( ◉ 150 m )          │ ││ → konum seçiciyi açar
││ └────────────────────────┘ ││
││ Migros Kadıköy · 150 m      ││ titleMedium (koordinat asla gösterilmez)
││ Bölgeye girince bildirim    ││
│└────────────────────────────┘│
│┌ ☑ Maddeler ─────────── 2/6 ┐│
││ ▰▰▱▱▱▱ (6px, market fg)      ││
││ ◯ Yumurta (15'li)         ≡ ││ SubtaskRow 48h + sürükleme tutamacı
││ ◯ Domates 1 kg            ≡ ││
││ ◯ Zeytinyağı              ≡ ││
││ ◯ Bulaşık deterjanı       ≡ ││
││ + Madde ekle                ││ Enter → yeni satır; çok satırlı yapıştır → böl
││ Tamamlanan 2 madde        ⌄ ││
│└────────────────────────────┘│
│┌ 🏷 Kategori ────────────────┐│
││ [🧺 Market✓][Ev][İş][Sağlık]…[+ Yeni]│
││ ⚑ Öncelik                   ││
││ [ Yok | Düşük | Orta | Yüksek ]│ SegmentedButton 48h
│└────────────────────────────┘│
│ (✓ Tamamlandı olarak işaretle)│ yapışkan alt buton 358×56
└──────────────────────────────┘
```

- **Otomatik kaydetme:** Kayıt anlık (debounce 400 ms). "Bitti" yalnızca kapatıyor. Doğrulama hataları inline gösteriliyor (kart kenarı `error` + açıklama metni).
- **Geçmiş saat seçimi:** Chip `error` rengine dönüyor + "Bu saat geçti — yarın 18:30 mı?" öneri chip'i. Sessiz +1 dk yok.
- **Menü ⋮:** Kopyala · Sil (undo snackbar ile) · (ileride) Paylaş.
- **Tekrar sheet'i:**
  - Segment: Yok / Günlük / Haftalık / Aylık / Özel.
  - Gün düğmeleri (Pzt…Paz, 48 daire).
  - "Her [1] haftada bir" stepper, "Bitiş: Hiçbir zaman".
  - Önizleme: "Sonraki 3: Cmt 13 Eyl · Cmt 20 Eyl · Cmt 27 Eyl".
  - Tekrarlayan öğede tarih değişince soruluyor: "Yalnızca bu sefer / Tüm seriler" (B7).
- **Ertele sheet'i:** 2×2 kart (175×72): 10 dakika 14:42 · 1 saat 15:32 · Bu akşam 20:00 · Yarın sabah Paz 09:00. Ardından "Tarih ve saat seç…".

#### 3.3.5 Takvim (Yaklaşan)

```
┌──────────────────────────────┐
│ Takvim            Bugün  ▦   │ ▦ = ay görünümüne geç
│ Eylül 2026                   │
│ (Pzt)(Sal)(Çar)(Per)(Cum)(CMT)(Paz)│ WeekStripDay 46×68, radius full
│   8   9   10  11  12 [13]  14 │ seçili: primary dolu; bugün: 1.5px primary halka
│       •   ••      •  •••  •• │ kategori noktaları (≤3, 5px)
│  ─── (aşağı sürükle → 6×7 ay ızgarası) │
│ [Tümü✓][Hatırlatıcılar][Doğum günleri][Konumlu]│
│ BUGÜN · CUMARTESİ 13 EYLÜL   │ yapışkan gün başlığı
│ 16:00  ◯ Ali'yi kurstan al   │
│ 18:30  ◯ Market alışverişi 2/6│
│ 20:00  ◯ Sunum slaytları…    │
│ YARIN · PAZAR 14 EYLÜL       │
│ Tüm gün (ZA) Zeynep Aydın · 30 · Yarın │ BirthdayCard
│ 09:30  ◯ Kahvaltı rezervasyonu│
│ PAZARTESİ 15 EYLÜL           │
│ 08:45  ◯ Haftalık ekip toplantısı ↻ │
│ 13:00  ◯ Diş hekimi randevusu │
│ 16 Eylül — boş gün           │ 40h, onSurfaceVariant
└──────────────────────────────┘
```

- **Taşıma:** Karta uzun basıp WeekStrip'teki bir güne sürükle-bırak yeniden planlıyor. Alternatifi: menü › "Taşı…" ve semantics aksiyonu.
- **Boş gün:** Dokununca o güne tarihli hızlı yakalama açılıyor.

#### 3.3.6 Listeler + kategori yönetimi (F4.3)

```
┌──────────────────────────────┐
│ Listeler            🔍 Düzenle│
│┌─────────────┐ ┌─────────────┐│ SmartListTile 171×96, radius 24
││(↺)        1 │ │(▤)        6 ││ ikon 32 daire container; sayı headlineSmall
││ Gecikmiş    │ │ Bugün       ││
│└─────────────┘ └─────────────┘│
│┌─────────────┐ ┌─────────────┐│
││ Planlı   14 │ │ Zamansız  5 ││
│└─────────────┘ └─────────────┘│
│┌─────────────┐ ┌─────────────┐│
││ Doğum g. 12 │ │ Konumlu   2 ││
│└─────────────┘ └─────────────┘│
│┌ Kategorilerim ─────────────┐│ surface kart
││ (🧺) Market              3 ││ CategoryRow 56h; düzenle modunda ≡ tutamacı
││ (⌂)  Ev                  4 ││
││ (💼) İş                  5 ││
││ (♥)  Sağlık              2 ││
││ (☀)  Günlük              4 ││
││ (🏋) Spor salonu         1 ││
││ +  Yeni kategori            ││ primary metin
│└────────────────────────────┘│
│ ✓ Tamamlananlar          48 ›│
└──────────────────────────────┘
```

- **Kategori editörü (sheet):**
  - Canlı önizleme satırı ve Ad alanı (maks 24 karakter).
  - **Renk:** 12 swatch (40, hedef 48), 6 sütun. Seçili halde 3px `onSurface` halka + ✓. Ekran okuyucu renk adını söylüyor ("Lacivert, seçili").
  - **İkon:** 18 Material Symbols Rounded ikonu (48'lik hücreler, 6 sütun).
  - Butonlar: [Sil] (düzenlemede, "Bu kategorideki 4 hatırlatıcı Diğer'e taşınacak" onayıyla) · [Kaydet].
  - **Migration:** Mevcut "Diğer + özel ad" kayıtları özel ad başına bir kullanıcı kategorisine dönüşüyor (renk: diğer, ikon: label).
- **Liste detayı (checklist modu, örn. Market):**
  - Büyük başlık + kategori rozeti, "3 açık · 1 liste".
  - Üstte "Bu listeye ekle…" inline alanı.
  - Maddeli hatırlatıcı açık haliyle görünüyor. Maddelere tek dokunuşla tik atılıyor; tamamlananlar alta süzülüyor.

#### 3.3.7 Doğum günleri (F4.4)
- **Hero kart** (358×152, radius 32, doğum günü container): "SIRADAKİ" labelSmall · "Zeynep Aydın" headlineSmall · "Yarın · 30 yaşına giriyor". Sağda büyük "1 gün" (displayTime, doğum günü fg). Altta [🎁 Hediye notu] [Mesaj hatırlat] butonları.
- **Aylara göre gruplu satırlar** (64h): baş harf avatarı, "14 Eylül · 30 yaşına", sağda "Yarın" / "8 gün".
- **29 Şubat:** "artık yıl değil: 28 Şubat'ta hatırlatılır" (F1.8 ile uyumlu).
- **Editör:**
  - İsim (autofocus).
  - Tarih: **yıl opsiyonel** ("Yılı bilmiyorsan boş bırak").
  - "Ne zaman hatırlatayım?" FilterChip'leri: Gününde✓ · 1 gün önce✓ · 3 gün · 1 hafta · 2 hafta.
  - Bildirim saati 09:00, Not, Kaydet.
- **Boş durum:** "Henüz doğum günü yok — Sevdiklerinin gününü kaçırma. Rehberden içe aktarma yakında." [Doğum günü ekle].

#### 3.3.8 Arama (F3.6)
- **Alan:** 56h `radius.full` `surfaceContainerHigh`, autofocus. Filtre chip'leri: Açık✓ · Tamamlanan · Kategori ▾ · Tarih ▾.
- **Sonuçlar gruplu:** "Hatırlatıcılar · 3", "Maddelerde · 1". Eşleşme weight 700 + `primaryContainer` vurgusu ("Elektrik **fatura**sını öde"). Not içinde eşleşme varsa tek satır bağlam gösteriliyor.
- **Başlangıç durumu:** Son aramalar.
- **Sonuç yok:** "“faturaa” için sonuç yok — Yazımı kontrol et veya tamamlananlarda ara." [Tamamlananlarda ara].
- **Arama davranışı:** Türkçe duyarsız eşleşme (İ/i, ı/I, ş/s, ğ/g, ç/c, ö/o, ü/u katlaması).

#### 3.3.9 Ayarlar
Gruplu kartlar (radius 24):
1. **İzinler:** Bildirimler (● Açık, success) · Konum ("Yalnızca kullanırken — arka plan hatırlatmaları çalışmaz" [Düzelt], uyarı) · Tam zamanlı alarmlar (Android).
2. **Görünüm:** Tema segment (Sistem/Açık/Koyu) · Duvar kâğıdı renkleri (Android 12+) · Titreşim geri bildirimi.
3. **Varsayılanlar:** Sabah saati 09:00 · Akşam saati 20:00 · Erteleme seçenekleri · Haftanın ilk günü Pazartesi.
4. **Diğer:** Ana ekran widget'ı ekle · Dil (Türkçe/English, F6.1) · Yedekle ve geri yükle (F2.2) · Hakkında 2.1.0 · **Tüm verileri sıfırla** (error rengi; önce "Yedek al" önerisi, sonra kırmızı onay).

Özel `RollingSwitchButton` kaldırılıyor; yerine `Switch.adaptive` geliyor.

#### 3.3.10 Konum seçici

```
┌──────────────────────────────┐
│ (←) (🔍 Adres veya yer ara  )│ 52h yüzen kontroller (iOS cam / Android surfaceContainerHigh)
│                              │
│         .-""""-.             │ harita tam ekran (OSM; dark'ta koyu stil)
│       /  ( ◉ )   \           │ yarıçap dairesi primary %20 dolgu + 2px kontur
│       \          /           │ pin 40, sürüklerken 8px yükselir (spatialFast)
│         '-....-'        (◎)  │ konumuma git 52
│┌────────────────────────────┐│ sheet detent: peek 140 / half 304 / full
││ Migros Kadıköy              ││ titleLarge
││ Caferağa Mah., Moda Cd. 12  ││ bodyMedium
││ Yarıçap              150 m  ││
││ ━━━━●━━━━━━━━━━━━━━━━━━━━━  ││ M3E slider: 16px track, 4×44 dikey tutamaç, adım 50
││ [→ Varınca✓] [← Ayrılınca (yakında)]││
││ ( Bu konumu kullan )        ││ 358×56
│└────────────────────────────┘│
└──────────────────────────────┘
```

- **Bağlamsal izin (F1.6):** İlk kez "Nerede" açıldığında 2 adımlı ön-izin sheet'i gösteriliyor:
  - ① "Uygulamayı kullanırken" izni [Devam].
  - ② "Uygulama kapalıyken de çalışması için Ayarlar'da ‘Her zaman izin ver’i seç" [Ayarları aç] / [Sonra]. Sadeleştirilmiş ayar ekranı çizimiyle.
- **İzin reddedilirse:** Harita yine açılıyor (manuel seçim mümkün). Sheet'te "Arka plan izni olmadan bildirim gelmeyebilir" uyarısı var.
- **API anahtarı yoksa:** "Yakındaki marketler" chip'i *hiç gösterilmiyor*; geliştirici metni yok.

#### 3.3.11 Boş durumlar (ortak desen)
- Yapı: 96px monokrom kor-şerit illüstrasyonu + headlineSmall başlık + bodyLarge tek cümle + en fazla 1 aksiyon.
- Metinler: Bugün boş · Hepsi tamam · Liste boş ("Market listesi boş — Eklemek için yukarıya yaz.") · Arama sonuç yok · Doğum günü yok · Konumlu hatırlatma yok ("Bir yere varınca hatırlatmak için hatırlatıcıda 'Nerede'yi aç.").

#### 3.3.12 Bildirim (F3.2)
- **Android:**
  - Başlık "Market alışverişi", metin "18:30 · Migros Kadıköy · 4 madde kaldı".
  - BigTextStyle maddeleri listeliyor; aksiyonlar [Tamamla] [10 dk] [1 saat].
  - Monokrom kor small icon, renk `#B8430F`.
- **iOS:**
  - Başlık, alt başlık "18:30 · Migros Kadıköy", gövdede maddeler.
  - Uzun bas: Tamamla · 10 dk ertele · 1 saat ertele · Yarın sabah.
  - Kullanıcı izin verirse `timeSensitive`.

---

### 3.4 Widget'lar

#### Android (F5.1)
- **Ortak:** Android 12+ sistem köşe yarıçapı ve dinamik renkler (`system_neutral1_50/900`, "+" için `system_accent1_100`), 16dp iç boşluk, sistem fontu.

| Widget | Hücre (min dp) | İçerik |
|---|---|---|
| Sıradaki | 2×2 (110×110) | "SIRADAKİ" 11sp · **16:00** 28sp tabular · "Ali'yi kurstan al" 14sp 2 satır · "+5 daha" · 40×40 "+" |
| Bugün | 4×2 (250×110) | Başlık "Bugün · 6" + sağ üstte **56×40 hap "+"** (Google Tasks M3E kalıbı) · 2 satır (48h): "◯ Elektrik faturasını öde · Gecikti" (primary), "◯ Ali'yi kurstan al · 16:00" |
| Liste | 4×4, 3×3–5×6 arası boyutlanır | Kaydırılabilir `RemoteCollectionItems` (API 31+) / `RemoteViewsService`: Kaçanlar, Bugün, Doğum günü bölümleri; satır başına 48dp onay dairesi |
| Hızlı ekle | 1×1 | Yalnız "+" hap → doğrudan yakalama sheet'i |

Durumlar: "Bugün boş. Eklemek için +" · "Bildirimler kapalı — açmak için dokun".

#### iOS (F5.2 — WidgetKit + App Intents)
- **Ortak:**
  - Sistem `contentMargins`, SF Pro.
  - Full color'da kor vurgu. Accented/tinted ve clear (Liquid Glass) modlarında tüm grafikler template; yalnız onay daireleri `widgetAccentable()`.
  - Onay daireleri `Button(intent: CompleteReminderIntent)` (44×44).

| Aile | İçerik |
|---|---|
| systemSmall | SIRADAKİ · 16:00 (monospacedDigit) · başlık 2 satır · tamamla düğmesi |
| systemMedium | "Bugün · 6 açık" + 3 satır (36h) |
| systemLarge | Başlık + tarih · 6 satır · alt satırda "🎂 Zeynep Aydın · Yarın" |
| systemExtraLarge (iOS 27, iPhone) | İki sütun: Bugün (8 satır) · Yaklaşan 3 gün + doğum günleri — opsiyonel |
| accessoryRectangular | "16:00 Ali'yi kurstan al" / "+5 hatırlatma" |
| accessoryCircular | Gauge: 2/8 tamamlandı |
| accessoryInline | "16:00 · Ali'yi kurstan al" |

**Kısayollar (F5.3):** Yeni hatırlatıcı · Market listesi · Bugün · Yeni doğum günü.

---

### 3.5 Temel mikro-etkileşimler

**Tamamla**

| Zaman | Olay |
|---|---|
| 0 ms | Haptik (medium), checkbox 1→0.85 (spatialFast) |
| 0–240 ms | Daire → 9 kenarlı cookie morph; kategori fg dolgusu merkezden yayılıyor |
| 120–300 ms | ✓ path çiziliyor; başlığın üstü soldan sağa çiziliyor |
| 300–900 ms | Kart yerinde bekliyor (yanlış dokunuşu fark etme penceresi) |
| 900 ms | Yükseklik 0'a iniyor (spatialDefault); şeritteki düğüm doluyor; "Tamamlananlar" sayacı 1→1.15→1 |
| sonra | Snackbar: "“Ali'yi kurstan al” tamamlandı · Geri al" (5 sn; ekran okuyucu açıksa 10 sn ve odak aksiyona) |

Tekrarlayan öğede kart kalkmıyor; meta satırı "Sonraki: Cmt 20 Eyl 16:00" ile crossfade oluyor.

**Swipe**
- **Sağa (start→end):** Tamamla. `success` zemin + ✓.
- **Sola kısa:** Ertele. `tertiary` zemin + snooze → Ertele sheet'i.
- **Sola uzun (>%60):** Sil. `error` zemin + çöp kutusu → yumuşak silme + Geri al.
- **%30 eşiği:** İkon 0.8→1.0 büyüyor + `selectionClick`. Eşik altında bırakılırsa spatialDefault ile geri dönüyor.
- **Alternatif:** Her aksiyon uzun basma menüsünde ve semantics `customActions`'ta da var (WCAG 2.5.7).

**Geri al:** Silme 5 sn `deletedAt` ile yumuşak (F2.1 alanıyla uyumlu). Geri al'da kart eski indeksine spatialDefault ile dönüyor. Aynı anda tek snackbar; yeni aksiyon öncekini kesinleştiriyor.

**Ertele:** Seçim sonrası kart şeritteki yeni saatine uçuyor (Y ekseninde shared-axis, spatialSlow). Başka güne ertelenirse küçülerek Takvim sekme ikonuna doğru kayboluyor. Toast: "Yarın 09:00'a ertelendi · Geri al".

**Yeniden sıralama** (maddeler, kategoriler, sabitlenmişler)
- 300 ms uzun basma → kaldırma (scale 1.03, level3, medium haptik).
- Komşu satırlar spatialDefault ile kayıyor; bırakınca light haptik.
- Semantics: "Yukarı taşı / Aşağı taşı".

**Yakalama ayrıştırma:** Token tanınınca vurgu zemini effectsFast ile beliriyor, ilgili chip spatialFast ile "pop" ediyor + `selectionClick`.

**Nav geçişi**
- Android: gösterge genişliği morph oluyor, ikon outlined→filled.
- iOS: cam kapsül seçimi kayıyor, içerik fade-through.

**Şimdi çizgisi:** Dakikada bir animasyonsuz ilerliyor. Açılışta tek seferlik 1.2 sn parlama (Reduce Motion'da yok).

---

### 3.6 Erişilebilirlik kuralları (F4.5 kabul kriterleri)

1. **Kontrast:** Metin ≥4.5:1, büyük metin ve UI bileşeni/ikon ≥3:1. Yukarıdaki token tabloları referans. Yeni renk eklenirse `test/ui/theme/contrast_test.dart` otomatik kontrol ediyor. Alfa ile soluklaştırılmış metin yasak; bunun yerine `onSurfaceVariant`.
2. **Dokunma hedefi:** Min 48×48 dp (iOS 44 pt yeterli ama tek kod için 48). Görsel öğe küçük olabilir (checkbox 26), hit alanı değil.
3. **Renk tek başına sinyal değil:** Gecikme için "Gecikti" metni + ikon; öncelik için "!!!" + metin; kategori için ikon + ad.
4. **Semantics:** Her kart tek düğüm. Etiket: "Ali'yi kurstan al, Günlük, bugün 16:00, tamamlanmadı". `customSemanticsActions`: Tamamla, Ertele, Düzenle, Sil, Yukarı/Aşağı taşı. Nav öğelerinde `selected` durumu, chip'lerde `checked`.
5. **Sürükleme alternatifi (WCAG 2.5.7):** Swipe, reorder ve takvime sürükle-bırak için menü ve semantics eşdeğerleri var.
6. **Yazı ölçeği %200'e kadar:** Başlıklar 2 satıra sarıyor. Şerit >1.3'te tek sütuna geçiyor. Chip satırları sarılıyor. Sabit yükseklik yok, `minHeight` kullanılıyor. Bottom nav etiketleri >1.5'te iOS'ta Large Content Viewer davranışını taklit eden uzun basma balonu gösteriyor.
7. **Hareket:** `MediaQuery.disableAnimationsOf` (iOS Reduce Motion / Android animasyon ölçeği 0) → springler yerine 150 ms fade; parlama, burst ve morph kapalı.
8. **Şeffaflık/kontrast:** iOS'ta Reduce Transparency ve Increase Contrast açıksa cam yerine solid. Flutter bunları doğrudan vermiyor; `UIAccessibility.isReduceTransparencyEnabled` MethodChannel ile okunacak. `MediaQuery.highContrastOf` açıksa `outline` kenarlar 2px oluyor.
9. **Zaman sınırı:** Snackbar ≥5 sn; ekran okuyucu aktifse 10 sn ve odak "Geri al"a taşınıyor. Hiçbir onay otomatik kapanmıyor.
10. **Odak sırası:** Başlık → özet → Kaçanlar → şerit (kronolojik) → zamansız → yakalama → nav. Sheet açılınca odak ilk alana, kapanınca tetikleyiciye dönüyor.
11. **Dil:** Semantics metinleri Türkçe yazılıyor ve `Locale('tr')` ile okunuyor. Saatler 24 saat biçiminde; TalkBack/VoiceOver "on altı sıfır sıfır" yerine "saat 16:00" okuyacak şekilde `Semantics(label:)` ayrı veriliyor.
12. **Haptik** asla tek geri bildirim değil ve kapatılabilir.

---

## 4. Kısa alternatif: **"Mor Mürekkep"** (evrimsel yol)

Mevcut mor mirası koruyan, platform bileşenlerine en yakın yol:
- **Görünüm:** `useMaterial3: true` + `ColorScheme.fromSeed(#6B4FC8)` + dinamik renk varsayılan açık.
- **Ana ekran:** Bento kartlar: "Bugün 6", "Gecikmiş 1", "Doğum günü yarın", "Market 2/6". Altında klasik gruplu liste (Bugün / Yaklaşan / Zamansız).
- **Font ve bileşenler:** Comfortaa yalnız logo ve başlıkta, gövdede sistem fontu. Android'de standart M3 NavigationBar (4 sekme: Bugün, Yaklaşan, Listeler, Ayarlar) + FAB. iOS'ta düz `CupertinoTabBar`, cam yok.
- **Artısı:** En hızlı ve en düşük riskli geçiş; F4.1 tek PR'da büyük ölçüde biter.
- **Eksisi:** Ayırt edici değil. "Ne zaman ne var" sorusunu zaman şeridi kadar iyi cevaplamıyor. Dinamik renk varsayılanı kategori kontrastını her duvar kâğıdında garanti edemiyor.

---

## 5. Flutter uygulama notları

### 5.1 Paketler (pub.dev, 13 Eylül 2026 itibarıyla kontrol edildi)

| Paket | Sürüm / tazelik | Karar | Not |
|---|---|---|---|
| `material_ui` | 1.2.0 · 4 gün önce · flutter.dev | **Kullan** | `dart fix` ile `package:flutter/material.dart` → `material_ui` |
| `cupertino_ui` | 1.0.2 · 10 gün önce · flutter.dev | **Kullan** (picker, context menu, sheet) | Henüz cam bileşeni yok |
| `dynamic_color` | 2.1.0 · 23 gün önce · material.io | **Kullan** (opsiyonel ayar + harmonize) | Artık `material_ui`'ye bağımlı; geçişle aynı PR'da |
| `motor` | 1.1.0 · 9 ay önce · whynotmake.it | **Kullan** | `MaterialSpringMotion` (M3 spatial/effects token'ları) + `CupertinoMotion`; tek API |
| `flutter_local_notifications` | 22.3.1 · 9 saat önce | **Yükselt** (repo ^18) | Aksiyonlar için iOS'ta `initialize` sırasında kategori tanımı; Flutter ≥3.38.1, compileSdk 36 |
| `home_widget` | 0.9.4 · 9 gün önce | **Yükselt** (repo ^0.9.1) | Widget UI native kalıyor (Kotlin RemoteViews / SwiftUI) |
| `liquid_glass_widgets` | 1.5.0 · 8 saat önce · verified | **Sınırlı kullan** (yalnız iOS tab bar, arama düğmesi, yakalama çubuğu) | Flutter ≥3.41; "Minimal" (BackdropFilter) kalite modu fallback; a11y fallback'leri hazır |
| `adaptive_platform_ui` | 0.1.111 · 49 gün önce | **Kullanma** | Platform view + kök view controller değişimi, "yalnız prototip" uyarısı |
| `m3e_collection` | 0.3.7 · 10 ay önce · 33 beğeni | **Bağımlılık yapma** | Şekil ve slider uygulamaları referans alınabilir |
| `flutter_slidable` | 4.0.3 · 11 ay önce · 6.1k beğeni | **Kullan veya kendin yaz** | Swipe + eşik haptiği için yeterli; bakım yavaş, gerekirse `Dismissible` + özel |
| `table_calendar` | 3.2.1 · 34 gün önce · *doğrulanmamış yayıncı* | **Tercihen kendin yaz** | WeekStrip ve ay ızgarası basit; tasarım kontrolü için özel widget önerilir |
| `google_fonts` | 8.2.1 · flutter.dev | **Yalnız geliştirmede** | Yayında Google Sans Flex değişken dosyası asset olarak bundle edilir (offline) |
| `flutter_animate` | 4.5.2 · 21 ay önce | **Kullanma** | Bakım durgun; `motor` + implicit animasyonlar yeterli |
| `flutter_local_ai` / `edge_gen_ai` | aktif | **Şimdilik yok** (F8 fikri) | Cihaz kısıtlı; kural tabanlı ayrıştırıcı temel |

### 5.2 Hazır Flutter ile özel yapılacaklar
- **Hazır (material_ui/cupertino_ui):** `NavigationBar`/`CupertinoTabBar` (Android'de temalanmış), `SegmentedButton`, `FilterChip`, `SearchAnchor`, `Switch.adaptive`, `showModalBottomSheet`, `DraggableScrollableSheet`, `ReorderableListView`, `CupertinoContextMenu`, `CupertinoDatePicker`, `SnackBar`.
- **Özel:**
  - `TimeRibbon` (gutter/rail/düğüm/şimdi çizgisi; `SliverList` + `CustomPainter` rail).
  - `CheckboxMorph` (şekil morph: `material_new_shapes` benzeri path interpolasyonu veya kendi 9 köşeli `ShapeBorder.lerp`).
  - `CaptureField` (token vurgulu `TextEditingController.buildTextSpan`).
  - `TurkishDateParser` (saf Dart, %100 unit test; `lib/domain/parsing/`).
  - `WeekStrip`, `MonthGrid`, `SmartListTile`, yüzen `KorNavBar` (Android), `GlassTabBar` sarmalayıcısı (iOS).
- **Native:** Android widget (RemoteViews + `RemoteCollectionItems`), iOS WidgetKit extension + App Intents (Swift), bildirim kategorileri.

### 5.3 Tema mimarisi

```
lib/ui/theme/
  tokens/
    kor_palette.dart        // ham hex sabitleri (light/dark), kategori renk anahtarları
    kor_color_scheme.dart   // ColorScheme.light/dark: tüm M3 rolleri elle (fromSeed değil)
    kor_typography.dart     // TextTheme + FontVariation(wght/ROND/opsz) + tabular stil
    kor_shapes.dart         // radius sabitleri + CookieShapeBorder
    kor_spacing.dart        // const EdgeInsets / gap'ler
    kor_motion.dart         // ThemeExtension<KorMotion>: 6 spring (motor) + reduceMotion çözümleyici
  extensions/
    kor_colors_ext.dart     // ThemeExtension<KorColors>: success*, glass*, nowLine, category(key)→(fg, container, on)
    kor_elevation_ext.dart  // gölge listeleri, glass parametreleri
  adaptive/
    platform_chrome.dart    // TargetPlatform'a göre nav/sheet/picker/menu seçimi (tek karar noktası)
    a11y_prefs.dart         // reduceMotion, highContrast, reduceTransparency (MethodChannel)
  app_theme.dart            // ThemeData(light/dark) + component temaları (chip, segmented, snackbar, nav, input)
  haptics.dart              // KorHaptics.complete() vb.; ayar kapalıysa no-op
```

- **Kurallar:**
  - Widget'larda `Color(0x…)`, `Colors.*`, sabit `fontSize` yasak. Yalnız `Theme.of(context).colorScheme` / `context.korColors` / `textTheme` kullanılır. `flutter analyze` için özel lint veya grep tabanlı CI adımı eklenir.
  - `CategoryVisuals` switch'i kaldırılıyor. `Category` modeli `colorKey` + `iconKey` taşıyor; `KorColors.category(colorKey, brightness)` çözüyor. İkonlar sabit bir `Map<String, IconData>` üzerinden eşleniyor (tree-shaking için dinamik `IconData` üretilmiyor).
  - Golden testler: her ana bileşen light/dark × textScale 1.0/2.0.

### 5.4 Roadmap'e yerleştirme

| Madde | Kapsam (bu öneriye göre) | Bağımlılık / not |
|---|---|---|
| **F4.0 (yeni) Araç zinciri + tema altyapısı** · `chore/flutter-3-47-material-ui` | Flutter 3.29 → 3.47, `material_ui`/`cupertino_ui`'ye `dart fix`, iOS min 15 + UIScene, `flutter_local_notifications` 22 ve `home_widget` 0.9.4 yükseltmesi, token dosyaları ve ThemeExtension'lar, Google Sans Flex asset'i. **Görsel değişiklik yok** (`useMaterial3` hâlâ false) | F0.1 CI pin'i güncellenir. Diğer ajanın `lib/` işleriyle çakışmayı azaltmak için ayrı ve erken PR |
| **F4.1 Material 3 geçişi → "Kor" temel görünüm** | `useMaterial3: true`, Kor ColorScheme, tipografi, bileşen temaları, yeni `ReminderCard`, 3 sekmeli kabuk (Bugün/Takvim/Listeler) + Ayarlar'ın dişliye taşınması, `Switch.adaptive`, editör sırası düzeltmesi (başlık önce, autofocus) | F4.0. **F3.5/F3.6'dan önce** yapılmalı, yoksa swipe ve görünümler iki kez tasarlanır |
| F3.1 Tekrar | Tekrar sheet'i, "yalnız bu sefer / tüm seri", erken tamamla | F4.1 bileşenleriyle |
| F3.2 Bildirim aksiyonları | §3.3.12 metinleri; Ertele sheet'i | — |
| F3.3 Alt görevler | Maddeler kartı, checklist modu, "maddelere böl" | — |
| F3.4 Öncelik + sabitleme | Segment, halka stili, 📌, sıralama kuralı | — |
| F3.5 Swipe + undo | §3.5 swipe/undo; semantics aksiyonları | F4.1 |
| F3.6 Arama ve görünümler | Bugün şeridi (Kaçanlar / şerit / Bugün bir ara), Takvim gündemi, Listeler akıllı listeler, Arama ekranı | F4.1 |
| **F4.6 (yeni) Hızlı yakalama + Türkçe ayrıştırıcı** · `feat/quick-capture-nlp` | CaptureBar/FAB, yakalama sheet'i, `TurkishDateParser` + testler, token vurgusu | F3.1, F3.4 (tekrar ve öncelik token'ları için) |
| F4.2 Onboarding | 4 adım, bildirim ön-izni, bağlamsal konum ve exact alarm sheet'leri | F1.6 |
| F4.3 Özel kategoriler | Kategori editörü, 12 renk anahtarı, "Diğer+ad" migration | F2.1 |
| F4.4 Takvim + Doğum günleri | WeekStrip/ay ızgarası, sürükle-yeniden planla, Doğum günleri ekranı, yılsız tarih | F3.6 |
| F4.5 Erişilebilirlik | §3.6'nın 12 kuralı: F4.1'den itibaren **her PR'ın kabul kriteri**; F4.5 kapanış denetimi + kontrast testi + golden'lar | sürekli |
| **F4.7 (yeni) Hareket ve haptik cilası** · `feat/motion-haptics` | `KorMotion` springleri, checkbox morph, şimdi çizgisi, container transform'lar, Reduce Motion yolları | F4.1, F3.5 |
| F5.1 Android widget v2 | 4 widget (§3.4), dinamik renk, hap "+" | F4.6 (hızlı yakalama deep link) |
| F5.2 iOS widget | 6 aile + App Intents tamamla, tinted/clear uyumu | F1.9 (App Group/bundle adı önce) |
| **F5.4 (yeni) iOS Liquid Glass kromu** · `feat/ios-glass-chrome` | Cam tab bar, arama düğmesi, yakalama accessory'si (`liquid_glass_widgets` veya resmi `cupertino_ui` gelirse o), Reduce Transparency MethodChannel | F4.1; resmi paket çıkınca yeniden değerlendirilir |
| F5.3 Kısayollar | 4 kısayol | F4.6 |
| F6.1 i18n | Ayrıştırıcının `en` kural seti ayrı dosya; tüm metinler ARB | F4.6 |

### 5.5 Geçiş riskleri ve önlemler
1. **M2→M3 görsel kayma:** Buton yükseklikleri, dialog ve picker'lar, `surfaceTint` değişiyor. *Önlem:* F4.0'da token'lar görünümü değiştirmeden eklenir, F4.1'de ekran ekran golden testleriyle geçilir.
2. **Paralel ajan çakışması:** `lib/ui/**` ve `app_theme.dart` birçok maddeye dokunuyor. *Önlem:* F4.0 küçük ve erken olsun. Yeni bileşenler yeni dosyalarda (`lib/ui/components/`). Eski ekranlar sonra tek tek taşınır.
3. **Flutter 3.47 yükseltmesi:** iOS 15 minimumu, UIScene geçişi, `flutter_local_notifications` 18→22 kırıcı API değişiklikleri, `geo_fencing`/`flutter_map` uyumu. *Önlem:* F4.0 CI'da iOS build'i geçmeden merge yok (ROADMAP kuralı zaten var).
4. **Değişken font boyutu:** Google Sans Flex tam dosyası büyük. *Önlem:* `fonttools` ile latin+latin-ext alt kümesi ve yalnız wght/opsz/ROND eksenleri; APK/IPA farkı ölçülür. Hedef ≤ 400 KB; aşarsa statik ağırlıklara düşülür.
5. **Cam performansı:** Düşük uç cihazlarda shader maliyeti. *Önlem:* Cam yalnız iOS'ta ve yalnız 2–3 yüzen öğede; Android'de hiç yok; "Minimal" moda otomatik düşüş.
6. **Ayrıştırıcı hataları:** Yanlış tarih, güven kaybettirir. *Önlem:* Yalnız yüksek güvenli eşleşmeler token'a dönüşür. Her token kaldırılabilir ve kaydetmeden önce chip olarak görünür. 200+ Türkçe örnek cümlelik test tablosu; İ/ı büyük-küçük harf testleri.
7. **Widget'larda iki native kod tabanı:** Kotlin + Swift. *Önlem:* Veri sözleşmesi (JSON şeması) tek yerde tanımlanır ve `home_widget` ile paylaşılır. Görsel spec bu dokümandaki tablo.
8. **Kategori migration'ı:** "Diğer + özel ad" → kullanıcı kategorileri. *Önlem:* F2.1 Drift migration testleriyle aynı yaklaşım, geri dönüş için ham yedek (F1.4).

---

## Kaynaklar (toplu)

| URL | Tek satır çıkarım |
|---|---|
| https://flutter.dev/blog/whats-new-in-flutter-3-47 | 3.47 (12 Ağu 2026): material_ui/cupertino_ui 1.0, iOS 15 min, UIScene zorunlu, Android yüksek kontrast algılama |
| https://flutter.dev/blog/decoupling-material-cupertino | Paketler ayrıldı; Liquid Glass ve M3E resmi uygulamaları üzerinde çalışılıyor |
| https://pub.dev/packages/material_ui · https://pub.dev/packages/cupertino_ui | 1.2.0 / 1.0.2; Cupertino'da cam yok |
| https://github.com/flutter/flutter/issues/168813 | M3 Expressive SDK'da aktif geliştirilmiyor; hedef bileşen listesi |
| https://github.com/flutter/flutter/issues/170310 | Cupertino Liquid Glass çalışması durduruldu, paketlere taşındı |
| https://docs.flutter.dev/platform-integration/ios/ios-latest | Liquid Glass, iPad tab bar, zoom geçişi hâlâ desteklenmiyor |
| https://design.google/library/expressive-material-design-google-research | 46 çalışma, 18k katılımcı; kilit öğeler 4 kata kadar hızlı bulunuyor |
| https://raw.githubusercontent.com/androidx/androidx/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExpressiveMotionTokens.kt | Expressive spring değerleri (StandardMotionTokens.kt ile karşılaştırıldı) |
| https://www.macrumors.com/2026/06/10/how-liquid-glass-is-changing-in-ios-27/ | iOS 27: şeffaflık kaydırıcısı, okunurluk, Reduce Transparency uyumu |
| https://www.macrumors.com/guide/ios-27-calendar-reminders/ | iOS 27 Reminders: doğal dil ve extra-large widget |
| https://www.learnui.design/blog/ios-design-guidelines-templates.html | iOS 26 yüzen tab bar, search tab, accessory kalıpları |
| https://pub.dev/packages/liquid_glass_widgets | 1.5.0, shader tabanlı cam, a11y fallback, Flutter ≥3.41 |
| https://pub.dev/packages/adaptive_platform_ui | Platform view ile native cam; deneysel parçalar |
| https://www.todoist.com/help/articles/2026-changelog-HD3jJAtLd | Türkçe NLP (Mayıs 2026), sade Quick Add (Ağu 2026), Android M3 Expressive |
| https://culturedcode.com/things/blog/ | Things 3.23: tekrarlayanları erken tamamla ve yeniden planla |
| https://ticktick.com/features | NLP, timeline, widget'tan hızlı ekleme |
| https://techcrunch.com/2025/12/04/ai-finds-its-way-into-apples-top-apps-of-the-year | Tiimo 2025 iPhone Yılın Uygulaması (görsel zaman çizelgesi) |
| https://9to5google.com/2026/06/04/google-tasks-expressive-widget/ | Google Tasks widget'ı: hap "+" düğmesi, dinamik renk |
| https://developer.apple.com/design/human-interface-guidelines/widgets | Widget aileleri, etkileşim, tinted/clear render modları |
| https://developer.android.com/design/ui/widget | Canonical layout'lar, boyutlandırma, renk token'ları |
| https://developer.android.com/develop/ui/views/notifications/live-update | Live Updates: takvim etkinlikleri ve uyarılar uygunsuz kullanım |
| https://www.levelaccess.com/compliance-overview/european-accessibility-act-eaa/ | EAA yürürlükte; EN 301 549 / WCAG 2.2 AA |
| https://design.google/library/google-sans-flex-font · https://fonts.google.com/specimen/Google+Sans+Flex | Google Sans Flex açık kaynak; ROND ekseni, latin-ext |
| https://pub.dev/packages/motor | M3 ve Cupertino spring preset'leri tek API'de |
| https://pub.dev/packages/flutter_local_notifications | 22.3.1; bildirim aksiyonları |
| https://pub.dev/packages/home_widget | 0.9.4; widget'lar native yazılır |
| https://pub.dev/packages/dynamic_color | 2.1.0; material_ui bağımlılığı |
| https://pub.dev/packages/m3e_collection | 0.3.7, 10 ay güncellenmemiş |
| https://pub.dev/packages/flutter_slidable · https://pub.dev/packages/table_calendar · https://pub.dev/packages/google_fonts · https://pub.dev/packages/flutter_animate | Sürüm ve bakım durumu (§5.1) |
| https://github.com/kekko7072/flutter_local_ai · https://pub.dev/packages/edge_gen_ai | Cihaz içi AI mümkün ama cihaz kısıtlı |
