import SwiftUI
import UIKit

/// Kor renkleri (F4.0b, `lib/ui/theme/tokens/kor_palette.dart`), Android
/// widget'larındaki `res/values/colors.xml` + `values-night/colors.xml` ile
/// **aynı** değerler.
///
/// iOS'ta dinamik sistem rengi yoktur (tasarım §3.1): açık/koyu iki sabit
/// palet. Accented / tinted ve clear (vibrant) render modlarında sistem tüm
/// grafiği tek renge indirir; o modlarda renk taşıyıcı değildir, bu yüzden her
/// durum metinle de anlatılır (ör. "Gecikti").
enum WidgetTheme {
  static let surface = dynamic(light: 0xFAF7F2, dark: 0x1D1B17)
  static let onSurface = dynamic(light: 0x1F1B16, dark: 0xEDE6DC)
  static let onSurfaceVariant = dynamic(light: 0x5C554C, dark: 0xB9B0A4)
  static let outline = dynamic(light: 0x8C8479, dark: 0x857D72)
  static let primary = dynamic(light: 0xB8430F, dark: 0xFF9B63)
  /// "+" hap ve "Bildirimler kapalı" şeridi (primaryContainer).
  static let pill = dynamic(light: 0xFFDCC8, dark: 0x6A2A08)
  static let onPill = dynamic(light: 0x4A1A00, dark: 0xFFDCC8)

  /// Kategori renkleri (`KorColorKey` `fg`); bilinmeyen anahtar → "diger".
  static func category(_ key: String) -> Color {
    switch key {
    case "market": return dynamic(light: 0x2E7031, dark: 0x8ED68A)
    case "ev": return dynamic(light: 0x00696B, dark: 0x6FD6D2)
    case "is": return dynamic(light: 0x2D5EA8, dark: 0x9EC2F7)
    case "saglik": return dynamic(light: 0xB0265E, dark: 0xFF9EC2)
    case "gunluk": return dynamic(light: 0x8A5300, dark: 0xF2BE6B)
    case "dogumgunu": return dynamic(light: 0x9A2A8A, dark: 0xF2A3E4)
    default: return dynamic(light: 0x6546C8, dark: 0xC2B1FF)
    }
  }

  private static func dynamic(light: UInt32, dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        traits.userInterfaceStyle == .dark ? color(dark) : color(light)
      })
  }

  private static func color(_ rgb: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((rgb >> 16) & 0xFF) / 255,
      green: CGFloat((rgb >> 8) & 0xFF) / 255,
      blue: CGFloat(rgb & 0xFF) / 255,
      alpha: 1
    )
  }
}
