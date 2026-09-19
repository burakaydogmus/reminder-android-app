import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  // 13 Sep 2026 is a Sunday.
  final now = DateTime(2026, 9, 13, 14, 32);

  test('upperTr keeps Turkish dotted/dotless i', () {
    expect(KorFormat.upperTr('istanbul ılık'), 'İSTANBUL ILIK');
    expect(KorFormat.upperTr('Sıradaki'), 'SIRADAKİ');
  });

  test('agenda day headers', () {
    expect(
      KorFormat.agendaDayHeader(DateTime(2026, 9, 13), now, AppL10n.turkish),
      'BUGÜN · PAZAR 13 EYLÜL',
    );
    expect(
      KorFormat.agendaDayHeader(DateTime(2026, 9, 14), now, AppL10n.turkish),
      'YARIN · PAZARTESİ 14 EYLÜL',
    );
    expect(
      KorFormat.agendaDayHeader(DateTime(2026, 9, 15), now, AppL10n.turkish),
      'SALI 15 EYLÜL',
    );
    expect(
      KorFormat.agendaDayHeader(DateTime(2027, 1, 4), now, AppL10n.turkish),
      'PAZARTESİ 4 OCAK 2027',
    );
  });

  test('card time labels', () {
    expect(KorFormat.when(DateTime(2026, 9, 13, 18, 5), now, AppL10n.turkish),
        '18:05');
    expect(KorFormat.when(DateTime(2026, 9, 12, 18), now, AppL10n.turkish),
        'Dün 18:00');
    expect(KorFormat.when(DateTime(2026, 9, 14, 9, 30), now, AppL10n.turkish),
        'Yarın 09:30');
    expect(KorFormat.when(DateTime(2026, 9, 20, 9), now, AppL10n.turkish),
        '20 Eyl 09:00');
    expect(KorFormat.headerDate(now, AppL10n.turkish), 'Pazar, 13 Eylül');
  });

  test('countdown and day diff across DST', () {
    expect(KorFormat.countdown(0, AppL10n.turkish), 'Bugün');
    expect(KorFormat.countdown(1, AppL10n.turkish), 'Yarın');
    expect(KorFormat.countdown(8, AppL10n.turkish), '8 gün');
    expect(
        KorFormat.dayDiff(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 30)), 2);
  });
}
