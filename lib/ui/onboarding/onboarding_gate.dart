import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_store.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';

enum _Phase { checking, onboarding, home }

/// Decides between the first-launch onboarding (F4.2) and [home].
///
/// - Flag `onboarding_completed_v1` set → [home].
/// - Otherwise, if the cubit already holds reminders or birthdays (an
///   existing user) → the flag is set and [home] is shown.
/// - Otherwise the onboarding runs. If data arrives from the startup load
///   while the user has not moved past step 1 yet, the gate still skips.
///
/// "Atla", "Uygulamaya geç" and the step-4 suggestions set the flag.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    this.store,
    this.home = const HomeShell(),
    this.pinWidget,
  });

  /// Defaults to [OnboardingStore] over SharedPreferences.
  final OnboardingStore? store;

  final Widget home;

  /// Step 4 "Ana ekrana widget ekle"; defaults to [pinHomeScreenWidget].
  final Future<void> Function(BuildContext context)? pinWidget;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final OnboardingStore _store = widget.store ?? OnboardingStore();
  _Phase _phase = _Phase.checking;

  /// The user moved past step 1; late data no longer skips onboarding.
  bool _engaged = false;

  static bool _hasData(ReminderState state) =>
      state.reminders.isNotEmpty || state.birthdays.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final completed = await _store.isCompleted();
    if (!mounted) return;
    if (completed) {
      setState(() => _phase = _Phase.home);
      return;
    }
    if (_hasData(context.read<ReminderCubit>().state)) {
      await _finish();
      return;
    }
    setState(() => _phase = _Phase.onboarding);
  }

  Future<void> _finish([OnboardingFollowUp? then]) async {
    if (!mounted || _phase == _Phase.home) return;
    setState(() => _phase = _Phase.home);
    if (then != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) then(context);
      });
    }
    await _store.markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.korMotion;
    final Widget child;
    switch (_phase) {
      case _Phase.checking:
        child = const Scaffold(key: ValueKey(_Phase.checking));
      case _Phase.onboarding:
        child = OnboardingFlow(
          key: const ValueKey(_Phase.onboarding),
          onSkip: _finish,
          onFinish: _finish,
          onEngaged: () => _engaged = true,
          pinWidget: widget.pinWidget,
        );
      case _Phase.home:
        child =
            KeyedSubtree(key: const ValueKey(_Phase.home), child: widget.home);
    }

    return BlocListener<ReminderCubit, ReminderState>(
      listenWhen: (_, next) =>
          _phase == _Phase.onboarding && !_engaged && _hasData(next),
      listener: (_, __) => _finish(),
      child: AnimatedSwitcher(
        duration: motion.durationOf(context, motion.long),
        switchInCurve: motion.fallbackCurve,
        switchOutCurve: motion.fallbackCurve,
        child: child,
      ),
    );
  }
}
