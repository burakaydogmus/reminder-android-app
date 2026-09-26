import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/contact_birthday_import.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/contacts_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class ContactImportKeys {
  static const sheet = Key('contactImport.sheet');
  static const selectAll = Key('contactImport.selectAll');
  static const importButton = Key('contactImport.import');
  static const openSettings = Key('contactImport.openSettings');
  static const done = Key('contactImport.done');
  static Key row(String key) => ValueKey('contactImport.row.$key');
}

/// Doğum günleri › "Rehberden aktar" (F7.3): reads the address book **once**,
/// lists the contacts that have a birthday and adds the selected ones as
/// birthdays.
///
/// One-shot and read-only: nothing is written to the address book, no sync is
/// kept, and only the name and the date leave a contact. Resolves to the run's
/// [ContactImportResult], or `null` when nothing was imported.
Future<ContactImportResult?> showContactImportSheet(
  BuildContext context, {
  ContactsPlatform platform = const PluginContactsPlatform(),
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final result = await showModalBottomSheet<ContactImportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ContactImportBody(platform: platform),
  );
  if (result == null || result.isEmpty) return result;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.skippedCount == 0
            ? l10n.contactImportSnack(result.importedCount)
            : l10n.contactImportSnackWithSkipped(
                result.importedCount,
                result.skippedCount,
              ),
      ),
    ),
  );
  return result;
}

/// What the sheet is showing.
enum _Stage {
  /// Asking for the permission / reading the address book.
  loading,

  /// The permission was refused (or revoked while reading): explain and offer
  /// the Settings deep link.
  denied,

  /// The address book could not be read for a reason that is not a denial.
  unavailable,

  /// Read fine, but no contact has a birthday.
  empty,

  /// The pickable list.
  list,

  /// The summary of what was imported and what was already there.
  result,
}

class _ContactImportBody extends StatefulWidget {
  const _ContactImportBody({required this.platform});

  final ContactsPlatform platform;

  @override
  State<_ContactImportBody> createState() => _ContactImportBodyState();
}

class _ContactImportBodyState extends State<_ContactImportBody> {
  _Stage _stage = _Stage.loading;
  List<ContactImportCandidate> _rows = const [];
  final Set<String> _selected = {};
  ContactImportResult _result = const ContactImportResult.empty();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    // The permission prompt and the read must not run inside build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  /// Permission first (explanation sheet, then the system prompt once), then a
  /// single read. A refusal is not an error state: the sheet explains what to do
  /// and the action stays usable.
  Future<void> _start() async {
    if (!mounted) return;
    final state = await PermissionFlows.contacts(context);
    if (!mounted) return;
    if (state != ContactsPermissionState.granted) {
      setState(() => _stage = _Stage.denied);
      return;
    }
    await _read();
  }

  Future<void> _read() async {
    if (!mounted) return;
    setState(() => _stage = _Stage.loading);
    final List<ContactBirthday> contacts;
    try {
      contacts = await widget.platform.birthdays();
    } on ContactsReadException catch (error) {
      if (!mounted) return;
      // A read that fails with a denial means the permission went away between
      // the check and the read (revoked in system settings, or the OS changed
      // its mind) — the same graceful degradation the calendar feature does.
      setState(
        () => _stage = error.failure == ContactsFailure.permissionDenied
            ? _Stage.denied
            : _Stage.unavailable,
      );
      return;
    }
    if (!mounted) return;
    final rows = ContactBirthdayImport.candidates(
      contacts: contacts,
      existing: context.read<ReminderCubit>().state.birthdays,
    );
    setState(() {
      _rows = rows;
      _selected.clear();
      _stage = rows.isEmpty ? _Stage.empty : _Stage.list;
    });
  }

  Set<String> get _selectable => ContactBirthdayImport.selectableKeys(_rows);

