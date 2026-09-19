package com.burakaydogmus.reminder

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * API 26–30 için Liste koleksiyonu (F5.1). API 31+ `RemoteCollectionItems`
 * kullanır ve bu servise hiç bağlanmaz.
 */
class ReminderListWidgetService : RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
      Factory(applicationContext)

  private class Factory(private val context: Context) : RemoteViewsFactory {
    private var rows: List<ListRows.Row> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
      val raw = WidgetPayload.read(HomeWidgetPlugin.getData(context))
      rows =
          ListRows.build(
              WidgetPayload.localized(context, raw.lang),
              WidgetPayload.snapshot(raw),
          )
    }

    override fun onDestroy() {
      rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews? = rows.getOrNull(position)?.views

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = ListRows.VIEW_TYPE_COUNT

    override fun getItemId(position: Int): Long = rows.getOrNull(position)?.id ?: position.toLong()

    override fun hasStableIds(): Boolean = true
  }
}
