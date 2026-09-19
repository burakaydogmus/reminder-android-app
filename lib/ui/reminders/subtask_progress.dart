import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';

/// Subtask progress texts (F3.3), shared by the card, the compact row and the
/// editor's Maddeler card.
abstract final class SubtaskProgressText {
  /// "2/6".
  static String count(List<Subtask> subtasks) =>
      '${subtasks.doneCount}/${subtasks.length}';

  /// Screen reader text: "6 maddeden 2'si tamamlandı" reads awkwardly with
  /// Turkish suffixes, so the neutral "maddeler: 2/6 tamamlandı" is used.
  static String spoken(List<Subtask> subtasks, AppLocalizations l10n) =>
      l10n.subtasksSpoken(count(subtasks));
}

/// Thin progress bar in the category colour (§3.3.4: 6 px in the editor, a
/// thinner one on cards). Colour is never the only signal: the "2/6" text
/// sits next to it. The bar itself is excluded from semantics; callers put
/// [SubtaskProgressText.spoken] in their label.
class SubtaskProgressBar extends StatelessWidget {
  const SubtaskProgressBar({
    super.key,
    required this.subtasks,
    required this.color,
    this.height = 6,
  });

  final List<Subtask> subtasks;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: KorRadius.fullAll,
        child: LinearProgressIndicator(
          value: subtasks.progress,
          minHeight: height,
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
