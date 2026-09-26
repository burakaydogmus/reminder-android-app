import 'dart:math' as math;

/// Tekrar sıklığı (F3.1).
enum RecurrenceFrequency {
  /// Tekrar yok.
  none,

  /// Her [RecurrenceRule.interval] günde bir ("Her gün", "3 günde bir").
  daily,

  /// Her [RecurrenceRule.interval] haftada bir, seçili günlerde.
  weekly,

  /// Her [RecurrenceRule.interval] ayda bir, ayın belirli gününde.
  monthly,

  /// Her [RecurrenceRule.interval] yılda bir, yılın belirli ay/gününde
  /// ("Her yıl", "2 yılda bir").
  yearly,
}

/// Bir hatırlatıcının tekrar kuralı (saf Dart, değer tipi).
///
/// Kural yalnızca **tarihi** üretir; saat, dakika ve saniye her zaman
/// `anchor`'dan (hatırlatıcının `remindAt` değeri) alınır. Hesaplar yerel
/// `DateTime` alanlarıyla yapılır (`DateTime(y, m, d + n, h, min)`), `Duration`
/// eklenmez: yaz saati geçişinde 09:00 yine 09:00 kalır.
///
/// Aralıklı kurallar (`interval > 1`) `anchor`'dan sayılır: gün/hafta/ay/yıl
/// dizisi `anchor`'ın günü/haftası (Pazartesi başlangıçlı)/ayı/yılıyla başlar.
/// Tamamlanınca `remindAt` bir sonraki tekrara ilerlediği için yeni `anchor`
/// aynı dizinin üzerindedir; faz korunur.
class RecurrenceRule {
  const RecurrenceRule._({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.month,
    this.dayOfMonth,
    this.until,
  });

  /// Tekrar yok.
  static const none = RecurrenceRule._(frequency: RecurrenceFrequency.none);

  /// En büyük aralık (UI stepper sınırı, bozuk veride de kırpılır).
  static const maxInterval = 99;

  /// Her [interval] günde bir.
  factory RecurrenceRule.daily({int interval = 1, DateTime? until}) =>
      RecurrenceRule._(
        frequency: RecurrenceFrequency.daily,
        interval: _clampInterval(interval),
        until: _dateOnly(until),
      );

  /// Her [interval] haftada bir, [weekdays] günlerinde
  /// (`DateTime.monday` … `DateTime.sunday`). Boş küme `anchor`'ın günü
  /// demektir.
  factory RecurrenceRule.weekly(
    Iterable<int> weekdays, {
    int interval = 1,
    DateTime? until,
  }) {
    final days = {
      for (final d in weekdays)
        if (d >= DateTime.monday && d <= DateTime.sunday) d,
    }.toList()
      ..sort();
    return RecurrenceRule._(
      frequency: RecurrenceFrequency.weekly,
      interval: _clampInterval(interval),
      weekdays: List.unmodifiable(days),
      until: _dateOnly(until),
    );
  }

  /// Her [interval] ayda bir, ayın [dayOfMonth]. günü; kısa aylarda ayın son
  /// günü (31 → 30 / 28 / 29).
  factory RecurrenceRule.monthly({
    required int dayOfMonth,
    int interval = 1,
    DateTime? until,
  }) =>
      RecurrenceRule._(
        frequency: RecurrenceFrequency.monthly,
        interval: _clampInterval(interval),
        dayOfMonth: dayOfMonth.clamp(1, 31),
        until: _dateOnly(until),
      );

  /// Her [interval] yılda bir, [month] ayının [dayOfMonth]. günü. İkisi de
  /// `null` bırakılabilir: o zaman `anchor`'ın ayı/günü kullanılır (kural
  /// hatırlatıcının tarihini izler).
  ///
  /// Kısa aylarda gün ayın son gününe kırpılır — yani **29 Şubat'a kurulu
  /// yıllık kural artık yıl olmayan yıllarda 28 Şubat'ta** çalışır; doğum
  /// günlerinin kuralıyla (`Birthday.occurrenceInYear`) aynı davranış.
  factory RecurrenceRule.yearly({
    int interval = 1,
    int? month,
    int? dayOfMonth,
    DateTime? until,
  }) =>
      RecurrenceRule._(
        frequency: RecurrenceFrequency.yearly,
        interval: _clampInterval(interval),
        month: month?.clamp(1, 12),
        dayOfMonth: dayOfMonth?.clamp(1, 31),
        until: _dateOnly(until),
      );

