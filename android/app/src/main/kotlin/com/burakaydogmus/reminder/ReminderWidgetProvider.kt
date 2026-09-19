package com.burakaydogmus.reminder

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Dört widget sağlayıcısının ortak tabanı (F5.1): veriyi okur, çizim anına göre
 * bölümler ([WidgetPayload.snapshot]), her örneği [build] ile çizer ve saate bağlı
 * yenilemeyi ([ReminderWidgetRefreshReceiver.schedule]) kurar.
 */
abstract class ReminderWidgetProvider : HomeWidgetProvider() {

  abstract fun build(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      snapshot: WidgetPayload.Snapshot,
  ): RemoteViews

  /** Liste'nin koleksiyonu gibi `updateAppWidget` sonrası işler. */
  open fun afterUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetIds: IntArray,
  ) {}

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val raw = WidgetPayload.read(widgetData)
    val snapshot = WidgetPayload.snapshot(raw)
    // F6.1: strings in the app's language (payload "lang").
    val localized = WidgetPayload.localized(context, raw.lang)
    for (widgetId in appWidgetIds) {
      appWidgetManager.updateAppWidget(
          widgetId,
          build(localized, appWidgetManager, widgetId, snapshot),
      )
    }
    afterUpdate(context, appWidgetManager, appWidgetIds)
    ReminderWidgetRefreshReceiver.schedule(context)
  }
}
