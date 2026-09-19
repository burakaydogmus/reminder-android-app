import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/onboarding/steps/capture_demo_step.dart';
import 'package:reminder/ui/onboarding/steps/notification_step.dart';
import 'package:reminder/ui/onboarding/steps/ready_step.dart';
import 'package:reminder/ui/onboarding/steps/welcome_step.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Runs after onboarding was left, with a context below the app navigator
/// (e.g. to open an editor on top of the home shell).
typedef OnboardingFollowUp = void Function(BuildContext context);

/// Keys for tests.
abstract final class OnboardingKeys {
  static const skip = Key('onboarding.skip');
  static const start = Key('onboarding.start');
  static const next = Key('onboarding.next');
  static const allowNotifications = Key('onboarding.allowNotifications');
  static const notNow = Key('onboarding.notNow');
  static const marketSuggestion = Key('onboarding.suggestion.market');
  static const birthdaySuggestion = Key('onboarding.suggestion.birthday');
  static const widgetSuggestion = Key('onboarding.suggestion.widget');
  static const enterApp = Key('onboarding.enterApp');
}

/// Asks Android to pin the reminder list widget (same action as Ayarlar →
/// "Widget ekle"); falls back to instructions where pinning is unsupported.
Future<void> pinHomeScreenWidget(BuildContext context) async {
  final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
  if (!context.mounted) return;
  if (supported) {
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: kReminderListWidgetQualifiedAndroidName,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.onboardingWidgetUnsupported)),
    );
  }
}

/// The 4-step first-launch onboarding (`kor-design-proposal.md` §3.3.1).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onSkip,
    required this.onFinish,
    this.onEngaged,
    this.pinWidget,
    this.initialPage = 0,
  });

  /// "Atla".
  final VoidCallback onSkip;

  /// "Uygulamaya geç" (no follow-up) or a step-4 suggestion (follow-up opens
  /// the editor once the app is shown).
  final void Function([OnboardingFollowUp? then]) onFinish;

  /// Called once the user moves past step 1.
  final VoidCallback? onEngaged;

  final Future<void> Function(BuildContext context)? pinWidget;

  /// Start page (tests).
  final int initialPage;

  static const stepCount = 4;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _controller =
      PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    if (page > 0) widget.onEngaged?.call();
  }

  void _goTo(int page) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.jumpToPage(page);
      return;
    }
    final motion = context.korMotion;
    _controller.animateToPage(
      page,
      duration: motion.long,
      curve: motion.fallbackCurve,
    );
  }

  void _next() => _goTo(_page + 1);

  @override
  Widget build(BuildContext context) {
    final showSkip = _page < OnboardingFlow.stepCount - 1;
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              children: [
                // Focus/reading order: step content and its actions first,
                // "Atla" last.
                Semantics(
                  sortKey: const OrdinalSortKey(2),
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KorSpacing.s3,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Visibility(
                          visible: showSkip,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            key: OnboardingKeys.skip,
                            onPressed: showSkip ? widget.onSkip : null,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                KorSizes.minTouch,
                                KorSizes.minTouch,
                              ),
                            ),
                            child: Text(context.l10n.onboardingSkip),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    sortKey: const OrdinalSortKey(1),
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: PageView(
                        controller: _controller,
                        onPageChanged: _onPageChanged,
                        children: [
                          WelcomeStep(onStart: _next),
                          CaptureDemoStep(onNext: _next),
                          NotificationStep(onNext: _next),
                          ReadyStep(
                            onCreateMarketList: () => widget.onFinish(
                              (ctx) => showReminderEditorSheet(
                                ctx,
                                initialCategoryId: ReminderCategoryIds.market,
                              ),
                            ),
                            onAddBirthday: () => widget.onFinish(
                              (ctx) => showBirthdayEditorSheet(ctx),
                            ),
                            onPinWidget: () =>
                                (widget.pinWidget ?? pinHomeScreenWidget)(
                              context,
                            ),
                            onEnterApp: () => widget.onFinish(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
