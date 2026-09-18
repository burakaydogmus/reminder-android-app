import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset with the Google Sans Flex licence (SIL OFL 1.1).
const googleSansFlexLicenseAsset = 'fonts/GoogleSansFlex/OFL.txt';

/// Package name the font licence is listed under on the Lisanslar page.
const googleSansFlexLicensePackage = 'Google Sans Flex';

/// Legalese under the app name on the Lisanslar page.
const appLegalese = 'MIT © 2026 Burak Aydoğmuş';

bool _registered = false;

/// Adds licences Flutter doesn't collect from `pubspec.lock` to the
/// [LicenseRegistry] (F6.2b): the bundled Google Sans Flex font. The asset is
/// read lazily, only when the Lisanslar page asks for licences. Idempotent.
void registerAppLicenses({AssetBundle? bundle}) {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    final text = await (bundle ?? rootBundle).loadString(
      googleSansFlexLicenseAsset,
    );
    yield LicenseEntryWithLineBreaks(
      const [googleSansFlexLicensePackage],
      text,
    );
  });
}

/// Test hook: lets a test register again after `LicenseRegistry.reset()`.
@visibleForTesting
void resetAppLicensesForTesting() => _registered = false;
