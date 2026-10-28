import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../settings/settings_providers.dart';
import '../../l10n/l10n.dart';

class _Step {
  const _Step(this.title, this.body, this.icon);
  final String title;
  final String body;
  final IconData? icon; // null = la comilla del feed
}

const _stepCount = 3;

List<_Step> _steps(AppLocalizations l) => [
  _Step(l.onboardingStep1Title, l.onboardingStep1Body, null),
  _Step(
    l.onboardingStep2Title,
    l.onboardingStep2Body,
    Icons.cloud_off_outlined,
  ),
  _Step(
    l.onboardingStep3Title,
    l.onboardingStep3Body,
    Icons.swipe_vertical_outlined,
  ),
];

/// Bienvenida mínima de tres pasos; se puede saltar en cualquier momento.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await saveOnboardingDone();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page == _stepCount - 1) {
      _finish();
      return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: AppDuration.transition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final steps = _steps(l);
    final last = _page == _stepCount - 1;
    return SosiegoPage(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: Gap.s8, top: Gap.s8),
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSize.minTarget, AppSize.minTarget),
                  foregroundColor: scheme.onSurface.withValues(alpha: 0.8),
                ),
                child: Text(
                  l.onboardingSkip,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: const Key('onboarding-pages'),
              controller: _controller,
              itemCount: _stepCount,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _StepView(step: steps[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s32,
              Gap.s8,
              Gap.s32,
              Gap.s24,
            ),
            child: Column(
              children: [
                Semantics(
                  label: l.onboardingStepSemantics(_page + 1, _stepCount),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _stepCount; i++)
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : AppDuration.quick,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.25),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Gap.s24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('onboarding-next'),
                    onPressed: _next,
                    child: Text(last ? l.onboardingStart : l.onboardingNext),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Gap.s32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: step.icon == null
                    ? Text(
                        '“',
                        style: TextStyle(
                          fontFamily: AppTheme.verseFont,
                          fontSize: 120,
                          height: 0.8,
                          color: scheme.primary.withValues(alpha: 0.5),
                        ),
                      )
                    : Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.accentWash,
                        ),
                        child: Icon(step.icon, size: 40, color: scheme.primary),
                      ),
              ),
              const SizedBox(height: Gap.s24),
              Semantics(
                header: true,
                child: Text(step.title, style: AppText.title(context)),
              ),
              const SizedBox(height: Gap.s16),
              Text(
                step.body,
                style: AppText.verse(
                  context,
                  size: 20,
                ).copyWith(color: context.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
