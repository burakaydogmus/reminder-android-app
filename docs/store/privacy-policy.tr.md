# Hatırlatıcı — Gizlilik Politikası

**Son güncelleme:** 13 Eylül 2026
**Uygulama:** Hatırlatıcı (Android: `com.burakaydogmus.reminder`, iOS bundle ID: `com.burakaydogmus.reminder`)
**İletişim:** `<iletişim e-postası>`

> **Yayın notu (mağazaya göndermeden önce):** Google Play ve App Store, gizlilik politikasının
> herkese açık, PDF olmayan, bölge kısıtlaması olmayan bir web adresinde yayınlanmasını ve
> uygulama içinden bağlantı verilmesini ister. Bu dosya henüz öyle bir adreste yayında değildir.
> Seçenekler için bu belgenin sonundaki **Barındırma** bölümüne bakın. Yayınlamadan önce
> `<iletişim e-postası>` yer tutucusu gerçek bir iletişim adresiyle değiştirilmelidir.

## Özet

- Hatırlatıcı **hesap istemez**, **reklam ve analiz aracı içermez**, verilerini gönderdiği
  **bize ait bir sunucu yoktur**.
- Hatırlatıcıların, doğum günlerin ve ayarların **yalnızca cihazında** saklanır.
- Konumun cihazda kullanılır: haritada yer seçmek ve seçtiğin yere vardığında hatırlatmak için.
- İnternete yalnızca iki durumda çıkılır: harita karolarını OpenStreetMap'ten indirmek ve (yalnızca
  bu özelliği içeren derlemelerde) yakındaki marketleri Google Places'ta aramak.
- Yedek dosyası yalnızca sen istediğinde oluşturulur ve senin seçtiğin yere paylaşılır.

## 1. Cihazında saklanan veriler

Uygulamaya girdiğin her şey cihazın içindeki uygulama alanında tutulur:

| Veri | Nerede | Amaç |
|---|---|---|
| Hatırlatıcılar (başlık, not, kategori, saat, seçilen konum ve yarıçap, tamamlanma durumu) | SQLite veritabanı (Drift), uygulama destek klasörü | Uygulamanın temel işlevi |
| Doğum günleri (ad, tarih, not, kaç gün önce hatırlatılacağı) | Aynı veritabanı | Yıllık doğum günü hatırlatmaları |
| Ayarlar (tema, bildirim tercihleri) | Aynı veritabanı | Tercihlerini hatırlamak |
| Tanıtım ekranının ve izin açıklamalarının gösterilip gösterilmediği, bildirim zamanlama kayıtları, konum bölgesi kayıtları | SharedPreferences (Android) / UserDefaults (iOS) | Uygulamanın doğru çalışması |
| Ana ekran aracında gösterilen hatırlatıcı listesi (Android) | Widget için SharedPreferences | Ana ekran aracını güncellemek |

Bu verilere biz erişemeyiz; hiçbir sunucuya gönderilmez.

**Silme:**

- Tek bir hatırlatıcıyı sildiğinde listeden kalkar; veritabanında "silindi" olarak işaretlenmiş
  bir kayıt olarak kalır (ileride senkron desteği için hazırlık). Bu kayıt da cihaz dışına çıkmaz.
- **Ayarlar → Tüm verileri sıfırla** hatırlatıcıları, doğum günlerini ve ayarları veritabanından
  kalıcı olarak siler, bekleyen bildirimleri ve konum bölgelerini kaldırır.
- Uygulamayı kaldırdığında uygulama alanındaki tüm veriler işletim sistemi tarafından silinir.
- Android'de uygulamanın sistem yedeğine (Google hesabına otomatik yedekleme) dahil edilmesi
  kapalıdır (`android:allowBackup="false"`). iOS'ta cihazın iCloud / bilgisayar yedeğine uygulama
  verilerinin dahil edilip edilmediği sistem ayarlarına bağlıdır (*doğrulanmalı*).

## 2. Konum

Konum iznini yalnızca konumlu bir hatırlatıcı oluştururken veya harita açıldığında, önce bir
açıklama göstererek isteriz. İzin vermezsen de yeri haritadan elle seçebilirsin.

- **Haritada yer seçme:** "Konumuma git" dediğinde cihazın o anki konumu alınır ve haritayı
  ortalamak için kullanılır. Konum kaydedilmez; yalnızca senin seçtiğin nokta hatırlatıcıyla
  birlikte cihazda saklanır.
- **Konuma varınca hatırlatma (arka planda konum):** Konumlu hatırlatıcılar için seçtiğin
  noktalar işletim sisteminin bölge izleme (geofence) servisine kaydedilir. Bölgeye girdiğinde
  sistem uygulamayı uyandırır ve cihazda bir bildirim gösterilir. **Uygulama kapalıyken** de
  çalışması için "Her zaman" konum izni gerekir. Konum geçmişin tutulmaz, konumun bize veya
  başka birine gönderilmez.
- Bölge izleme, Android'de Google Play Hizmetleri'nin konum API'si, iOS'ta Core Location
  üzerinden yapılır. Bu sistem servislerinin konum verisini nasıl işlediği cihaz üreticisinin /
  işletim sisteminin gizlilik koşullarına tabidir.

İzni istediğin zaman sistem ayarlarından kapatabilirsin; bu durumda konumlu hatırlatmalar
çalışmaz, diğer özellikler çalışmaya devam eder.

## 3. Bildirimler

