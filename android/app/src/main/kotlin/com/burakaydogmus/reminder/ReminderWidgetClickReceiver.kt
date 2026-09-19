package com.burakaydogmus.reminder

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver

/**
 * Liste koleksiyonundaki dokunmaların tek şablonu (F5.1).
 *
 * Koleksiyon satırları kendi PendingIntent'ini taşıyamaz; tek bir şablon + satır
 * başına fill-in adresi gerekir. Bir satırda iki farklı eylem var (daire → arka
 * planda tamamla, satır → uygulamayı aç), bu yüzden şablon bu alıcıya gider:
 *
 * - `toggle?id=` → `home_widget`'ın arka plan alıcısına iletilir (uygulama açılmaz).
 * - `open?id=`, `birthday?id=` → uygulama `HomeWidgetLaunchIntent` ile açılır.
 *   Görünür başlatıcının gönderdiği PendingIntent alıcıya kısa bir arka plan
 *   etkinlik başlatma izni verir; API 34+'da gönderen olarak da izin açıkça
 *   istenir. Liste dışındaki tüm "aç" dokunuşları trambolinsiz, doğrudan
 *   etkinlik PendingIntent'idir ([WidgetViews.launch]).
 */
class ReminderWidgetClickReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != ACTION_CLICK) return
    val uri = intent.data ?: return
    if (uri.scheme != WidgetViews.SCHEME) return
    if (uri.host == "toggle") {
      val forward =
          Intent(context, HomeWidgetBackgroundReceiver::class.java)
              .setAction(HOME_WIDGET_BACKGROUND_ACTION)
              .setData(uri)
      context.sendBroadcast(forward)
      return
    }
    try {
      val options =
          if (Build.VERSION.SDK_INT >= 34) {
            ActivityOptions.makeBasic()
                .apply {
                  setPendingIntentBackgroundActivityStartMode(
                      ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                  )
                }
                .toBundle()
          } else {
            null
          }
      WidgetViews.launch(context, uri).send(context, 0, null, null, null, null, options)
    } catch (e: Exception) {
      Log.w(TAG, "Could not open the app from the list widget", e)
    }
  }

  companion object {
    private const val TAG = "ReminderWidgetClick"
    const val ACTION_CLICK = "com.burakaydogmus.reminder.action.WIDGET_CLICK"
    private const val HOME_WIDGET_BACKGROUND_ACTION = "es.antonborri.home_widget.action.BACKGROUND"

    /** Liste koleksiyonunun şablonu; fill-in yalnız `data`'yı doldurur (değişebilir olmalı). */
    fun template(context: Context): PendingIntent {
      val intent = Intent(context, ReminderWidgetClickReceiver::class.java).setAction(ACTION_CLICK)
      var flags = PendingIntent.FLAG_UPDATE_CURRENT
      flags = flags or if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
      return PendingIntent.getBroadcast(context, 1, intent, flags)
    }
  }
}
