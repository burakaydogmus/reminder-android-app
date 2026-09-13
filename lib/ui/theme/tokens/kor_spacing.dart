import 'package:flutter/widgets.dart';

/// Kor spacing scale (4pt base) and fixed component sizes.
///
/// Source: `kor-design-proposal.md` §3.1 "Boşluk", `kor-screens.json`
/// `tokens.spacing` / `tokens.sizes`.
abstract final class KorSpacing {
  static const double s0 = 0;
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 56;

  // Semantic aliases.
  static const double screenEdge = s5;
  static const double cardGap = s3;
  static const double sectionGap = s7;
  static const double cardPaddingCompact = s4;
  static const double cardPadding = s5;
  static const double timeGutter = s10;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenEdge);

  /// ReminderCard padding from `components.ReminderCard.padding`.
  static const EdgeInsets reminderCardPadding =
      EdgeInsets.fromLTRB(4, 10, 16, 10);
}

/// Fixed sizes (`tokens.sizes`).
abstract final class KorSizes {
  static const double minTouch = 48;
  static const double iconSm = 20;
  static const double icon = 24;
  static const double checkboxVisual = 26;
  static const double navBarHeight = 64;
  static const double captureBarHeight = 52;
  static const double fab = 56;
  static const double timeGutter = 56;
}
