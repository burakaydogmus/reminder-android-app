/// İsteğe bağlı: yakındaki market araması (Google Places) için
/// `--dart-define=GOOGLE_MAPS_KEY=...` ile anahtar verin.
/// Harita OpenStreetMap ile çalışır; bu anahtar zorunlu değildir.
const String kGoogleMapsKey = String.fromEnvironment(
  'GOOGLE_MAPS_KEY',
  defaultValue: '',
);

bool get mapsConfigured => kGoogleMapsKey.isNotEmpty;
