# Google Play — Data safety formu cevapları

Durum: 26 Eylül 2026 (F8.1 cihaz takvimi satırı eklendi; öncesi 13 Eylül 2026, `master` @ 4038806). Kod değişirse (özellikle
F6.3 çökme raporlama, F7.x bulut senkronu) bu formun **yeniden** doldurulması gerekir.

Kaynak: [Data safety bölümü yardım sayfası](https://support.google.com/googleplay/android-developer/answer/10787469)

## Tanımlar (formu cevaplarken esas alınanlar)

- **Toplama (collection):** Verinin uygulamadan (kütüphaneler/SDK'lar dahil) *cihaz dışına*
  aktarılması. Yalnızca cihazda işlenen veri beyan edilmez.
- **Paylaşma (sharing):** Toplanan verinin üçüncü tarafa aktarılması. Kullanıcının başlattığı ve
  paylaşılmasını makul olarak beklediği aktarımlar (ör. paylaşım menüsüyle dosya gönderme) ve
  geliştirici adına çalışan hizmet sağlayıcılar paylaşma sayılmaz.
- **Geçici işleme (ephemeral):** Cihaz dışına çıkıp yalnızca isteği karşılamak için bellekte
  işlenen veri formda belirtilir; koşulları sağlarsa mağaza sayfasında gösterilmez.
- Uygulama hiç veri toplamasa bile form doldurulmalı ve gizlilik politikası bağlantısı verilmelidir.

## Koddan tespitler

| Kod | Ağ trafiği / veri akışı |
|---|---|
| `lib/data/**` (Drift `reminder.sqlite`, SharedPreferences) | Yalnızca cihaz. Sunucu, SDK, analiz yok. |
| `lib/services/notification_service.dart` | Yerel bildirim (`flutter_local_notifications`), push yok. |
| `lib/services/device_calendar_service.dart` (F8.1, `device_calendar_plus`) | Cihaz takvimi **yalnızca okunur** (`CalendarContract` / EventKit), kullanıcı Ayarlar'dan açtıysa. Etkinlikler bellekte tutulur, veritabanına yazılmaz ve hiçbir sunucuya gönderilmez. Yazma metodu yok. |
| `lib/services/contacts_service.dart` (F7.3, `flutter_contacts`) | Rehber **yalnızca okunur** ve **yalnızca bir kez**, kullanıcı "Rehberden aktar"a bastığında. `getAll` yalnızca `ContactProperty.event` ile çağrılır: ad + doğum tarihi dışında hiçbir alan (kişi kimliği, fotoğraf, telefon, e-posta) istenmez. Seçilen doğum günleri uygulamanın kendi veritabanına yazılır; hiçbir sunucuya gönderilmez. Yazma metodu yok, arka plan senkronu yok. |
| `lib/services/geofence_*.dart` (`native_geofence`) | Bölgeler işletim sistemine kaydedilir; olaylar cihazda işlenir. Uygulama koordinatları hiçbir sunucuya göndermez. |
| `lib/ui/maps/location_picker_page.dart` | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` karo indirir (IP + user agent + görüntülenen bölge OSMF'ye ulaşır). Konum parametresi göndermez; karo adresi yalnızca görüntülenen harita bölgesini içerir. |
| `lib/services/places_nearby_service.dart` | **Yalnızca `GOOGLE_MAPS_KEY` ile derlenmişse** (`mapsConfigured`) ve kullanıcı Market kategorisinde "Yakındaki marketleri göster"e basarsa: seçili noktanın enlem/boylamı `maps.googleapis.com`'a gider. Anahtarsız derlemede düğme görünmez, istek yapılmaz. |
| `lib/data/backup/backup_io.dart` | JSON yedek geçici klasöre yazılır, `share_plus` ile sistem paylaşım menüsü açılır — kullanıcı başlatır, hedefi kullanıcı seçer. Geliştiriciye veri gelmez. |
| `pubspec.yaml` | Firebase, reklam, analiz, çökme raporlama SDK'sı yok. |

## Önerilen yayın yapılandırması

**Release derlemeleri `GOOGLE_MAPS_KEY` olmadan yapılmalı.** Nedeni yalnızca gizlilik formu değil:
Places sonuçları OpenStreetMap haritasında, Google atfı olmadan gösteriliyor ve seçilen yerin adı
saklanıyor; bu Google Maps Platform koşullarıyla çelişiyor olabilir (ayrıntı:
[`permissions-review.md`](permissions-review.md) §5). Aşağıdaki **A sütunu** bu yapılandırma
içindir.

## Veri türleri tablosu

A = anahtarsız derleme (önerilen) · B = `GOOGLE_MAPS_KEY` ile derleme

| Veri türü (Play kategorisi) | A: Toplanıyor? | A: Paylaşılıyor? | B: Toplanıyor? | B: Paylaşılıyor? | Amaç | İsteğe bağlı? | Gerekçe |
|---|---|---|---|---|---|---|---|
| Konum → Kesin konum | Hayır | Hayır | **Evet** | Hayır (*doğrulanmalı*) | Uygulama işlevselliği | Evet (kullanıcı düğmeye basarsa) | A: GPS konumu ve seçilen noktalar cihazda kalır; geofence OS'ta işlenir. B: Places isteği koordinatı tam hassasiyetle gönderir (<3 km² → kesin). Google, geliştirici adına API hizmeti veren taraf olarak değerlendirilirse "paylaşma" sayılmaz; bu yorum *doğrulanmalı*. Geçici işlenir: **Evet** (uygulama/geliştirici saklamaz). |
| Konum → Yaklaşık konum | Hayır | Hayır | Hayır | Hayır | — | — | Ayrı yaklaşık konum gönderimi yok. IP'den türetilebilecek konum için aşağıdaki not. |
| Kişisel bilgiler (ad, e-posta, kullanıcı kimliği, adres, telefon…) | Hayır | Hayır | Hayır | Hayır | — | — | Hesap yok. Doğum günü kayıtlarındaki kişi adları yalnızca cihazda — F7.3'te rehberden aktarılanlar da (ad + tarih) cihazda kalıyor. |
| Finansal bilgiler | Hayır | Hayır | Hayır | Hayır | — | — | Satın alma yok. |
| Sağlık ve fitness | Hayır | Hayır | Hayır | Hayır | — | — | "Sağlık" yalnızca bir kategori etiketi, cihazda. |
| Mesajlar / e-posta / SMS | Hayır | Hayır | Hayır | Hayır | — | — | — |
| Fotoğraflar ve videolar / Ses | Hayır | Hayır | Hayır | Hayır | — | — | — |
| Dosyalar ve dokümanlar | Hayır | Hayır | Hayır | Hayır | — | — | Yedek dosyası kullanıcı başlatınca, kullanıcının seçtiği hedefe gider; geliştiriciye aktarım yok (kullanıcı başlatımlı aktarım istisnası). |
| Takvim (etkinlikler) | Hayır | Hayır | Hayır | Hayır | — | — | **F8.1:** kullanıcı Ayarlar'dan açarsa cihaz takvimi **okunuyor**, ama veri cihaz dışına çıkmıyor → Play tanımına göre "toplama" değil. Yazma yok (`WRITE_CALENDAR` tanımlı değil). Uygulamanın kendi hatırlatıcıları da cihazda. |
| Kişiler | Hayır | Hayır | Hayır | Hayır | — | — | **F7.3:** kullanıcı "Rehberden aktar"a basarsa rehber **bir kez okunuyor**; veri cihaz dışına çıkmıyor → Play tanımına göre "toplama" değil. Yalnızca ad + tarih uygulamanın kendi veritabanına yazılıyor (kişi kimliği/fotoğraf/telefon hiç okunmuyor), yazma yok (`WRITE_CONTACTS` tanımlı değil). Bkz. `permissions-review.md` §10 — 27 Ocak 2027 Contacts Permissions politikası targetSdk 37+ için beyan istiyor. |
| Uygulama etkinliği (etkileşimler, arama geçmişi, kullanıcı içerikleri) | Hayır | Hayır | Hayır | Hayır | — | — | Hatırlatıcı metinleri kullanıcı içeriği ama cihaz dışına çıkmıyor. |
| Web tarama | Hayır | Hayır | Hayır | Hayır | — | — | — |
| Uygulama bilgileri ve performans (çökme kayıtları, tanılama) | Hayır | Hayır | Hayır | Hayır | — | — | Çökme raporlama yok. F6.3'te eklenirse **Evet** olur. |
| Cihaz veya diğer kimlikler | Hayır | Hayır | Hayır | Hayır | — | — | Reklam kimliği / cihaz kimliği okunmuyor. |

**IP adresi ve user agent (OSM karoları, Places istekleri):** Play formunda IP adresi için ayrı bir
veri türü yoktur. Uygulama IP'yi okumaz veya göndermez; ağ bağlantısının doğal sonucu olarak
sunucuya ulaşır. Önerilen cevap: beyan edilmez. OSM karo istekleri kullanıcı konumu içermez
(görüntülenen harita bölgesi, kullanıcı haritayı elle kaydırdığında konumdan bağımsızdır; ancak
"Konumuma git" sonrası görüntülenen bölge dolaylı olarak yaklaşık konumu yansıtır). Bu dolaylı
durumun beyan gerektirip gerektirmediği Play yardımında açıkça ele alınmıyor — *doğrulanmalı*;
temkinli seçenek A derlemede de "Yaklaşık konum: toplanıyor, geçici, uygulama işlevselliği,
paylaşılmıyor" demektir. Önerimiz: harita karoları konum verisi olarak işlenmediği için
"toplanmıyor", bu gerekçeyi iç notlarda saklayarak.

## Formun genel soruları

| Soru | Cevap (A) | Not |
|---|---|---|
| Uygulama gerekli kullanıcı veri türlerinden herhangi birini topluyor veya paylaşıyor mu? | **Hayır** | B derlemede: Evet (Kesin konum). |
| Toplanan tüm veriler aktarımda şifreleniyor mu? | (A'da sorulmaz) | B: **Evet** — Places isteği HTTPS (`Uri.https`). |
| Kullanıcılar verilerinin silinmesini isteyebilir mi? | (A'da sorulmaz) | B: Geliştirici veri saklamıyor; uygulamada **Ayarlar → Tüm verileri sıfırla** ve kaldırma ile yerel veri silinir. |
| Hesap oluşturma | Yok | Hesap silme bağlantısı zorunluluğu uygulanmaz. |
| Bağımsız güvenlik incelemesi (MASA) | Hayır | İsteğe bağlı. |
| Aile politikası / çocuklara yönelik | Hayır | Hedef kitle genel. |
| Gizlilik politikası URL'si | Zorunlu | `docs/store/privacy-policy.*.md` önce yayınlanmalı. |

## İlgili ama Data safety dışı beyanlar

- **Konum izinleri beyanı** (`ACCESS_BACKGROUND_LOCATION`) ayrı bir formdur — bkz.
  [`permissions-review.md`](permissions-review.md). **Exact alarm** beyanı gerekmez:
  `USE_EXACT_ALARM` kaldırıldı, yalnızca kullanıcının verdiği `SCHEDULE_EXACT_ALARM` var (F6.2c).
- Harici SDK'larda gizli trafik olmadığı `pubspec.lock` üzerinden tekrar kontrol edilmeli
  (her bağımlılık güncellemesinden sonra).
