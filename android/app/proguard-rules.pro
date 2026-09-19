# R8 keep rules for release builds (see android/app/build.gradle).
# Flutter's own rules (io.flutter.**, Play Core dontwarn) are added by the
# Flutter Gradle plugin; plugin AARs add their consumer rules automatically.

# flutter_local_notifications serialises scheduled notifications with Gson
# and reads them back through TypeToken generics. Gson >= 2.11 ships these
# rules itself; they are kept here as a safety net (Gson's android example).
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod,InnerClasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# native_geofence persists geofences with kotlinx.serialization and restarts
# them from receivers/WorkManager while the app is closed. Keep the plugin
# (receivers, background worker, @Serializable models and their serializers).
-keep class com.chunkytofustudios.native_geofence.** { *; }
-keepclassmembers @kotlinx.serialization.Serializable class ** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}

# home_widget resolves widget providers by class name (Class.forName) for
# updates and background callbacks. F5.1: four providers, the list service
# and the click/refresh receivers (manifest components, kept by name here too
# so Dart's qualifiedAndroidName always matches).
-keep class es.antonborri.home_widget.** { *; }
-keep class com.burakaydogmus.reminder.Reminder*WidgetProvider { *; }
-keep class com.burakaydogmus.reminder.ReminderListWidgetService { *; }
-keep class com.burakaydogmus.reminder.ReminderListWidgetService$* { *; }
-keep class com.burakaydogmus.reminder.ReminderWidget*Receiver { *; }
