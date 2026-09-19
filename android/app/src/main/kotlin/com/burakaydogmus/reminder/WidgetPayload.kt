package com.burakaydogmus.reminder

import android.content.SharedPreferences
import java.util.Calendar
import org.json.JSONObject

/**
 * Ana ekran widget'larının veri sözleşmesi (F5.1), Dart tarafı
 * `lib/home/widget_payload.dart` (`WidgetPayload.build`) ile ortak.
 *
 * Dart eşitleme anında yazar; widget'lar saatlerce uygulama açılmadan yaşadığı
 * için zamana bağlı her şey (bölüm, "Gecikti", "Yarın", sayılar, sıradaki,
 * doğum günü etiketi) burada çizim anında `dueAt` / `date` ile yeniden
 * hesaplanır. Okunamayan veri boş duruma düşer, widget çökmez.
 */
object WidgetPayload {
  /** `kHomeWidgetPayloadKey` (Dart). */
  const val KEY = "widget_payload_v2"

  const val SECTION_OVERDUE = "overdue"
  const val SECTION_TODAY = "today"
  const val SECTION_UNTIMED = "untimed"
  const val SECTION_LATER = "later"

  private val MONTHS =
      arrayOf("Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara")

  data class Item(
      val id: String,
      val title: String,
      /** Epoch ms; `null` = zamansız. */
      val dueAt: Long?,
      /** Kor renk anahtarı (`market`, `ev`, `is`, …). */
      val category: String,
      /** "2/6" veya `null`. */
      val subtasks: String?,
      val recurring: Boolean,
      /** Dart'taki sıra (bölüm içi `compareReminders`). */
      val order: Int,
  )

  data class BirthdayItem(val id: String, val name: String, val date: Long, val age: Int?)

  data class Raw(
      val notificationsEnabled: Boolean,
      val items: List<Item>,
      val birthdays: List<BirthdayItem>,
  )

  /** Çizim anındaki görünüm. */
  data class Snapshot(
      val notificationsEnabled: Boolean,
      val overdue: List<Item>,
      val today: List<Item>,
      val untimed: List<Item>,
      val later: List<Item>,
      /** Bugün ve yarın olan doğum günleri (yakın olan önce). */
      val birthdays: List<Pair<BirthdayItem, Boolean>>,
      val now: Long,
  ) {
    /** Bugünün açık işleri: gecikmiş + bugün + zamansız (Bugün ekranı sırası). */
    val todayOpen: List<Item>
      get() = overdue + today + untimed

    /** Sıradaki: bugünün ilk zamanlı işi → sonraki günler → en eski gecikmiş → zamansız. */
    val next: Item?
      get() =
          today.firstOrNull()
              ?: later.firstOrNull()
              ?: overdue.firstOrNull()
              ?: untimed.firstOrNull()

    /** "+N daha": bugünün sıradaki dışındaki açık işleri. */
    val moreThanNext: Int
      get() {
        val next = next ?: return 0
        val open = todayOpen.size
        return if (later.contains(next)) open else open - 1
      }

    val isEmpty: Boolean
      get() = overdue.isEmpty() && today.isEmpty() && untimed.isEmpty() && later.isEmpty()
  }

  fun read(prefs: SharedPreferences): Raw = parse(prefs.getString(KEY, null))

  fun parse(json: String?): Raw {
    if (json.isNullOrEmpty()) return Raw(true, emptyList(), emptyList())
    return try {
      val root = JSONObject(json)
      val items = ArrayList<Item>()
      val arr = root.optJSONArray("items")
      if (arr != null) {
        for (i in 0 until arr.length()) {
          val o = arr.optJSONObject(i) ?: continue
          val id = o.optString("id", "")
          if (id.isEmpty()) continue
          items.add(
              Item(
                  id = id,
                  title = o.optString("title", "").ifEmpty { "…" },
                  dueAt = if (o.isNull("dueAt")) null else o.optLong("dueAt"),
                  category = o.optString("category", "diger"),
                  subtasks = if (o.isNull("subtasks")) null else o.optString("subtasks"),
                  recurring = o.optBoolean("recurring", false),
                  order = i,
              ))
        }
      }
      val birthdays = ArrayList<BirthdayItem>()
      val bArr = root.optJSONArray("birthdays")
      if (bArr != null) {
        for (i in 0 until bArr.length()) {
          val o = bArr.optJSONObject(i) ?: continue
          birthdays.add(
              BirthdayItem(
                  id = o.optString("id", ""),
                  name = o.optString("name", ""),
                  date = o.optLong("date"),
                  age = if (o.isNull("age") || !o.has("age")) null else o.optInt("age"),
              ))
        }
      }
      Raw(root.optBoolean("notificationsEnabled", true), items, birthdays)
    } catch (_: Exception) {
      Raw(true, emptyList(), emptyList())
    }
  }

