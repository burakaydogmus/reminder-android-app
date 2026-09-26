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

/// Tekrarın neye göre sayıldığı (F3.1c).
enum RecurrenceAnchor {
  /// **Takvime göre:** seri sabit tarihlerden oluşur. Geç tamamlamak sıradaki
  /// tekrarı kaydırmaz, kaçırılan tekrarlar atlanır. F3.1 / F3.1b davranışı,
  /// varsayılan.
  schedule,

  /// **Tamamlandıktan sonra:** sıradaki tekrar hatırlatıcının *tamamlandığı*
  /// günden sayılır ("çarşafları yıkadıktan 14 gün sonra"). Tamamlanmadıkça
  /// hatırlatıcı yerinde kalır ve gecikir — asıl amaç bu.
  ///
  /// Bu modda takvim alanları ([RecurrenceRule.weekdays],
  /// [RecurrenceRule.dayOfMonth], [RecurrenceRule.month]) anlamsızdır ve kural
  /// kurulurken **bilerek düşürülür**: sıradaki tarih ayın gününden değil
  /// tamamlama gününden gelir.
  completion,
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
///
/// İki **ölçüt** ([anchorMode], F3.1c) var: takvime göre (yukarısı) ve
/// tamamlandıktan sonra. İkincisinde takvimde bilinen bir gelecek tarih
/// **yoktur** — bu yüzden [nextOccurrence] (ve dolayısıyla [firstOnOrAfter],
/// [upcoming]) `null` döner; sıradaki tarih yalnızca [nextAfterCompletion] ile,
/// tamamlama anı belli olduğunda hesaplanır.
class RecurrenceRule {
  const RecurrenceRule._({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.month,
    this.dayOfMonth,
    this.until,
    this.anchorMode = RecurrenceAnchor.schedule,
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

  /// Tamamlandıktan [interval] gün/hafta/ay/yıl sonra tekrarlayan kural
  /// (F3.1c): "tamamlandıktan 14 gün sonra".
  ///
  /// Takvim alanları (haftanın günleri, ayın günü, yıllık ay/gün) bu modda
  /// anlamsız olduğu için **hiç alınmaz**: sıradaki tarih yalnızca tamamlama
  /// gününden ve [interval]'dan gelir. [RecurrenceFrequency.none] verilirse
  /// [none] döner (mod tek başına bir tekrar değildir).
  factory RecurrenceRule.afterCompletion(
    RecurrenceFrequency frequency, {
    int interval = 1,
    DateTime? until,
  }) {
    if (frequency == RecurrenceFrequency.none) return none;
    return RecurrenceRule._(
      frequency: frequency,
      interval: _clampInterval(interval),
      until: _dateOnly(until),
      anchorMode: RecurrenceAnchor.completion,
    );
  }

  final RecurrenceFrequency frequency;

  /// Tekrarın ölçütü (F3.1c): takvim ya da tamamlama. [none] her zaman
  /// [RecurrenceAnchor.schedule].
  final RecurrenceAnchor anchorMode;

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

  /// Tekrar tamamlama tarihine göre mi sayılıyor (F3.1c)?
  bool get isCompletionAnchored =>
      anchorMode == RecurrenceAnchor.completion && !isNone;

  RecurrenceRule withUntil(DateTime? value) => isNone
      ? this
      : RecurrenceRule._(
          frequency: frequency,
          interval: interval,
          weekdays: weekdays,
          month: month,
          dayOfMonth: dayOfMonth,
          until: _dateOnly(value),
          anchorMode: anchorMode,
        );

  /// Serinin tarihi [date]'e taşınınca ("tüm seri") kuralı yeni güne uyarlar:
  /// tek günlük haftalık kural o güne geçer, çok günlüye gün eklenir; aylık
  /// kural ayın yeni gününü alır (ay sonu kırpılmış gün aynı kalır); yıllık
  /// kuralın açık ay/günü yeni tarihe geçer (kırpılmış gün — 29 Şubat kuralı
  /// 28 Şubat'a taşınırsa — aynı kalır), ay/günü `anchor`'dan alan kural
  /// zaten yeni tarihi izler. Diğer kurallar değişmez. Aralık ve bitiş
  /// korunur. Ölçüt ([anchorMode]) hiçbir zaman değişmez; tamamlamaya bağlı
  /// kuralın hizalanacak takvim alanı olmadığı için kural aynen döner.
  RecurrenceRule alignedTo(DateTime date) {
    if (isCompletionAnchored) return this;
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
  ///
  /// **Tamamlamaya bağlı kural (F3.1c) her zaman `null` döner:** takvimde
  /// bilinen bir sonraki tarih yoktur, tarih ancak tamamlanınca doğar
  /// ([nextAfterCompletion]). Bu sayede geçmiş kalan böyle bir hatırlatıcı
  /// tekrarsız biri gibi yerinde kalıp gecikir (bildirim yeniden kurulmaz,
  /// takvim de seriyi ileriye yansıtmaz).
  DateTime? nextOccurrence(
      {required DateTime after, required DateTime anchor}) {
    if (isCompletionAnchored) return null;
    final candidate = switch (frequency) {
      RecurrenceFrequency.none => null,
      RecurrenceFrequency.daily => _nextDaily(after, anchor),
      RecurrenceFrequency.weekly => _nextWeekly(after, anchor),
      RecurrenceFrequency.monthly => _nextMonthly(after, anchor),
      RecurrenceFrequency.yearly => _nextYearly(after, anchor),
    };
    return _withinUntil(candidate);
  }

  /// Tamamlamaya bağlı kuralın ([RecurrenceAnchor.completion]) sıradaki
  /// tekrarı: **[completedAt]'in günü + [interval]**, saat/dakika [anchor]'dan
  /// (hatırlatıcının kendi saati, tamamlama anı değil). 10:00'a kurulu, 14
  /// günlük bir hatırlatıcı ayın 3'ünde 23:40'ta tamamlanırsa sıradaki tekrar
  /// 17'si 10:00 olur.
  ///
  /// Hesap yine takvim alanlarıyla yapılır (`DateTime(y, m, d + n, h, min)`),
  /// `Duration` eklenmez: yaz saati geçişinde saat kaymaz. Ay ve yıl
  /// aralıklarında gün ayın son gününe kırpılır (31 Ocak + 1 ay → 28/29 Şubat).
  ///
  /// Takvime bağlı kurallarda ve [none]'da `null`; [until] geçildiyse de `null`
  /// (seri bitti, hatırlatıcı tamamlanmış sayılır).
  DateTime? nextAfterCompletion({
    required DateTime completedAt,
    required DateTime anchor,
  }) {
    if (!isCompletionAnchored) return null;
    final year = completedAt.year;
    final month = completedAt.month;
    final day = completedAt.day;
    final candidate = switch (frequency) {
      RecurrenceFrequency.none => null,
      RecurrenceFrequency.daily => _at(anchor, year, month, day + interval),
      RecurrenceFrequency.weekly =>
        _at(anchor, year, month, day + 7 * interval),
      RecurrenceFrequency.monthly => _monthsAfter(anchor, year, month, day),
      RecurrenceFrequency.yearly => _yearsAfter(anchor, year, month, day),
    };
    return _withinUntil(candidate);
  }

  /// [interval] ay sonrası, gün ayın son gününe kırpılmış.
  DateTime _monthsAfter(DateTime anchor, int year, int month, int day) {
    final index = year * 12 + month - 1 + interval;
    final y = index ~/ 12;
    final m = index % 12 + 1;
    return _at(anchor, y, m, math.min(day, daysInMonth(y, m)));
  }

  /// [interval] yıl sonrası, gün ayın son gününe kırpılmış (29 Şubat → 28
  /// Şubat, yıllık takvim kuralıyla aynı davranış).
  DateTime _yearsAfter(DateTime anchor, int year, int month, int day) {
    final y = year + interval;
    return _at(anchor, y, month, math.min(day, daysInMonth(y, month)));
  }

  /// [candidate] bitişi ([until], dahil) geçtiyse `null`.
  DateTime? _withinUntil(DateTime? candidate) {
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
  /// hali; kural yıllık değilse `null`. Tamamlamaya bağlı yıllık kuralın sabit
  /// bir ay/günü **yoktur** (tarih tamamlamadan gelir), o da `null` döner.
  ({int month, int day})? yearlyTarget(DateTime anchor) =>
      frequency == RecurrenceFrequency.yearly && !isCompletionAnchored
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
  ///
  /// Ölçüt **ek bir alan** olarak yazılır (`anchor: 'completion'`) ve yalnızca
  /// tamamlamaya bağlı kurallarda görünür: takvime bağlı kuralların JSON'u
  /// F3.1b'dekiyle bit bit aynı kalır (bildirim parmak izi değişmez).
  Map<String, dynamic>? toJson() {
    if (isNone) return null;
    final end = until;
    final calendar = !isCompletionAnchored;
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (isCompletionAnchored) 'anchor': anchorMode.name,
      if (calendar && frequency == RecurrenceFrequency.weekly)
        'weekdays': weekdays,
      if (calendar && frequency == RecurrenceFrequency.monthly)
        'dayOfMonth': dayOfMonth,
      if (calendar && frequency == RecurrenceFrequency.yearly && month != null)
        'month': month,
      if (calendar &&
          frequency == RecurrenceFrequency.yearly &&
          dayOfMonth != null)
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
  /// kaybeder. Ölçüt ek bir alan olduğu için (`anchor`) eski sürüm onu
  /// **yok sayar**: tekrar çalışmaya devam eder, ama takvime göre — artık
  /// tamamlama tarihini takip etmez.
  ///
  /// `anchor: 'completion'` okunurken takvim alanları (`weekdays`,
  /// `dayOfMonth`, `month`) **bilerek düşürülür**: o modda anlamları yok.
  static RecurrenceRule fromJson(Object? json) {
    if (json is! Map) return none;
    try {
      final interval = (json['interval'] as num?)?.toInt() ?? 1;
      final untilRaw = json['until'];
      final until = untilRaw is String ? DateTime.tryParse(untilRaw) : null;
      if (json['anchor'] == RecurrenceAnchor.completion.name) {
        final frequency = switch (json['frequency']) {
          'daily' => RecurrenceFrequency.daily,
          'weekly' => RecurrenceFrequency.weekly,
          'monthly' => RecurrenceFrequency.monthly,
          'yearly' => RecurrenceFrequency.yearly,
          _ => RecurrenceFrequency.none,
        };
        return RecurrenceRule.afterCompletion(
          frequency,
          interval: interval,
          until: until,
        );
      }
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
      other.anchorMode == anchorMode &&
      other.interval == interval &&
      _listEquals(other.weekdays, weekdays) &&
      other.month == month &&
      other.dayOfMonth == dayOfMonth &&
      other.until == until;

  @override
  int get hashCode => Object.hash(
        frequency,
        anchorMode,
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
