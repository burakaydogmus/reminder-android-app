import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Writes the current frame to `build/a11y_shots/<name>.png` (tests render
/// text with the square test font). Used by `a11yAudit` when run with
/// `--dart-define=A11Y_SHOTS=true`, to look at a failing variant.
Future<void> debugShot(WidgetTester tester, String name) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final safe = name.replaceAll(RegExp(r'[^\w\s.,()-]', unicode: true), '_');
  await tester.binding.runAsync(() async {
    final image = await layer.toImage(view.paintBounds);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File('build/a11y_shots/$safe.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}
