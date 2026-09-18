import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset with the Google Sans Flex licence (SIL OFL 1.1).
const googleSansFlexLicenseAsset = 'fonts/GoogleSansFlex/OFL.txt';

/// Package name the font licence is listed under on the Lisanslar page.
const googleSansFlexLicensePackage = 'Google Sans Flex';

/// Notice for `liquid_glass_renderer` (MIT, Tim Lehmann), vendored inside
/// `liquid_glass_widgets`; copied verbatim from that package's
/// `THIRD_PARTY_NOTICES`.
const liquidGlassRendererLicenseAsset =
    'assets/licenses/liquid_glass_renderer.txt';

/// Package name the `liquid_glass_renderer` notice is listed under.
const liquidGlassRendererLicensePackage = 'liquid_glass_renderer';

/// Notice for `motor` (MIT, Tim Lehmann), whose spring code is adapted inside
/// `liquid_glass_widgets`; copied verbatim from its `THIRD_PARTY_NOTICES`.
const motorLicenseAsset = 'assets/licenses/motor.txt';

/// Package name the `motor` notice is listed under.
const motorLicensePackage = 'motor';

/// Legalese under the app name on the Lisanslar page.
const appLegalese = 'MIT © 2026 Burak Aydoğmuş';

/// (package, asset) pairs [registerAppLicenses] adds.
const _appLicenses = <(String, String)>[
  (googleSansFlexLicensePackage, googleSansFlexLicenseAsset),
  (liquidGlassRendererLicensePackage, liquidGlassRendererLicenseAsset),
  (motorLicensePackage, motorLicenseAsset),
];

bool _registered = false;

/// Adds licences Flutter doesn't collect from `pubspec.lock` to the
/// [LicenseRegistry] (F6.2b): the bundled Google Sans Flex font and the
/// third-party notices vendored inside `liquid_glass_widgets` (only in its
/// `THIRD_PARTY_NOTICES`, which Flutter doesn't read). Assets are read lazily,
/// only when the Lisanslar page asks for licences. Idempotent.
void registerAppLicenses({AssetBundle? bundle}) {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (package, asset) in _appLicenses) {
      final text = await (bundle ?? rootBundle).loadString(asset);
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}

/// Test hook: lets a test register again after `LicenseRegistry.reset()`.
@visibleForTesting
void resetAppLicensesForTesting() => _registered = false;
