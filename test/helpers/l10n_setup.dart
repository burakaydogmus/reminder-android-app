import 'package:intl/date_symbol_data_local.dart';

/// Loads the `intl` date symbols of both app locales (F6.1). Pure tests of
/// date/time texts call it in `setUpAll`; `UiHarness.create` does it too.
Future<void> initTestDateFormatting() async {
  await initializeDateFormatting('tr_TR');
  await initializeDateFormatting('en_US');
}