Tüm bildirimler **yerel bildirimdir**: cihazda zamanlanır ve cihazda gösterilir. Anlık bildirim
(push) servisi kullanılmaz, bildirim içeriği hiçbir sunucudan geçmez. Android'de hatırlatmaların
dakikasında gelmesi için "Alarmlar ve hatırlatıcılar" iznini isteyebiliriz. Bildirim içeriği
(hatırlatıcı başlığı) cihaz ayarlarına göre kilit ekranında görünebilir.

## 4. İnternet bağlantısı kullanan özellikler

Uygulama yalnızca aşağıdaki durumlarda internete bağlanır. Bu isteklerde hesap bilgisi veya
hatırlatıcı içeriği gönderilmez.

### 4.1 OpenStreetMap harita karoları

Konum seçici haritası açıldığında harita görüntüleri (karolar)
`tile.openstreetmap.org` adresinden indirilir. Her istekte, internet bağlantısının doğal bir
sonucu olarak **IP adresin**, uygulamayı tanımlayan **kullanıcı aracısı (user agent)** ve
görüntülenen harita bölgesi OpenStreetMap Vakfı (OSMF) sunucularına ulaşır. Bu veriler OSMF'nin
politikalarına tabidir:

- OSMF Gizlilik Politikası: <https://osmfoundation.org/wiki/Privacy_Policy>
- Karo Kullanım Politikası: <https://operations.osmfoundation.org/policies/tiles/>

### 4.2 Google Places ile yakındaki market araması (isteğe bağlı)

Bu özellik **yalnızca Google Maps API anahtarıyla derlenmiş sürümlerde** bulunur; anahtarsız
sürümlerde "Yakındaki marketleri göster" düğmesi hiç görünmez ve Google'a istek yapılmaz.

Özelliğin bulunduğu bir sürümde düğmeye bastığında, haritada seçili noktanın **koordinatları**
(enlem/boylam), arama yarıçapı ve yer türü Google'ın Places API'sine (`maps.googleapis.com`)
gönderilir; bu istekle IP adresin de Google'a ulaşır. Seçtiğin marketin adı ve konumu
hatırlatıcıyla cihazda saklanabilir. Google'ın bu verileri işlemesi Google Gizlilik Politikası'na
tabidir: <https://policies.google.com/privacy>

## 5. Yedekleme (dışa ve içe aktarma)

- **Dışa aktarma** yalnızca **Ayarlar → Yedekle** ile başlar. Hatırlatıcıların, doğum günlerin,
  ayarların ve uygulama sürümü bir JSON dosyasına yazılır, geçici klasöre kaydedilir ve sistemin
  **paylaşım menüsü** açılır. Dosyanın nereye gideceğini (ör. Dosyalar, Drive, e-posta) sen
  seçersin; o andan sonra dosya seçtiğin uygulamanın/hizmetin gizlilik koşullarına tabidir.
  Dosya şifrelenmez; güvenli bir yerde saklamanı öneririz. Geçici kopya işletim sistemi
  tarafından temizlenir.
- **İçe aktarma** yalnızca **Ayarlar → Geri yükle** ile, senin seçtiğin dosyayı cihazda okur.

## 6. Kullanmadıklarımız

- Kullanıcı hesabı, giriş, bulut senkronu
- Reklam, reklam kimliği, izleme (tracking)
- Analiz, kullanım istatistiği, çökme raporlama servisi
- Rehber, kamera, mikrofon, fotoğraf erişimi
- Uygulama içi satın alma

Bunlardan biri ileride eklenirse bu politika uygulama güncellemesinden önce güncellenecektir.

## 7. Çocuklar

Uygulama genel kitleye yöneliktir ve çocuklardan bilerek kişisel veri toplamaz; zaten
hiçbir kişisel veri cihaz dışına aktarılmaz (bkz. bölüm 4 istisnaları).

## 8. Hakların

Kişisel verilerin (ör. KVKK veya GDPR kapsamında) cihazında tutulduğu için erişim, düzeltme ve
silme haklarını doğrudan uygulama içinden kullanabilirsin: kayıtları düzenleyebilir, silebilir,
yedek alabilir veya tüm verileri sıfırlayabilirsin. Bizde senin hakkında saklanan bir veri
bulunmaz. OpenStreetMap ve Google'a ulaşan veriler için ilgili şirketlerin politikalarına
başvurabilirsin. Soruların için: `<iletişim e-postası>`

## 9. Değişiklikler

Bu politika değişirse güncel sürüm aynı adreste yayınlanır ve "Son güncelleme" tarihi değişir.
Önemli değişiklikler uygulama güncelleme notlarında da belirtilir.

---

## Barındırma (yayın öncesi yapılacak, henüz etkin değil)

Mağaza başvurusu için bu metnin herkese açık bir URL'de yayınlanması gerekir. Önerilen yol:

1. **GitHub Pages** (repo herkese açık olduğu için ücretsiz): GitHub → *Settings → Pages →
   Build and deployment → Deploy from a branch → `master` / `/docs`*. Jekyll Markdown'ı HTML'e
   çevirir; adres büyük olasılıkla
   `https://burakaydogmus.github.io/reminder-android-app/store/privacy-policy.tr.html` olur
   (*doğrulanmalı* — ilk yayından sonra adres kontrol edilmeli).
2. Alternatif: ayrı bir `gh-pages` dalı veya kişisel alan adında statik sayfa.
3. Yayından sonra URL; Play Console (*Uygulama içeriği → Gizlilik politikası*), App Store Connect
   (*App Privacy → Privacy Policy URL*) ve uygulama içindeki Ayarlar ekranına (henüz bağlantı yok,
   bkz. `permissions-review.md` yapılacaklar) eklenmeli.
