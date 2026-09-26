/// Legacy entry point of the quick-capture parser.
///
/// The parser is multilingual since F4.6c; the library now lives in
/// [capture_parser.dart](capture_parser.dart) and takes a `CaptureLocale`.
/// This file only re-exports it so existing imports keep working — import
/// `capture_parser.dart` in new code.
library;

export 'package:reminder/domain/parsing/capture_parser.dart';
