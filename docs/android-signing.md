# Android imzalama (kişisel kullanım ve sonrası)

Bu belge CI'ın ürettiği APK'nın nasıl imzalandığını ve kendi cihazında sorunsuz
güncelleyebilmek için ne yapman gerektiğini anlatır.

## Neden gerekli

Android bir APK'yı, kurulu sürümle **aynı anahtarla** imzalanmışsa günceller;
imza farklıysa kurulumu reddeder ve tek çözüm uygulamayı silmek olur —
yani yerel veritabanının silinmesi.

`android/key.properties` yokken Gradle release derlemesini **debug anahtarıyla**
imzalar. CI koşucuları her koşuda sıfırdan kurulduğu için o debug anahtarı her
seferinde yeniden üretilir: iki farklı CI koşusundan indirilen APK'lar farklı
imza taşır, üst üste kurulamaz. Bu yüzden kişisel kullanım için de kalıcı bir
anahtar gerekir.

## Anahtarı üretme (bir kez)

```powershell
New-Item -ItemType Directory -Force C:\Users\<kullanıcı>\keys | Out-Null
Set-Location C:\Users\<kullanıcı>\keys
keytool -genkey -v -keystore reminder-personal.jks -keyalg RSA -keysize 4096 `
  -validity 10000 -alias reminder -dname "CN=..., O=Personal, C=TR"
```

Dosyayı **repo dışında** tut (bu proje git worktree kullanıyor; worktree'ler
geri dönüştürüldüğünde takip edilmeyen dosyalar silinir) ve **yedekle**:
anahtar kaybolursa aynı imzayla bir daha APK üretilemez, kurulu uygulama
güncellenemez.

## GitHub gizli değişkenleri

Repo → Settings → Secrets and variables → Actions → *New repository secret*:

| Ad | Değer |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `.jks` dosyasının base64 hâli (aşağıya bak) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore parolası |
| `ANDROID_KEY_PASSWORD` | anahtar parolası (aynıysa keystore parolasının aynısı) |
| `ANDROID_KEY_ALIAS` | `reminder` (varsayılan; alias'ı değiştirdiysen onu yaz) |

Base64'e çevirme (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\<kullanıcı>\keys\reminder-personal.jks")) `
  | Set-Content -NoNewline -Encoding ascii C:\Users\<kullanıcı>\keys\keystore.b64
```

Çıkan `keystore.b64` dosyasının içeriğini `ANDROID_KEYSTORE_BASE64` değerine
yapıştır. Parolalar komut satırına yazılmasın diye `gh` ile de eklenebilir
(`gh secret set ANDROID_KEYSTORE_PASSWORD --repo <owner>/<repo>` parolayı
gizli olarak sorar).

`ANDROID_KEY_ALIAS` ve `ANDROID_KEY_PASSWORD` eklenmezse iş akışı sırasıyla
`reminder` ve keystore parolasını varsayar.

## CI ne yapıyor

`.github/workflows/android.yml` içindeki "Write the signing config" adımı
`ANDROID_KEYSTORE_BASE64` doluysa anahtarı runner'ın geçici dizinine çözer ve
`android/key.properties` dosyasını yazar (mutlak `storeFile` yolu ile — Gradle
göreli yolu `android/app` altında arar). Gerisi mevcut Gradle yapılandırması:
`signingConfigs.release`.

- Artifact adı imzaya göre değişir: `app-release-apk` (kişisel anahtar) veya
  `app-release-debugsigned-apk` (anahtar yok).
- "Show the APK signer" adımı APK'yı imzalayan sertifikayı yazdırır. Kişisel
  anahtarla imzalanmışsa `Owner` senin `-dname` değerin olur; SHA-256 parmak izi
  `keytool -list -v -keystore reminder-personal.jks` çıktısıyla eşleşmelidir.
  Debug anahtarıyla imzalanmışsa `CN=Android Debug` görünür.
- Gizli değişkenler yoksa iş akışı yine çalışır (fork'lar ve yeni klonlar
  bozulmaz), sadece APK'lar üst üste kurulamaz.

## Cihaza kurma

Actions → Android build → son koşu → Artifacts → APK'yı indir, telefona kopyala
ve kur (bilinmeyen kaynaklara izin vermen gerekebilir). Artifact'lar 7 gün
sonra silinir.

İlk kez kalıcı anahtara geçerken, cihazda **debug anahtarıyla imzalanmış** bir
sürüm kuruluysa o silinmek zorunda: önce uygulama içinden yedek al
(Ayarlar → Yedekleme), uygulamayı sil, yeni APK'yı kur, yedeği geri yükle.
Sonraki güncellemeler sorunsuz üst üste kurulur.

## Mağaza yayını (sonra)

Play Store için ayrıca **AAB** (`flutter build appbundle --release`) ve Play App
Signing kurulumu gerekir; buradaki anahtar o zaman **upload key** olur. Tag ile
tetiklenen imzalı release iş akışı ROADMAP F6.3 maddesidir ve henüz yapılmadı.