  final RecurrenceFrequency frequency;

  /// Aralık (≥ 1): "2 haftada bir" için 2.
  final int interval;

  /// Haftalık kuralın günleri, sıralı (Pazartesi = 1). Diğer sıklıklarda boş.
  final List<int> weekdays;

  /// Yıllık kuralın ayı (1–12); `null` ise `anchor`'ın ayı. Yalnızca
  /// [RecurrenceFrequency.yearly] kullanır.
  final int? month;

  /// Aylık kuralın günü (1–31; her zaman dolu) ya da yıllık kuralın ayın
  /// günü (`null` ise `anchor`'ın günü). Diğer sıklıklarda `null`.
  final int? dayOfMonth;

  /// Son tekrar günü (dahil, yalnızca tarih). `null`: bitiş yok.
  final DateTime? until;

  bool get isNone => frequency == RecurrenceFrequency.none;

  RecurrenceRule withUntil(DateTime? value) => isNone
      ? this
      : RecurrenceRule._(
          frequency: frequency,
          interval: interval,
          weekdays: weekdays,
          month: month,
          dayOfMonth: dayOfMonth,
          until: _dateOnly(value),
        );

  /// Serinin tarihi [date]'e taşınınca ("tüm seri") kuralı yeni güne uyarlar:
  /// tek günlük haftalık kural o güne geçer, çok günlüye gün eklenir; aylık
  /// kural ayın yeni gününü alır (ay sonu kırpılmış gün aynı kalır); yıllık
  /// kuralın açık ay/günü yeni tarihe geçer (kırpılmış gün — 29 Şubat kuralı
  /// 28 Şubat'a taşınırsa — aynı kalır), ay/günü `anchor`'dan alan kural
  /// zaten yeni tarihi izler. Diğer kurallar değişmez. Aralık ve bitiş
  /// korunur.
  RecurrenceRule alignedTo(DateTime date) {
    switch (frequency) {
      case RecurrenceFrequency.weekly:
        if (weekdays.contains(date.weekday)) return this;
        return RecurrenceRule.weekly(
          weekdays.length <= 1 ? [date.weekday] : [...weekdays, date.weekday],
          interval: interval,
          until: until,
        );
      case RecurrenceFrequency.monthly:
        final dom = dayOfMonth ?? date.day;
        if (math.min(dom, daysInMonth(date.year, date.month)) == date.day) {
          return this;
        }
        return RecurrenceRule.monthly(
          dayOfMonth: date.day,
          interval: interval,
          until: until,
        );
      case RecurrenceFrequency.yearly:
        final m = month ?? date.month;
        final dom = dayOfMonth ?? date.day;
        if (m == date.month &&
            math.min(dom, daysInMonth(date.year, m)) == date.day) {
          return this;
        }
        return RecurrenceRule.yearly(
          interval: interval,
          month: date.month,
          dayOfMonth: date.day,
          until: until,
        );
      case RecurrenceFrequency.none:
      case RecurrenceFrequency.daily:
        return this;
    }
  }

  /// [after]'dan **kesin sonraki** ilk tekrar; saat [anchor]'dan. [anchor]
  /// dizinin başlangıcıdır ve kurala uyuyorsa kendisi de bir tekrardır;
  /// [anchor]'dan önceki günler hiçbir zaman döndürülmez. Tekrar yoksa veya
  /// [until] geçildiyse `null`.
  DateTime? nextOccurrence(
      {required DateTime after, required DateTime anchor}) {
    final candidate = switch (frequency) {
      RecurrenceFrequency.none => null,
      RecurrenceFrequency.daily => _nextDaily(after, anchor),
      RecurrenceFrequency.weekly => _nextWeekly(after, anchor),
      RecurrenceFrequency.monthly => _nextMonthly(after, anchor),
      RecurrenceFrequency.yearly => _nextYearly(after, anchor),
    };
    if (candidate == null) return null;
    final end = until;
    if (end != null &&
        _epochDay(candidate.year, candidate.month, candidate.day) >
            _epochDay(end.year, end.month, end.day)) {
      return null;
    }
    return candidate;
  }

