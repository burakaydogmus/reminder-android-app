package com.burakaydogmus.reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget'ların saate bağlı yenilemesi (F5.1).
 *
 * Bir iş zamanı geçince "16:00" → "Gecikti", gece yarısında "Yarın" → saat ve
 * bölümler değişir; uygulama açılmasa da widget doğru kalmalı. Her çizimden sonra
 * [schedule] tek bir **uyandırmayan, esnek** (`AlarmManager.RTC`, `set`) alarm
 * kurar: bir sonraki `dueAt` veya gece yarısı, hangisi önceyse. Cihaz uykudaysa
 * alarm ekran açılınca teslim edilir — kimse bakmazken widget için pil harcanmaz,
 * tam zamanlı alarm izni gerekmez. Alarm tüm widget'ları yeniler; her çizim
 * alarmı yeniden kurar (aynı PendingIntent, yenisi eskinin yerine geçer).
 *
 * Yeniden başlatma / uygulama güncellemesi alarmı siler; sistem o sırada
 * widget'lara `APPWIDGET_UPDATE` gönderir, çizim alarmı yeniden kurar. Saat veya
 * saat dilimi elle değişince de ([Intent.ACTION_TIME_CHANGED],
 * [Intent.ACTION_TIMEZONE_CHANGED]) widget'lar hemen yenilenir.
 */
class ReminderWidgetRefreshReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    when (intent.action) {
      ACTION_REFRESH,
      Intent.ACTION_TIME_CHANGED,
      Intent.ACTION_TIMEZONE_CHANGED -> WidgetViews.updateAll(context)
    }
  }

  companion object {
    const val ACTION_REFRESH = "com.burakaydogmus.reminder.action.WIDGET_REFRESH"

    /** Bir sonraki görünüm değişimine esnek, uyandırmayan alarm kurar. */
    fun schedule(context: Context) {
      val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
      val raw = WidgetPayload.read(HomeWidgetPlugin.getData(context))
      // Saat dakika başında değişir; bir saniye pay, sınırın hemen öncesinde
      // çizip aynı görünümü tekrar kurmayı önler.
      val at = WidgetPayload.nextChangeAt(raw) + 1_000L
      try {
        alarms.set(AlarmManager.RTC, at, pendingIntent(context))
      } catch (_: SecurityException) {
        // Bazı üretici ROM'ları alarm sayısını sınırlar; bir sonraki senkron
        // veya sistem güncellemesi yine yeniler.
      }
    }

    private fun pendingIntent(context: Context): PendingIntent {
      val intent =
          Intent(context, ReminderWidgetRefreshReceiver::class.java).setAction(ACTION_REFRESH)
      return PendingIntent.getBroadcast(
          context,
          0,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
    }
  }
}
