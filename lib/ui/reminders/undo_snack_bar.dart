import 'package:flutter/semantics.dart' show FocusSemanticEvent;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';

/// "Geri al" snackbar after complete / delete / snooze (§3.5, §3.6 rule 9).
///
/// One at a time: showing a new one removes the previous one immediately
/// (its action was already applied, so it is simply final). Visible for
/// [duration], or [screenReaderDuration] when a screen reader is active; in
/// that case accessibility focus moves to the "Geri al" action.
abstract final class UndoSnackBar {
  static const Duration duration = Duration(seconds: 5);
  static const Duration screenReaderDuration = Duration(seconds: 10);

  static void show(
    ScaffoldMessengerState messenger, {
    required String message,
    required VoidCallback onUndo,
  }) {
    final accessible = MediaQuery.accessibleNavigationOf(messenger.context);
    final actionKey = GlobalKey();
    messenger
      ..clearSnackBars()
      ..removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: accessible ? screenReaderDuration : duration,
        // An action would otherwise keep the snackbar open forever.
        persist: false,
        action: SnackBarAction(
          key: actionKey,
          label: messenger.context.l10n.actionUndo,
          onPressed: onUndo,
        ),
      ),
    );
    if (accessible) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusAction(actionKey),
      );
    }
  }

  /// Sends accessibility focus to the action's button node.
  static void _focusAction(GlobalKey key) {
    final context = key.currentContext;
    if (context is! Element) return;
    RenderObject? target;
    void visit(Element element) {
      if (target != null) return;
      final widget = element.widget;
      if (widget is Semantics && (widget.properties.button ?? false)) {
        target = element.renderObject;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildren(visit);
    (target ?? context.renderObject)?.sendSemanticsEvent(
      const FocusSemanticEvent(),
    );
  }
}