  /// [from] anına eşit ya da sonraki ilk tekrar.
  DateTime? firstOnOrAfter(
          {required DateTime from, required DateTime anchor}) =>
      nextOccurrence(
        after: from.subtract(const Duration(microseconds: 1)),
        anchor: anchor,
      );

  /// [from]'dan itibaren (dahil) en fazla [count] tekrar.
  List<DateTime> upcoming({
    required DateTime from,
    required DateTime anchor,
    int count = 3,
  }) {
    final result = <DateTime>[];
    var next = firstOnOrAfter(from: from, anchor: anchor);
    while (next != null && result.length < count) {
      result.add(next);
      next = nextOccurrence(after: next, anchor: anchor);
    }
    return result;
  }

  DateTime _nextDaily(DateTime after, DateTime anchor) {
    final start = _epochDay(anchor.year, anchor.month, anchor.day);
    final target = _epochDay(after.year, after.month, after.day);
    var k = math.max(0, (target - start) ~/ interval - 1);
    while (true) {
      final c = _atEpochDay(anchor, start + k * interval);
      if (c.isAfter(after)) return c;
      k++;
    }
  }

  DateTime _nextWeekly(DateTime after, DateTime anchor) {
    final days = weekdays.isEmpty ? [anchor.weekday] : weekdays;
    final anchorDay = _epochDay(anchor.year, anchor.month, anchor.day);
    final weekStart = anchorDay - (anchor.weekday - DateTime.monday);
    final target = _epochDay(after.year, after.month, after.day);
    final span = 7 * interval;
    var block = math.max(0, (target - weekStart) ~/ span - 1);
    while (true) {
      final start = weekStart + block * span;
      for (final wd in days) {
        final day = start + wd - DateTime.monday;
        if (day < anchorDay) continue;
        final c = _atEpochDay(anchor, day);
        if (c.isAfter(after)) return c;
      }
      block++;
    }
  }

  DateTime _nextMonthly(DateTime after, DateTime anchor) {
    final dom = dayOfMonth ?? anchor.day;
    final anchorDay = _epochDay(anchor.year, anchor.month, anchor.day);
    final start = anchor.year * 12 + anchor.month - 1;
    final target = after.year * 12 + after.month - 1;
    var k = math.max(0, (target - start) ~/ interval - 1);
    while (true) {
      final index = start + k * interval;
      final year = index ~/ 12;
      final month = index % 12 + 1;
      final day = math.min(dom, daysInMonth(year, month));
      k++;
      if (_epochDay(year, month, day) < anchorDay) continue;
      final c = _at(anchor, year, month, day);
      if (c.isAfter(after)) return c;
    }
  }

  DateTime _nextYearly(DateTime after, DateTime anchor) {
    final m = month ?? anchor.month;
    final dom = dayOfMonth ?? anchor.day;
    final anchorDay = _epochDay(anchor.year, anchor.month, anchor.day);
    final start = anchor.year;
    var k = math.max(0, (after.year - start) ~/ interval - 1);
    while (true) {
      final year = start + k * interval;
      // Kısa ayda ayın son günü: 29 Şubat kuralı artık yıl olmayan yılda
      // 28 Şubat'ta çalışır (doğum günleriyle aynı davranış).
      final day = math.min(dom, daysInMonth(year, m));
      k++;
      if (_epochDay(year, m, day) < anchorDay) continue;
      final c = _at(anchor, year, m, day);
      if (c.isAfter(after)) return c;
    }
  }

