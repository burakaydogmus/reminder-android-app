package com.burakaydogmus.reminder

import android.appwidget.AppWidgetManager
import android.content.Context
import android.view.View
import android.widget.RemoteViews

/**
 * Sıradaki 2×2 (F5.1): "SIRADAKİ", büyük saat, 2 satır başlık, "+N daha" ve
 * yuvarlak "+". Gövdeye dokunma işi açar; iş yoksa "+" ile aynı (yeni).
 */
class ReminderNextWidgetProvider : ReminderWidgetProvider() {
  override fun build(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      snapshot: WidgetPayload.Snapshot,
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_next)
    val now = snapshot.now
    val label = context.getString(R.string.widget_next_label)
    WidgetViews.bindAdd(context, views, R.id.widget_add)
    WidgetViews.bindNotificationsStrip(
        context,
        views,
        R.id.widget_notifications_off,
        snapshot.notificationsEnabled,
    )

    val next = snapshot.next
    if (next == null) {
      val empty = context.getString(R.string.widget_empty_today)
      views.setTextViewText(R.id.widget_next_label, label)
      views.setViewVisibility(R.id.widget_next_time, View.GONE)
      views.setTextViewText(R.id.widget_next_title, empty)
      views.setViewVisibility(R.id.widget_next_more, View.INVISIBLE)
      views.setOnClickPendingIntent(
          R.id.widget_next_body,
          WidgetViews.launch(context, WidgetViews.newUri),
      )
      views.setContentDescription(R.id.widget_next_body, empty)
      return views
    }

    val due = next.dueAt
    val overdue = due != null && due < now
    // Bugün değilse gün etiketi üst satıra eklenir: "SIRADAKİ · YARIN".
    val day =
        when {
          due == null -> null
          overdue -> context.getString(R.string.widget_overdue)
          due >= WidgetPayload.startOfDay(now, 1) -> WidgetPayload.dayLabel(context, due, now)
          else -> null
        }
    views.setTextViewText(
        R.id.widget_next_label,
        if (day == null) label
        else "$label · ${day.uppercase(WidgetPayload.localeOf(context))}",
    )
    if (due == null) {
      views.setViewVisibility(R.id.widget_next_time, View.GONE)
    } else {
      views.setViewVisibility(R.id.widget_next_time, View.VISIBLE)
      views.setTextViewText(R.id.widget_next_time, WidgetPayload.clock(due))
      WidgetViews.setTextColorRes(
          context,
          views,
          R.id.widget_next_time,
          if (overdue) R.color.widget_primary else R.color.widget_on_surface,
      )
    }
    views.setTextViewText(R.id.widget_next_title, next.title)
    val more = snapshot.moreThanNext
    val moreText = if (more > 0) context.getString(R.string.widget_more, more) else null
    views.setViewVisibility(R.id.widget_next_more, if (moreText == null) View.INVISIBLE else View.VISIBLE)
    if (moreText != null) views.setTextViewText(R.id.widget_next_more, moreText)
    views.setOnClickPendingIntent(
        R.id.widget_next_body,
        WidgetViews.launch(context, WidgetViews.openUri(next.id)),
    )
    views.setContentDescription(
        R.id.widget_next_body,
        listOfNotNull(label, day, due?.let { WidgetPayload.clock(it) }, next.title, moreText)
            .joinToString(", "),
    )
    return views
  }
}