  /** [raw]'ı [now] anına göre bölümlere ayırır (Dart `WidgetPayload.build` kuralı). */
  fun snapshot(raw: Raw, now: Long = System.currentTimeMillis()): Snapshot {
    val overdue = ArrayList<Item>()
    val today = ArrayList<Item>()
    val untimed = ArrayList<Item>()
    val later = ArrayList<Item>()
    val todayStart = startOfDay(now, 0)
    val tomorrowStart = startOfDay(now, 1)
    for (item in raw.items) {
      val at = item.dueAt
      when {
        at == null -> untimed.add(item)
        at < now -> overdue.add(item)
        at < tomorrowStart -> today.add(item)
        else -> later.add(item)
      }
    }
    // Dart sırası (bölüm sırası, bölüm içinde `compareReminders`) korunur:
    // bugünden gecikmişe geçen öğeler zaten gecikmişlerden sonra ve saat
    // sırasındadır.
    val birthdays =
        raw.birthdays
            .mapNotNull { b ->
              when {
                b.date in todayStart until tomorrowStart -> b to true
                b.date >= tomorrowStart && b.date < startOfDay(now, 2) -> b to false
                else -> null
              }
            }
            .sortedWith(compareBy({ !it.second }, { it.first.name }))
    return Snapshot(raw.notificationsEnabled, overdue, today, untimed, later, birthdays, now)
  }

  /** Bir sonraki görünüm değişimi: ilk gelecek `dueAt` veya gece yarısı. */
  fun nextChangeAt(raw: Raw, now: Long = System.currentTimeMillis()): Long {
    val midnight = startOfDay(now, 1)
    val nextDue = raw.items.mapNotNull { it.dueAt }.filter { it > now }.minOrNull()
    return if (nextDue != null && nextDue < midnight) nextDue else midnight
  }

  /** Satırdaki zaman etiketi: "Gecikti" / "16:00" / "Yarın" / "12 Eki"; zamansız → null. */
  fun timeLabel(dueAt: Long?, now: Long): String? {
    if (dueAt == null) return null
    if (dueAt < now) return "Gecikti"
    if (dueAt < startOfDay(now, 1)) return clock(dueAt)
    return dayLabel(dueAt, now)
  }

  /** "Bugün" / "Yarın" / "12 Eki" (yıl farklıysa "12 Oca 2027"). */
  fun dayLabel(at: Long, now: Long): String {
    if (at >= startOfDay(now, 0) && at < startOfDay(now, 1)) return "Bugün"
    if (at >= startOfDay(now, 1) && at < startOfDay(now, 2)) return "Yarın"
    val c = Calendar.getInstance().apply { timeInMillis = at }
    val n = Calendar.getInstance().apply { timeInMillis = now }
    val base = "${c.get(Calendar.DAY_OF_MONTH)} ${MONTHS[c.get(Calendar.MONTH)]}"
    return if (c.get(Calendar.YEAR) == n.get(Calendar.YEAR)) base
    else "$base ${c.get(Calendar.YEAR)}"
  }

  /** "09:05". */
  fun clock(at: Long): String {
    val c = Calendar.getInstance().apply { timeInMillis = at }
    return String.format(
        java.util.Locale.ROOT,
        "%02d:%02d",
        c.get(Calendar.HOUR_OF_DAY),
        c.get(Calendar.MINUTE),
    )
  }

  /** [now]'un gününden [plusDays] gün sonraki gece yarısı (yerel saat). */
  fun startOfDay(now: Long, plusDays: Int): Long {
    val c = Calendar.getInstance()
    c.timeInMillis = now
    c.set(Calendar.HOUR_OF_DAY, 0)
    c.set(Calendar.MINUTE, 0)
    c.set(Calendar.SECOND, 0)
    c.set(Calendar.MILLISECOND, 0)
    c.add(Calendar.DAY_OF_MONTH, plusDays)
    return c.timeInMillis
  }
}