  /// Yıllık kuralın hedef ay/günü, `null` alanları [anchor]'dan tamamlanmış
  /// hali; kural yıllık değilse `null`.
  ({int month, int day})? yearlyTarget(DateTime anchor) =>
      frequency == RecurrenceFrequency.yearly
          ? (month: month ?? anchor.month, day: dayOfMonth ?? anchor.day)
          : null;

  /// [year]/[month] ayındaki gün sayısı (artık yıl dahil).
  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static int _clampInterval(int value) => value.clamp(1, maxInterval);

  static DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  /// Takvim gününün UTC epoch gün numarası (yaz saatinden bağımsız).
  static int _epochDay(int year, int month, int day) =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static DateTime _atEpochDay(DateTime anchor, int epochDay) {
    final d = DateTime.utc(1970, 1, 1 + epochDay);
    return _at(anchor, d.year, d.month, d.day);
  }

  /// [anchor]'ın duvar saatiyle verilen gün.
  static DateTime _at(
          DateTime anchor, int year, int month, int day) =>
      anchor.isUtc
          ? DateTime.utc(year, month, day, anchor.hour, anchor.minute,
              anchor.second, anchor.millisecond, anchor.microsecond)
          : DateTime(year, month, day, anchor.hour, anchor.minute,
              anchor.second, anchor.millisecond, anchor.microsecond);

  // Display texts (summary, weekday and day-of-month labels) live in the UI
  // layer: `ui/common/recurrence_text.dart` (localized, F6.1).

  // ---------------------------------------------------------------------------
  // JSON

  /// `null` → tekrar yok (eski kayıtlar).
  Map<String, dynamic>? toJson() {
    if (isNone) return null;
    final end = until;
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (frequency == RecurrenceFrequency.weekly) 'weekdays': weekdays,
      if (frequency == RecurrenceFrequency.monthly) 'dayOfMonth': dayOfMonth,
      if (frequency == RecurrenceFrequency.yearly && month != null)
        'month': month,
      if (frequency == RecurrenceFrequency.yearly && dayOfMonth != null)
        'dayOfMonth': dayOfMonth,
      if (end != null)
        'until': '${end.year.toString().padLeft(4, '0')}-'
            '${end.month.toString().padLeft(2, '0')}-'
            '${end.day.toString().padLeft(2, '0')}',
    };
  }

  /// Toleranslı çözüm: `null`, bilinmeyen sıklık veya bozuk değer → [none].
  ///
  /// **Geriye dönük uyumluluk:** bu tolerans bilerek böyle; `yearly`
  /// bilmeyen **eski bir sürüm** (ya da eski bir yedek okuyucusu) yıllık
  /// kuralı [none] olarak okur — hatırlatıcı korunur, yalnızca tekrarını
  /// kaybeder.
  static RecurrenceRule fromJson(Object? json) {
    if (json is! Map) return none;
    try {
      final interval = (json['interval'] as num?)?.toInt() ?? 1;
      final untilRaw = json['until'];
      final until = untilRaw is String ? DateTime.tryParse(untilRaw) : null;
      switch (json['frequency']) {
        case 'daily':
          return RecurrenceRule.daily(interval: interval, until: until);
        case 'weekly':
          final days = (json['weekdays'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              const <int>[];
          return RecurrenceRule.weekly(days, interval: interval, until: until);
        case 'monthly':
          final dom = (json['dayOfMonth'] as num?)?.toInt();
          if (dom == null) return none;
          return RecurrenceRule.monthly(
            dayOfMonth: dom,
            interval: interval,
            until: until,
          );
        case 'yearly':
          return RecurrenceRule.yearly(
            interval: interval,
            month: (json['month'] as num?)?.toInt(),
            dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
            until: until,
          );
      }
    } catch (_) {
      // Bozuk kural: tekrar yok say.
    }
    return none;
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.frequency == frequency &&
      other.interval == interval &&
      _listEquals(other.weekdays, weekdays) &&
      other.month == month &&
      other.dayOfMonth == dayOfMonth &&
      other.until == until;

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        Object.hashAll(weekdays),
        month,
        dayOfMonth,
        until,
      );

  @override
  String toString() => 'RecurrenceRule(${toJson()})';

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
