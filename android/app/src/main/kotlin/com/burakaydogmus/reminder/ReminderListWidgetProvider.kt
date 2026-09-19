package com.burakaydogmus.reminder

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews

/**
 * Liste 4×4, 3×3–5×6 arası boyutlanır (F5.1): kaydırılabilir Kaçanlar / Bugün /
 * Doğum günü / Sonra bölümleri.
 *
 * F5.1 öncesi tek widget'ın sınıfı (adı değişmez), böylece ana ekranda duran
 * widget'lar kendiliğinden Liste olur.
 *
 * Koleksiyon: API 31+ `RemoteViews.RemoteCollectionItems` (satırlar doğrudan
 * RemoteViews içinde, servis yok); API 26–30 [ReminderListWidgetService]
 * (`RemoteViewsService` + `RemoteViewsFactory`). Satırlar iki yolda da
 * [ListRows] ile çizilir. Koleksiyon öğeleri kendi PendingIntent'ini taşıyamaz;
 * tıklamalar tek şablon ([ReminderWidgetClickReceiver.template]) + satır başına
 * fill-in adresidir.
 */
class ReminderListWidgetProvider : ReminderWidgetProvider() {
  override fun build(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      snapshot: WidgetPayload.Snapshot,
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_list)
    ReminderTodayWidgetProvider.bindHeader(context, views, snapshot.todayOpen.size)
    WidgetViews.bindAdd(context, views, R.id.widget_add)
    WidgetViews.bindNotificationsStrip(
        context,
        views,
        R.id.widget_notifications_off,
        snapshot.notificationsEnabled,
    )

    if (Build.VERSION.SDK_INT >= 31) {
      val items =
          RemoteViews.RemoteCollectionItems.Builder()
              .setHasStableIds(true)
              .setViewTypeCount(ListRows.VIEW_TYPE_COUNT)
      for (row in ListRows.build(context, snapshot)) {
        items.addItem(row.id, row.views)
      }
      views.setRemoteAdapter(R.id.widget_list, items.build())
    } else {
      val intent =
          Intent(context, ReminderListWidgetService::class.java)
              .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
      // Farklı widget'lar farklı fabrika alsın diye (Intent eşitliği ekstraları saymaz).
      intent.data = Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME))
      @Suppress("DEPRECATION") views.setRemoteAdapter(R.id.widget_list, intent)
    }
    views.setEmptyView(R.id.widget_list, R.id.widget_empty)
    views.setOnClickPendingIntent(
        R.id.widget_empty,
        WidgetViews.launch(context, WidgetViews.newUri),
    )
    views.setPendingIntentTemplate(
        R.id.widget_list,
        ReminderWidgetClickReceiver.template(context),
    )
    return views
  }

  override fun afterUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetIds: IntArray,
  ) {
    if (Build.VERSION.SDK_INT < 31) {
      // Fabrika `onDataSetChanged` ile veriyi yeniden okur.
      @Suppress("DEPRECATION")
      appWidgetManager.notifyAppWidgetViewDataChanged(widgetIds, R.id.widget_list)
    }
  }
}
