package com.burakaydogmus.reminder

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Liste widget'ının satırları (F5.1); API 31+ `RemoteCollectionItems` ve API 26–30
 * `RemoteViewsFactory` aynı listeyi kullanır.
 *
 * Sıra: Kaçanlar (gecikmiş) · Bugün (bugün + zamansız) · Doğum günü (bugün/yarın)
 * · Sonra. Boş bölümün başlığı yazılmaz. Tıklamalar fill-in adresidir; şablon
 * [ReminderWidgetClickReceiver.template].
 */
object ListRows {
  /** Bölüm başlığı, hatırlatıcı ve doğum günü satırı. */
  const val VIEW_TYPE_COUNT = 3

  data class Row(val id: Long, val views: RemoteViews)

  private val ITEM =
      WidgetViews.RowIds(
          R.id.widget_item_row,
          R.id.widget_item_check,
          R.id.widget_item_title,
          R.id.widget_item_meta,
      )

  fun build(context: Context, snapshot: WidgetPayload.Snapshot): List<Row> {
    val rows = ArrayList<Row>()
    val used = HashSet<Long>()
    fun stableId(key: String): Long {
      var id = key.hashCode().toLong() and 0xffffffffL
      while (!used.add(id)) id++
      return id
    }

    fun section(title: Int, key: String) {
      val views = RemoteViews(context.packageName, R.layout.widget_list_section)
      views.setTextViewText(R.id.widget_section_title, context.getString(title))
      rows.add(Row(stableId("section:$key"), views))
    }

    fun items(list: List<WidgetPayload.Item>) {
      for (item in list) {
        val views = RemoteViews(context.packageName, R.layout.widget_list_item)
        WidgetViews.bindRowContent(context, views, ITEM, item, snapshot.now)
        views.setOnClickFillInIntent(ITEM.row, fillIn(WidgetViews.openUri(item.id)))
        views.setOnClickFillInIntent(ITEM.check, fillIn(WidgetViews.toggleUri(item.id)))
        rows.add(Row(stableId("item:${item.id}"), views))
      }
    }

    if (snapshot.overdue.isNotEmpty()) {
      section(R.string.widget_section_overdue, "overdue")
      items(snapshot.overdue)
    }
    val today = snapshot.today + snapshot.untimed
    if (today.isNotEmpty()) {
      section(R.string.widget_section_today, "today")
      items(today)
    }
    if (snapshot.birthdays.isNotEmpty()) {
      section(R.string.widget_section_birthdays, "birthdays")
      for ((birthday, isToday) in snapshot.birthdays) {
        val views = RemoteViews(context.packageName, R.layout.widget_list_birthday)
        views.setTextViewText(R.id.widget_birthday_name, birthday.name)
        val day =
            context.getString(if (isToday) R.string.widget_today else R.string.widget_tomorrow)
        val meta =
            if (birthday.age == null) day
            else context.getString(R.string.widget_birthday_age, day, birthday.age)
        views.setTextViewText(R.id.widget_birthday_meta, meta)
        views.setContentDescription(
            R.id.widget_birthday_row,
            context.getString(R.string.widget_cd_birthday, birthday.name, meta),
        )
        views.setOnClickFillInIntent(
            R.id.widget_birthday_row,
            fillIn(WidgetViews.birthdayUri(birthday.id)),
        )
        rows.add(Row(stableId("birthday:${birthday.id}"), views))
      }
    }
    if (snapshot.later.isNotEmpty()) {
      section(R.string.widget_section_later, "later")
      items(snapshot.later)
    }
    return rows
  }

  private fun fillIn(uri: android.net.Uri): Intent = Intent().setData(uri)
}
