package com.burakaydogmus.reminder

import android.appwidget.AppWidgetManager
import android.content.Context
import android.view.View
import android.widget.RemoteViews

/**
 * Bugün 4×2 (F5.1): "Bugün · N" + 56×40 hap "+", bugünün (gecikmiş + bugün +
 * zamansız) ilk iki işi; satır başına 48dp onay dairesi (arka planda tamamlar),
 * satıra dokunma işi açar.
 */
class ReminderTodayWidgetProvider : ReminderWidgetProvider() {
  override fun build(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      snapshot: WidgetPayload.Snapshot,
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_today)
    bindHeader(context, views, snapshot.todayOpen.size)
    WidgetViews.bindAdd(context, views, R.id.widget_add)
    WidgetViews.bindNotificationsStrip(
        context,
        views,
        R.id.widget_notifications_off,
        snapshot.notificationsEnabled,
    )

    val open = snapshot.todayOpen
    views.setViewVisibility(R.id.widget_empty, if (open.isEmpty()) View.VISIBLE else View.GONE)
    if (open.isEmpty()) {
      views.setOnClickPendingIntent(
          R.id.widget_empty,
          WidgetViews.launch(context, WidgetViews.newUri),
      )
    }
    for (i in ROWS.indices) {
      val item = open.getOrNull(i)
      if (item == null) {
        views.setViewVisibility(ROWS[i].row, View.GONE)
      } else {
        WidgetViews.bindRow(context, views, ROWS[i], item, snapshot.now)
      }
    }
    return views
  }

  companion object {
    private val ROWS =
        listOf(
            WidgetViews.RowIds(
                R.id.widget_row_0,
                R.id.widget_check_0,
                R.id.widget_title_0,
                R.id.widget_meta_0,
            ),
            WidgetViews.RowIds(
                R.id.widget_row_1,
                R.id.widget_check_1,
                R.id.widget_title_1,
                R.id.widget_meta_1,
            ),
        )

    /** "Bugün · N" başlığı (Bugün ve Liste); dokunma uygulamayı açar. */
    fun bindHeader(context: Context, views: RemoteViews, count: Int) {
      views.setTextViewText(
          R.id.widget_header,
          context.getString(R.string.widget_today_header, count),
      )
      views.setContentDescription(
          R.id.widget_header,
          context.getString(R.string.widget_cd_today, count),
      )
      views.setOnClickPendingIntent(R.id.widget_header, WidgetViews.launch(context, null))
    }
  }
}
