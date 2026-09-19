package com.burakaydogmus.reminder

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews

/** Hızlı ekle 1×1 (F5.1): yalnız "+" hap → yeni hatırlatıcı (`reminderwidget://new`). */
class ReminderQuickAddWidgetProvider : ReminderWidgetProvider() {
  override fun build(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      snapshot: WidgetPayload.Snapshot,
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_quick_add)
    WidgetViews.bindAdd(context, views, R.id.widget_add)
    return views
  }
}