  bool get _allSelected =>
      _selectable.isNotEmpty && _selected.length == _selectable.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_selectable);
      }
    });
  }

  Future<void> _openSettings() async {
    final state = await PermissionFlows.fixContacts(context);
    if (!mounted) return;
    if (state == ContactsPermissionState.granted) await _read();
  }

  Future<void> _import() async {
    final cubit = context.read<ReminderCubit>();
    final (birthdays, result) = ContactBirthdayImport.plan(
      rows: _rows,
      selectedKeys: _selected,
      newId: const Uuid().v4,
      createdAt: DateTime.now(),
    );
    setState(() => _importing = true);
    // Imported birthdays schedule notifications, so the same pre-permission
    // flow the manual editor runs applies here too.
    if (birthdays.isNotEmpty && cubit.state.settings.notificationsEnabled) {
      await PermissionFlows.beforeScheduling(context);
    }
    for (final birthday in birthdays) {
      await cubit.addBirthday(birthday);
    }
    if (!mounted) return;
    setState(() {
      _importing = false;
      _result = result;
      _stage = _Stage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      key: ContactImportKeys.sheet,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KorSpacing.screenEdge,
                  0,
                  KorSpacing.screenEdge,
                  KorSpacing.s3,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    _stage == _Stage.result
                        ? l10n.contactImportResultTitle
                        : l10n.contactImportTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              Flexible(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_stage) {
      case _Stage.loading:
        return _message(context, context.l10n.contactImportLoading);
      case _Stage.denied:
        return _denied(context);
      case _Stage.unavailable:
        return _message(context, context.l10n.contactImportUnavailable);
      case _Stage.empty:
        return _message(context, context.l10n.contactImportEmpty);
      case _Stage.list:
        return _list(context);
      case _Stage.result:
        return _resultView(context);
    }
  }

  Widget _message(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KorSpacing.screenEdge,
        0,
        KorSpacing.screenEdge,
        KorSpacing.s6,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _denied(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KorSpacing.screenEdge,
        0,
        KorSpacing.screenEdge,
        KorSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.contactImportDenied,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: KorSpacing.s5),
          FilledButton(
            key: ContactImportKeys.openSettings,
            onPressed: _openSettings,
            child: Text(l10n.permissionOpenSettings),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selectable = _selectable;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KorSpacing.screenEdge,
          ),
          child: Text(
            l10n.contactImportFound(_rows.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (selectable.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KorSpacing.s3,
              ),
              child: TextButton(
                key: ContactImportKeys.selectAll,
                onPressed: _toggleAll,
                child: Text(
                  _allSelected
                      ? l10n.contactImportSelectNone
                      : l10n.contactImportSelectAll(selectable.length),
                ),
              ),
            ),
          ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s3,
            ),
            itemCount: _rows.length,
            itemBuilder: (context, index) => _Row(
              key: ContactImportKeys.row(_rows[index].key),
              candidate: _rows[index],
              selected: _selected.contains(_rows[index].key),
              onChanged: (value) => setState(() {
                if (value) {
                  _selected.add(_rows[index].key);
                } else {
                  _selected.remove(_rows[index].key);
                }
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KorSpacing.screenEdge,
            KorSpacing.s3,
            KorSpacing.screenEdge,
            KorSpacing.s4,
          ),
          child: FilledButton(
            key: ContactImportKeys.importButton,
            onPressed: _selected.isEmpty || _importing ? null : _import,
            child: Text(l10n.contactImportAction(_selected.length)),
          ),
        ),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.screenEdge,
            ),
            children: [
              Text(
                l10n.contactImportResultImported(_result.importedCount),
                style: theme.textTheme.titleSmall,
              ),
              if (_result.imported.isEmpty)
                Text(l10n.contactImportResultNothing, style: muted)
              else
                Text(_result.imported.join(' · '), style: muted),
              if (_result.skipped.isNotEmpty) ...[
                const SizedBox(height: KorSpacing.s4),
                Text(
                  l10n.contactImportResultSkipped(_result.skippedCount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(_result.skipped.join(' · '), style: muted),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KorSpacing.screenEdge,
            KorSpacing.s4,
            KorSpacing.screenEdge,
            KorSpacing.s4,
          ),
          child: FilledButton(
            key: ContactImportKeys.done,
            onPressed: () => Navigator.of(context).pop(_result),
            child: Text(l10n.actionDone),
          ),
        ),
      ],
    );
  }
}

/// One contact row: checkbox, name, the date and — when the year is missing —
/// a note that the age will be unknown. An already added birthday is disabled
/// and says so, instead of being dropped from the list.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onChanged,
  });

  final ContactImportCandidate candidate;
  final bool selected;
  final ValueChanged<bool> onChanged;

  /// `14 Eylül` without a year, `14 Eylül 1990` with one.
  static String dateLabel(ContactBirthday c, AppLocalizations l10n) {
    final year = c.year;
    return KorFormat.pattern(
      year == null ? l10n.dateFormatDayMonth : l10n.dateFormatDayMonthYear,
      DateTime(year ?? 2000, c.month, c.day),
      l10n,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final contact = candidate.contact;
    final date = dateLabel(contact, l10n);
    final note = candidate.alreadyAdded
        ? l10n.contactImportAlreadyAdded
        : (contact.hasYear ? null : l10n.contactImportYearUnknown);

    return CheckboxListTile(
      value: candidate.alreadyAdded ? false : selected,
      onChanged: candidate.alreadyAdded ? null : (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(contact.name),
      subtitle: Text(
        note == null ? date : l10n.contactImportRowSubtitle(date, note),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
