import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Geofence için gerekli konum izinleri (Android’de mümkünse arka plan).
Future<bool> ensureGeofenceLocationPermission() async {
  var status = await Permission.location.request();
  if (!status.isGranted) return false;

  if (Platform.isAndroid) {
    final bg = await Permission.locationAlways.request();
    return bg.isGranted;
  }

  final always = await Permission.locationAlways.request();
  return always.isGranted;
}
