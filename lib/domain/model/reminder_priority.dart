/// Hatırlatıcı önceliği (F3.4): 0 yok, 1 düşük, 2 orta, 3 yüksek.
///
/// Hızlı yakalama ayrıştırıcısının `!` / `!!` / `!!!` ölçeğiyle aynıdır
/// (`CaptureParseResult.priority`). Renk tek sinyal değildir (§3.6): kartlar
/// "!!!" işaretini, ekran okuyucu "Yüksek öncelik" metnini alır. Metinler
/// arayüzdedir (`PriorityPinVisuals.label` / `spoken`, F6.1).
abstract final class ReminderPriority {
  static const none = 0;
  static const low = 1;
  static const medium = 2;
  static const high = 3;

  /// Sıralı değerler (editördeki segmentler).
  static const values = [none, low, medium, high];

  /// Aralık dışı değerleri (bozuk yedek, eski sürüm) 0–3'e sıkıştırır.
  static int normalize(int? value) {
    if (value == null || value < none) return none;
    if (value > high) return high;
    return value;
  }

  /// Kart işareti: "!" / "!!" / "!!!"; öncelik yoksa boş metin.
  static String marker(int priority) => '!' * normalize(priority);
}
