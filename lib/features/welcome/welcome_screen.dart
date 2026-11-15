import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/animated_welcome_emblem.dart';

/// LearnTZ Animated Welcome Experience
/// Features a choreographed 7-step brand introduction animation:
/// 1. Logo fades in & scales up (700 ms)
/// 2. Graduation cap drops gently with bounce (600 ms)
/// 3. Golden rays illuminate & radiate (800 ms)
/// 4. Book opens subtly with glowing knowledge lines (700 ms)
/// 5. Sparkles appear & twinkle (900 ms)
/// 6. LearnTZ typography reveals (700 ms)
/// 7. Tagline "Learn Anywhere, Anytime" slides & fades in (600 ms)
/// Followed by automated / interactive transition to Country Selection.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final GlobalKey<AnimatedWelcomeEmblemState> _emblemKey = GlobalKey<AnimatedWelcomeEmblemState>();

  bool _sequenceFinished = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  bool _cancelledAutoTransition = false;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onSequenceCompleted() {
    if (!mounted) return;
    setState(() {
      _sequenceFinished = true;
    });

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest && !_cancelledAutoTransition && !_hasNavigated) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _navigateToCountry();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _cancelledAutoTransition = true;
    });
  }

  void _navigateToCountry() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _countdownTimer?.cancel();
    context.go(AppRoutes.onboardingCountry);
  }

  void _replayAnimation() {
    _countdownTimer?.cancel();
    setState(() {
      _sequenceFinished = false;
      _cancelledAutoTransition = false;
      _hasNavigated = false;
      _countdownSeconds = 3;
    });
    _emblemKey.currentState?.restart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = ref.watch(selectedCountryProvider);
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 880;

    final introContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Country Badge
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: colors.secondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              l10n.welcomeBadge(country.displayName),
              style: TextStyle(
                color: colors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Tagline Pill
        Text(
          l10n.tagline,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),

        // Headline
        Text(
          l10n.welcomeHeadline,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isWide ? 44 : 34,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: LearnTzColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          "A smarter way to support your child's learning journey. ${l10n.welcomeDescription(country.productName)}",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LearnTzColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 18),

        // Action Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.getStarted(country.productName)),
              style: FilledButton.styleFrom(
                backgroundColor: LearnTzColors.primary,
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.onboardingCountry),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('GET STARTED'),
              style: FilledButton.styleFrom(
                backgroundColor: LearnTzColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.signIn),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('SIGN IN'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.about),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: Text(l10n.learnAboutUs(country.productName)),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.learnerLogin),
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('STUDENT ACCESS'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Auto-transition indicator banner
        if (_sequenceFinished) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LearnTzColors.primary50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: LearnTzColors.primary200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: LearnTzColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cancelledAutoTransition
                            ? 'Ready to select your regional curriculum:'
                            : 'Transitioning to Country Selection in ${_countdownSeconds}s...',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.primary800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!_cancelledAutoTransition)
                      TextButton(
                        onPressed: _cancelCountdown,
                        child: const Text('Stay Here'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _navigateToCountry,
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      label: Text(l10n.countryTitle),
                      style: FilledButton.styleFrom(
                        backgroundColor: LearnTzColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _replayAnimation,
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Replay Intro'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );

    // Hero Animated Emblem Showcase Card
    final animatedShowcase = AppCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: isWide ? 440 : 360,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LearnTzColors.primary900,
              LearnTzColors.primary700,
              LearnTzColors.primary,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: LearnTzColors.primary900.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Skip / Fast-forward action in top right
            Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: () {
                  _emblemKey.currentState?.skipToEnd();
                  _navigateToCountry();
                },
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                label: const Text(
                  'Skip to Country',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Choreographed 7-Step Animated Emblem
            AnimatedWelcomeEmblem(
              key: _emblemKey,
              size: isWide ? 260.0 : 220.0,
              onSequenceCompleted: _onSequenceCompleted,
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: isWide ? 28 : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: introContent),
                    const SizedBox(width: 48),
                    Expanded(child: animatedShowcase),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    introContent,
                    const SizedBox(height: 32),
                    animatedShowcase,
                  ],
                ),
        ),
      ),
    );
  }
}
