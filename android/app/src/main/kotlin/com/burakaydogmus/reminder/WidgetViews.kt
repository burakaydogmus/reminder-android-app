package com.burakaydogmus.reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Dört widget'ın ortak parçaları (F5.1): adresler, PendingIntent'ler, renkler,
 * satır bağlama ve "Bildirimler kapalı" şeridi.
 *
 * Adresler Dart `WidgetLaunchTarget` / `reminderIdFromWidgetUri` ile ortak:
 * `reminderwidget://new`, `open?id=`, `birthday?id=`, `permissions` uygulamayı
 * açar; `toggle?id=` arka plan callback'inde tamamlar.
 */
object WidgetViews {
  const val SCHEME = "reminderwidget"

  val newUri: Uri = Uri.parse("$SCHEME://new")
  val permissionsUri: Uri = Uri.parse("$SCHEME://permissions")

  fun openUri(id: String): Uri = Uri.parse("$SCHEME://open?id=" + Uri.encode(id))

  fun birthdayUri(id: String): Uri = Uri.parse("$SCHEME://birthday?id=" + Uri.encode(id))

  fun toggleUri(id: String): Uri = Uri.parse("$SCHEME://toggle?id=" + Uri.encode(id))

  /** Uygulamayı doğrudan açan PendingIntent (trambolin yok; arka plan etkinlik kısıtı yok). */
  fun launch(context: Context, uri: Uri?): PendingIntent =
      HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)

  /** Uygulamayı açmadan tamamlar (`reminderHomeWidgetCallback`). */
  fun toggle(context: Context, id: String): PendingIntent =
      HomeWidgetBackgroundIntent.getBroadcast(context, toggleUri(id))

  /** Dört sağlayıcının tümü; senkron ve saat yenilemesi hepsini günceller. */
  val providers: List<Class<*>> =
      listOf(
          ReminderTodayWidgetProvider::class.java,
          ReminderListWidgetProvider::class.java,
          ReminderNextWidgetProvider::class.java,
          ReminderQuickAddWidgetProvider::class.java,
      )

  /** Ana ekrandaki tüm widget'lara `APPWIDGET_UPDATE` gönderir. */
  fun updateAll(context: Context) {
    val manager = AppWidgetManager.getInstance(context)
    for (provider in providers) {
      val ids = manager.getAppWidgetIds(ComponentName(context, provider))
      if (ids.isEmpty()) continue
      val intent =
          Intent(context, provider)
              .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
              .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
      context.sendBroadcast(intent)
    }
  }

  /** Metin rengi; API 31+'da kaynak olarak (tema/dinamik renk değişince yeniden çözülür). */
  fun setTextColorRes(
      context: Context,
      views: RemoteViews,
      id: Int,
      color: Int,
  ) {
    if (Build.VERSION.SDK_INT >= 31) {
      views.setColor(id, "setTextColor", color)
    } else {
      views.setTextColor(id, context.getColor(color))
    }
  }

  /** ImageView rengi (onay dairesi). */
  fun setTintRes(context: Context, views: RemoteViews, id: Int, color: Int) {
    if (Build.VERSION.SDK_INT >= 31) {
      views.setColor(id, "setColorFilter", color)
    } else {
      views.setInt(id, "setColorFilter", context.getColor(color))
    }
  }

  /** Kor kategori rengi (`CategoryVisuals.colorKeyFor`). */
  fun categoryColor(key: String): Int =
      when (key) {
        "market" -> R.color.widget_cat_market
        "ev" -> R.color.widget_cat_ev
        "is" -> R.color.widget_cat_is
        "saglik" -> R.color.widget_cat_saglik
        "gunluk" -> R.color.widget_cat_gunluk
        "dogumgunu" -> R.color.widget_cat_dogumgunu
        else -> R.color.widget_cat_diger
      }

  /** Satırın ikinci bilgisi: "16:00 · 2/6 · Tekrarlanan". */
  fun meta(context: Context, item: WidgetPayload.Item, now: Long): String =
      listOfNotNull(
              WidgetPayload.timeLabel(context, item.dueAt, now),
              item.subtasks,
              if (item.recurring) "↻" else null,
          )
          .joinToString(" · ")

  /** TalkBack: "Ali'yi kurstan al, 16:00, 2/6 madde, tekrarlanan". */
  fun spoken(context: Context, item: WidgetPayload.Item, now: Long): String =
      listOfNotNull(
              item.title,
              WidgetPayload.timeLabel(context, item.dueAt, now),
              item.subtasks?.let { context.getString(R.string.widget_cd_subtasks, it) },
              if (item.recurring) context.getString(R.string.widget_cd_recurring) else null,
          )
          .joinToString(", ")

  /**
   * Doğrudan tıklanabilir bir hatırlatıcı satırı (Bugün): daire → tamamla (arka plan),
   * satır → hatırlatıcıyı aç.
   */
  fun bindRow(
      context: Context,
      views: RemoteViews,
      ids: RowIds,
      item: WidgetPayload.Item,
      now: Long,
  ) {
    bindRowContent(context, views, ids, item, now)
    views.setOnClickPendingIntent(ids.row, launch(context, openUri(item.id)))
    views.setOnClickPendingIntent(ids.check, toggle(context, item.id))
  }

  /** Satırın metin, renk ve erişilebilirlik içeriği (tıklamalar hariç). */
  fun bindRowContent(
      context: Context,
      views: RemoteViews,
      ids: RowIds,
      item: WidgetPayload.Item,
      now: Long,
  ) {
    views.setViewVisibility(ids.row, View.VISIBLE)
    views.setTextViewText(ids.title, item.title)
    val meta = meta(context, item, now)
    views.setTextViewText(ids.meta, meta)
    views.setViewVisibility(ids.meta, if (meta.isEmpty()) View.GONE else View.VISIBLE)
    val overdue = item.dueAt != null && item.dueAt < now
    setTextColorRes(
        context,
        views,
        ids.meta,
        if (overdue) R.color.widget_primary else R.color.widget_on_surface_variant,
    )
    setTintRes(context, views, ids.check, categoryColor(item.category))
    views.setContentDescription(
        ids.check,
        context.getString(R.string.widget_cd_complete, item.title),
    )
    views.setContentDescription(ids.row, spoken(context, item, now))
  }

  /** "Bildirimler kapalı — açmak için dokun" şeridi (Ayarlar › İzinler). */
  fun bindNotificationsStrip(
      context: Context,
      views: RemoteViews,
      strip: Int,
      enabled: Boolean,
  ) {
    views.setViewVisibility(strip, if (enabled) View.GONE else View.VISIBLE)
    if (!enabled) views.setOnClickPendingIntent(strip, launch(context, permissionsUri))
  }

  /** "+" hap: yeni hatırlatıcı. */
  fun bindAdd(context: Context, views: RemoteViews, add: Int) {
    views.setOnClickPendingIntent(add, launch(context, newUri))
  }

  data class RowIds(
      val row: Int,
      val check: Int,
      val title: Int,
      val meta: Int,
  )
}
