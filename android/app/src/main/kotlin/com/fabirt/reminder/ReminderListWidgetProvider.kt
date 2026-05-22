package com.fabirt.reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class ReminderListWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.reminder_widget_layout)

      // Kök layout'a tıklama bağlamayın: çocuk satırların PendingIntent'lerini yutar.
      val openApp =
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, null)
      views.setOnClickPendingIntent(R.id.widget_header, openApp)

      val json = widgetData.getString("reminders_active_json", null) ?: "[]"

      val rows = parseRows(json)

      if (rows.isEmpty()) {
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        for (i in rowIds.indices) {
          views.setViewVisibility(rowIds[i], View.GONE)
        }
      } else {
        views.setViewVisibility(R.id.widget_empty, View.GONE)
        for (i in rowIds.indices) {
          if (i < rows.size) {
            val row = rows[i]
            views.setViewVisibility(rowIds[i], View.VISIBLE)
            views.setTextViewText(textIds[i], row.title)
            val toggle = toggleIntent(context, row.id)
            // Satır + kutu + metin: dokunma alanı geniş ve kök ile çakışmaz.
            views.setOnClickPendingIntent(rowIds[i], toggle)
            views.setOnClickPendingIntent(checkIds[i], toggle)
            views.setOnClickPendingIntent(textIds[i], toggle)
          } else {
            views.setViewVisibility(rowIds[i], View.GONE)
          }
        }
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private data class Row(val id: String, val title: String)

  private fun parseRows(json: String): List<Row> {
    return try {
      val arr = JSONArray(json)
      val out = ArrayList<Row>(arr.length())
      for (i in 0 until arr.length()) {
        val o = arr.getJSONObject(i)
        val id = o.getString("id")
        val title = o.optString("title", "").ifEmpty { "…" }
        out.add(Row(id, title))
      }
      out
    } catch (_: Exception) {
      emptyList()
    }
  }

  private fun toggleIntent(context: Context, reminderId: String): PendingIntent {
    val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java)
    intent.action = "es.antonborri.home_widget.action.BACKGROUND"
    intent.data =
        Uri.parse("reminderwidget://toggle?id=" + Uri.encode(reminderId))
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    val req = (31 * reminderId.hashCode()) xor reminderId.length
    return PendingIntent.getBroadcast(context, req, intent, flags)
  }

  companion object {
    private val rowIds =
        intArrayOf(
            R.id.widget_row_0,
            R.id.widget_row_1,
            R.id.widget_row_2,
            R.id.widget_row_3,
            R.id.widget_row_4,
            R.id.widget_row_5,
            R.id.widget_row_6,
            R.id.widget_row_7,
        )
    private val checkIds =
        intArrayOf(
            R.id.widget_check_0,
            R.id.widget_check_1,
            R.id.widget_check_2,
            R.id.widget_check_3,
            R.id.widget_check_4,
            R.id.widget_check_5,
            R.id.widget_check_6,
            R.id.widget_check_7,
        )
    private val textIds =
        intArrayOf(
            R.id.widget_text_0,
            R.id.widget_text_1,
            R.id.widget_text_2,
            R.id.widget_text_3,
            R.id.widget_text_4,
            R.id.widget_text_5,
            R.id.widget_text_6,
            R.id.widget_text_7,
        )
  }
}
