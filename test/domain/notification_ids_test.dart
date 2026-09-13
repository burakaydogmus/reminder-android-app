import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/notification_ids.dart';

import '../helpers/factories.dart';

/// Tohumlu [Random] ile üretilen, biçimce geçerli v4 UUID (tekrarlanabilir).
String _uuidV4(Random random) {
  String hex(int n) =>
      List.generate(n, (_) => random.nextInt(16).toRadixString(16)).join();
  const variants = '89ab';
  return '${hex(8)}-${hex(4)}-4${hex(3)}-'
      '${variants[random.nextInt(4)]}${hex(3)}-${hex(12)}';
}

void main() {
  group('NotificationIds.fnv1a32', () {
    // Yayımlanmış FNV-1a 32-bit test vektörleri
    // (http://www.isthe.com/chongo/tech/comp/fnv/).
    test('matches published FNV-1a 32-bit vectors', () {
      expect(NotificationIds.fnv1a32(''), 0x811C9DC5);
      expect(NotificationIds.fnv1a32('a'), 0xE40C292C);
      expect(NotificationIds.fnv1a32('foobar'), 0xBF9CF968);
    });

    test('hashes UTF-8 bytes, not UTF-16 code units', () {
      // 'ş' (U+015F) UTF-8'de iki bayttır: 0xC5 0x9F.
      const prime = 0x01000193;
      var expected = 0x811C9DC5;
      for (final byte in const [0xC5, 0x9F]) {
        expected = ((expected ^ byte) * prime) & 0xFFFFFFFF;
      }
      expect(NotificationIds.fnv1a32('ş'), expected);
    });
  });

  group('NotificationIds', () {
    const uuidA = '6f1c2b1e-0000-4000-8000-000000000000';
    const uuidB = 'c7d1e9a0-1111-4222-8333-444455556666';

    // Bu değerler cihazda zamanlanmış bildirimlerin kimlikleridir. Bir
    // algoritma/anahtar değişikliği bu testi kırmalı; o durumda eski
    // kimlikli bildirimlerin temizlenmesi de planlanmalıdır.
    test('produces the hard-coded ids for sample UUIDs', () {
      expect(NotificationIds.reminderNotificationId(uuidA), 1064515057);
      expect(NotificationIds.geoNotificationId(uuidA), 1511400282);
      expect(NotificationIds.birthdayNotificationId(uuidA, 0), 798650370);
      expect(NotificationIds.birthdayNotificationId(uuidA, 1440), 1995185839);

      expect(NotificationIds.reminderNotificationId(uuidB), 1191819202);
      expect(NotificationIds.geoNotificationId(uuidB), 1121790765);
      expect(NotificationIds.birthdayNotificationId(uuidB, 0), 2097222621);
      expect(NotificationIds.birthdayNotificationId(uuidB, 1440), 497286126);
    });

    test('model getters delegate to the namespaced keys', () {
      final r = buildReminder(id: uuidA);
      final b = buildBirthday(id: uuidA);

      expect(r.notificationId, NotificationIds.fromKey('reminder:$uuidA'));
      expect(r.geoNotificationId, NotificationIds.fromKey('geo:$uuidA'));
      expect(
        b.notificationIdFor(60),
        NotificationIds.fromKey('birthday:$uuidA:60'),
      );
    });

    test('is stable for the same input', () {
      for (final id in [uuidA, uuidB, '', 'r1', 'Doğum günü ğüşiöç']) {
        expect(
          NotificationIds.reminderNotificationId(id),
          NotificationIds.reminderNotificationId(String.fromCharCodes(
            id.codeUnits,
          )),
        );
        expect(
          buildReminder(id: id).notificationId,
          buildReminder(id: id).notificationId,
        );
      }
    });

    test('ids are in 1..0x7FFFFFFF', () {
      final random = Random(1);
      final keys = [
        '',
        'reminder:',
        for (var i = 0; i < 2000; i++) 'reminder:${_uuidV4(random)}',
      ];
      for (final key in keys) {
        expect(
          NotificationIds.fromKey(key),
          inInclusiveRange(1, 0x7FFFFFFF),
          reason: key,
        );
      }
    });

    test('reminder, geo and birthday ids differ for the same uuid', () {
      for (final id in [uuidA, uuidB, 'r1']) {
        final ids = {
          NotificationIds.reminderNotificationId(id),
          NotificationIds.geoNotificationId(id),
          for (final p in BirthdayAdvanceOffset.presets)
            NotificationIds.birthdayNotificationId(id, p.minutes),
        };
        expect(ids.length, 2 + BirthdayAdvanceOffset.presets.length,
            reason: id);
      }
    });

    test('all preset birthday offsets give distinct ids', () {
      final random = Random(2);
      for (var i = 0; i < 500; i++) {
        final b = buildBirthday(id: _uuidV4(random));
        final ids = BirthdayAdvanceOffset.presets
            .map((p) => b.notificationIdFor(p.minutes))
            .toSet();
        expect(ids.length, BirthdayAdvanceOffset.presets.length, reason: b.id);
      }
    });

    // 20.000 UUID × 3 isim alanı = n = 60.000 anahtar, 31 bitlik uzayda
    // (m = 2^31). Doğum günü paradoksuna göre beklenen çakışan çift sayısı
    // n² / (2m) ≈ 3.6e9 / 4.29e9 ≈ 0.84'tür; yani iyi dağılan bir hash'te
    // bile 1–2 çakışma normaldir ve "tam sıfır" beklemek yanlış olur. Sayı
    // Poisson(0.84) gibi dağılır: P(X > 5) ≈ 2e-4. Tohum sabit olduğundan
    // sonuç deterministiktir (şu an 0); sınır 5, algoritmanın bozulmasını
    // (ör. isim alanını yok sayma → 20.000+ çakışma) yakalar. Gerçek bir
    // kullanıcının ~500 bildirim kimliği için herhangi bir çakışma olasılığı
    // 500² / 2^32 ≈ 6e-5 mertebesindedir.
    test('has (near) zero collisions over 20,000 UUIDs x 3 namespaces', () {
      const uuidCount = 20000;
      const maxCollisions = 5;
      final random = Random(20260913);
      final seen = <int>{};
      var collisions = 0;

      for (var i = 0; i < uuidCount; i++) {
        final id = _uuidV4(random);
        for (final n in [
          NotificationIds.reminderNotificationId(id),
          NotificationIds.geoNotificationId(id),
          NotificationIds.birthdayNotificationId(id, 0),
        ]) {
          if (!seen.add(n)) collisions++;
        }
      }

      // ignore: avoid_print
      print('notification id collisions: $collisions / ${uuidCount * 3}');
      expect(collisions, lessThanOrEqualTo(maxCollisions));
    });
  });
}
