import 'package:url_launcher/url_launcher.dart';

/// External links shown in the app (F6.2b). Keep every URL here so store
/// documents and the app point to the same place.
abstract final class AppLinks {
  /// Turkish privacy policy (`docs/store/privacy-policy.tr.md`).
  ///
  /// TODO(F6.3): replace with the hosted policy page (e.g. GitHub Pages) once
  /// it is published with a contact address; the store listings must use the
  /// same URL.
  static final privacyPolicy = Uri.parse(
    'https://github.com/burakaydogmus/reminder-android-app/blob/master/'
    'docs/store/privacy-policy.tr.md',
  );

  /// OpenStreetMap copyright and licence page, linked from the map
  /// attribution (OSMF tile usage policy).
  static final osmCopyright = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );
}

/// Opens a URI outside the app; `false` when nothing could handle it.
/// Injected into widgets so tests don't hit the platform channel.
typedef LinkOpener = Future<bool> Function(Uri uri);

/// Default [LinkOpener]: the system browser via `url_launcher`. Only
/// `launchUrl` is used (no `canLaunchUrl`), so no Android `<queries>` or iOS
/// `LSApplicationQueriesSchemes` entries are needed.
Future<bool> openExternalLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
