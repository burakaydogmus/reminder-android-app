# Mağaza sayfası taslağı — Türkçe

Durum: 18 Eylül 2026 kodu (tekrarlayan hatırlatmalar F3.1 ve bildirim eylemleri F3.2 dahil).
Yalnızca **bugün çalışan** özellikler yazıldı. Henüz yapılmamış olanlar (doğal dille hızlı yakalama
F4.6, iOS widget F5.2, zaman şeridi F3.6) eklendiğinde metin güncellenmeli. Mağaza metinleri uygulamanın
gerçek deneyimini yansıtmalı (App Store §2.3; Play meta veri politikası).

Sınırlar: Play başlık 30, kısa açıklama 80, tam açıklama 4000 karakter
([Play yardım](https://support.google.com/googleplay/android-developer/answer/9859152)); App Store
ad ve alt başlık 30 karakter, anahtar kelimeler 100
([App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/),
[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
— anahtar kelime sınırı bu sayfada **bayt** olarak geçiyor; Türkçe harfler UTF-8'de 2 bayt olduğu
için 100 baytı aşmamak güvenli yol).

Aşağıdaki uzunluklar 18 Eylül 2026'da betikle ölçüldü: karakter = Unicode kod noktası (Python
`len`), bayt = UTF-8. Metin değişirse yeniden ölçülmeli.

## Uygulama adı seçenekleri (≤ 30)

| Seçenek | Uzunluk | Not |
|---|---|---|
| Hatırlatıcı | 11 | Mevcut `CFBundleDisplayName`. Genel bir kelime; mağazada ayırt edilmesi zor, aynı adlı uygulamalar olabilir (*doğrulanmalı*). |
| Kor: Hatırlatıcı | 16 | Tasarım adını marka yapar. |
| Kor – Hatırlatıcı ve Listeler | 29 | |
| Hatırlatıcı: Zaman ve Konum | 27 | Özelliği anlatır, anahtar kelime içerir. |
| Kor: Hatırlatma & Doğum Günü | 28 | |

**Öneri:** Mağaza adı "Kor: Hatırlatıcı", ana ekranda "Hatırlatıcı" kalabilir.
App Store alt başlık (≤ 30): **"Zamanında, yerinde hatırlat"** (27).

## Kısa açıklama (Play, ≤ 80)

> Saatinde ya da vardığın yerde hatırlatır. Doğum günleri, listeler; veri cihazda.

(80 karakter — sınırda; önceki taslak "… veriler cihazda." 83 karakterdi.)

## Tam açıklama (Play / App Store, ≤ 4000)

```text
Aklında kalmasın. Yaz, zamanını ya da yerini seç; gerisini Hatırlatıcı takip etsin.

BUGÜN'Ü TEK BAKIŞTA GÖR
Bugün ekranı işlerini gecikenler, bugün, zamansız ve tamamlananlar olarak gruplar. Takvim sekmesi önümüzdeki 30 günü hatırlatıcılar ve doğum günleriyle birlikte gösterir. Listeler sekmesinde kategorilere göre süzersin.

SAATİNDE HATIRLAT
Bir hatırlatıcıya tarih ve saat ekle, zamanı gelince bildirim gelsin. Geçmiş bir saati seçersen sessizce değiştirmez, seni uyarır ve "Yarın aynı saatte mi?" diye önerir.

VARDIĞIN YERDE HATIRLAT
Haritadan bir yer seç, yarıçapı belirle. Oraya vardığında bildirim gelir; uygulama kapalıyken bile. "Markete gidince ekmek al" gibi.

DOĞUM GÜNLERİNİ UNUTMA
Doğum günlerini bir kez ekle, her yıl hatırlatılsın. İstersen bir gün ya da bir hafta önceden haber alırsın. 29 Şubat doğumlular da unutulmaz.

TEKRARLA
Her gün, her hafta seçtiğin günlerde, her ay ya da birkaç günde bir. İstersen bir bitiş tarihi koy. Tekrarlayan bir hatırlatıcıyı tamamlayınca bir sonraki tekrara geçer.

BİLDİRİMDEN BİTİR
Bildirimdeki düğmelerle uygulamayı açmadan tamamla ya da 10 dakika, 1 saat sonraya ertele.

KAYDIR, BİTİR, GERİ AL
Sağa kaydır: tamamla. Sola kaydır: ertele ya da sil. Yanlışlıkla mı yaptın? "Geri al" bir dokunuş uzağında. Aynı işlemler uzun basma menüsünde ve ekran okuyucu eylemlerinde de var.

KATEGORİLER
Market, ev, iş, sağlık, günlük işler ve kendi adını verdiğin "Diğer". Her kategorinin kendi rengi ve simgesi var.

ANA EKRAN ARACI (ANDROID)
Yaklaşan hatırlatıcıların ana ekranında dursun; uygulamayı açmadan tamamlandı olarak işaretle.

YEDEKLE, TAŞI
Tüm hatırlatıcılarını ve doğum günlerini tek bir dosyaya yedekle, istediğin yere kaydet. Geri yüklerken mevcut kayıtlarla birleştir ya da tamamen değiştir.

SAKİN VE SICAK BİR TASARIM
"Kor" tasarımı: göz yormayan sıcak tonlar, dikkat gerektiren tek şey için tek bir turuncu vurgu. Açık ve koyu tema, büyük yazı boyutu ve ekran okuyucu desteği, hareket azaltma tercihine uyum.

İLK GÜNDEN KOLAY
Kısa bir tanıtım uygulamayı gösterir. İzinleri açılışta hepsini birden istemez; yalnızca ihtiyaç duyulduğunda, nedenini açıklayarak ister.

GİZLİLİK: VERİLERİN CİHAZINDA
Hesap yok, reklam yok, analiz yok. Hatırlatıcıların, doğum günlerin ve konumun cihazından çıkmaz. İnternet yalnızca harita görüntülerini (OpenStreetMap) yüklemek için kullanılır.

Harita verileri © OpenStreetMap katkıcıları.
```

Uzunluk: 2.389 karakter (sınır 4000).

> Places ile "yakındaki marketler" özelliği mağaza sürümünde bulunmayacağı (anahtarsız derleme
> önerisi) için metne yazılmadı. iOS sürümünde "ANA EKRAN ARACI (ANDROID)" bölümü çıkarılmalı.

## App Store tanıtım metni (Promotional text, ≤ 170)

> Saatinde ya da vardığın yerde hatırlatır, doğum günlerini her yıl hatırlar. Hesap yok, reklam yok; verilerin cihazında kalır.

(125 karakter)

## Anahtar kelimeler (App Store, ≤ 100)

```text
hatırlatma,yapılacaklar,görev,alışveriş,market,doğum günü,konum,bildirim,ajanda,liste,not
```

Uygulama adında ve alt başlıkta geçen kelimeler (hatırlatıcı, zaman, yer) tekrar edilmedi.
89 karakter, **98 bayt** (UTF-8; Türkçe harfler 2 bayt) — 100 bayt sınırının altında, ama kelime
eklenecekse önce `ajanda` / `not` çıkarılmalı.

## Ekran görüntüsü planı

Her ekran **açık ve koyu** temada; Android telefon (1080×2400 veya 1080×1920) ve iOS 6,9"/6,5"
boyutları. Metinler Türkçe, örnek veriler gerçek kişi adı içermez ("Ayşe" gibi kurgusal ad veya
"Annem"). Durum çubuğu temiz (saat 09:41, tam pil). Başlıklar görüntünün üstünde, kısa.

| # | Ekran | Durum/örnek veri | Başlık |
|---|---|---|---|
| 1 | Bugün | Geciken 1, bugün 3 zamanlı, 2 zamansız, 1 tamamlanan | Bugünün tek bakışta |
| 2 | Hatırlatıcı editörü | "Ne zaman" chip'leri seçili, kategori Market | Saatinde hatırlat |
| 3 | Konum seçici | OSM haritası, yarıçap çemberi, atıf görünür | Vardığında hatırlat |
| 4 | Takvim | 30 günlük gündem, arada doğum günü kartı | Önündeki 30 gün |
| 5 | Doğum günleri | 3 kayıt, "5 gün kaldı" | Doğum günlerini unutma |
| 6 | Kaydırma | Kart yarıya kaydırılmış (Tamamla) + "Geri al" snackbar | Kaydır, bitir, geri al |
| 7 | Android widget | Ana ekranda liste aracı (yalnızca Play) | Ana ekranında |
| 8 | Ayarlar | Tema seçici, İzinler, Yedekle/Geri yükle | Yedekle, taşı |
| 9 | Onboarding 1/4 | Karşılama | Aklında kalmasın |

Play özellik grafiği (1024×500): kor turuncusu vurgulu Bugün ekranı kesiti + ad. Görüntüler
emülatör/simülatörden alınmalı; widget testlerindeki `UiHarness` + golden altyapısı (F4.5) ileride
otomatik görüntü üretimi için kullanılabilir.

## İçerik derecelendirmesi notları

**Play (IARC anketi):** Kategori "Yardımcı Program, Verimlilik, İletişim veya Diğer". Cevaplar:
kullanıcılar arası etkileşim/iletişim **yok**, kullanıcı içeriği başkalarıyla paylaşılmıyor,
konum başka kullanıcılarla **paylaşılmıyor**, dijital satın alma **yok**, reklam **yok**, şiddet/
cinsellik/hakaret/madde/hazard içerik **yok**. Beklenen sonuç: **3+ / PEGI 3 / Herkes**
(*anket sonucuyla doğrulanmalı*).

**App Store (yaş derecelendirmesi):** Tüm içerik soruları "Yok"; sınırsız web erişimi yok (harita
yalnızca karo). Beklenen: **4+**.

Ek Play beyanları: Reklam içeriyor mu → Hayır. Hedef kitle → 18+ ya da "13+ dahil genel"
(çocuklara yönelik değil; "Aile" programına girmez). Haber uygulaması → Hayır. Hükümet uygulaması
→ Hayır. Finans özellikleri → Yok. Sağlık uygulaması → Hayır ("Sağlık" yalnızca kategori etiketi).

## Kategori önerisi

- **Google Play:** Verimlilik (Productivity)
- **App Store:** Birincil **Productivity**, ikincil **Lifestyle**

## Diğer mağaza alanları

- Destek URL'si (App Store zorunlu): repo Issues sayfası veya GitHub Pages "Destek" sayfası.
- Gizlilik politikası URL'si: bkz. `privacy-policy.tr.md` → Barındırma.
- İletişim e-postası: `<iletişim e-postası>`
