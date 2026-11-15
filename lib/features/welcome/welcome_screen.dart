import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/country_configuration.dart';
import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// LearnTZ — Enterprise Public Home & Landing Page
/// Premium, mobile-first educational platform interface optimized for responsive
/// performance across 320px mobile to 1440px desktop screens.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = ref.watch(selectedCountryProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Responsive Header Navigation
            _LandingHeader(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // 2. Concise Hero Section with Animated Prominent Logo
            _LandingHeroSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // 3. Four Core Learning Features Cards
            _LandingFeaturesSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // 4. Parent & Learner Experience (Dual Architecture)
            const _LandingExperienceSection(),

            // 5. Primary Registration & Sign-in Call-to-Action
            _LandingCtaBanner(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // 6. Clean Enterprise Footer
            _LandingFooter(
              selectedCountry: selectedCountry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef UnifiedLandingScreen = WelcomeScreen;

// ============================================================================
// 1. HEADER NAVIGATION
// ============================================================================
class _LandingHeader extends ConsumerWidget {
  const _LandingHeader({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 380;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : (isNarrow ? 8 : 14),
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LearnTzColors.neutral200)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prominent LearnTZ Logo (Left)
            Semantics(
              label: selectedCountry.productName,
              child: AppBrandLogo(
                height: isDesktop ? 38 : (isNarrow ? 26 : 30),
                productName: width >= 420 ? selectedCountry.productName : null,
                showTagline: false,
                countryBadge: width >= 420 ? selectedCountry.countryCode : null,
                onTap: () => context.go(AppRoutes.welcome),
              ),
            ),

            // Navigation Actions: Country, Language, Sign In, Get Started (Right)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDesktop) ...[
                      TextButton(
                        key: const ValueKey('nav-/about'),
                        onPressed: () => context.go(AppRoutes.about),
                        style: TextButton.styleFrom(
                          foregroundColor: LearnTzColors.neutral700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: Text(l10n.navigationAbout),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Country Selector
                    InkWell(
                      key: const ValueKey('nav-/country'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.go(AppRoutes.country),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 10 : (isNarrow ? 4 : 6),
                          vertical: isDesktop ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: LearnTzColors.neutral100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: LearnTzColors.neutral300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countryFlag(selectedCountry.countryCode),
                              style: TextStyle(fontSize: isDesktop ? 14 : 11),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              selectedCountry.countryCode,
                              style: TextStyle(
                                fontSize: isDesktop ? 12 : 11,
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.neutral800,
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 14, color: LearnTzColors.neutral600),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 3 : 6),

                    // Language Selector
                    PopupMenuButton<Locale>(
                      tooltip: l10n.language,
                      icon: Icon(
                        Icons.language,
                        size: isDesktop ? 20 : 18,
                        color: LearnTzColors.neutral700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onSelected: ref.read(appLocaleProvider.notifier).setLocale,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: Locale('en'), child: Text('English')),
                        PopupMenuItem(value: Locale('sw'), child: Text('Kiswahili')),
                      ],
                    ),
                    SizedBox(width: isNarrow ? 3 : 8),

                    // Sign In Button
                    SizedBox(
                      height: isDesktop ? 38 : 32,
                      child: OutlinedButton(
                        key: const Key('landing-header-sign-in-btn'),
                        onPressed: () => context.go(AppRoutes.signIn),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: LearnTzColors.primary,
                          side: const BorderSide(color: LearnTzColors.primary),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 14 : (isNarrow ? 6 : 10),
                            vertical: isDesktop ? 8 : 4,
                          ),
                          textStyle: TextStyle(
                            fontSize: isDesktop ? 13 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(l10n.signInAction),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 3 : 8),

                    // Get Started Button
                    SizedBox(
                      height: isDesktop ? 38 : 32,
                      child: FilledButton(
                        key: const Key('landing-header-get-started-btn'),
                        onPressed: () => context.go(AppRoutes.onboardingCountry),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.zero,
                          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: LearnTzColors.secondary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 16 : (isNarrow ? 8 : 12),
                            vertical: isDesktop ? 8 : 4,
                          ),
                          textStyle: TextStyle(
                            fontSize: isDesktop ? 13 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. HERO SECTION
// ============================================================================
class _LandingHeroSection extends StatelessWidget {
  const _LandingHeroSection({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 360;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LearnTzColors.neutral200)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : (isNarrow ? 14 : 20),
        vertical: isDesktop ? 44 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Prominent Official Brand Logo with Smooth Entrance Animation
              _AnimatedHeroLogo(
                selectedCountry: selectedCountry,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 24 : 16),

              // Headline: LEARN ANYWHERE. ACHIEVE EVERYWHERE.
              Text(
                'LEARN ANYWHERE. ACHIEVE EVERYWHERE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 36 : (isNarrow ? 20 : 25),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.18,
                  color: LearnTzColors.primary,
                ),
              ),
              const SizedBox(height: 10),

              // Supporting headline: Learning that moves with your child.
              Text(
                l10n.welcomeHeadline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 19 : (isNarrow ? 14 : 16),
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.secondary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // Description: Curriculum-aligned lessons, interactive practice...
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Curriculum-aligned lessons, interactive practice and examination preparation, wherever learning happens.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 15 : (isNarrow ? 12 : 13),
                    height: 1.48,
                    color: LearnTzColors.neutral700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 28 : 22),

              // Actions: Primary GET STARTED + Secondary Explore Learning
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('landing-get-started-btn'),
                    onPressed: () => context.go(AppRoutes.onboardingCountry),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('GET STARTED'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LearnTzColors.secondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 26 : 18,
                        vertical: isDesktop ? 14 : 12,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('landing-explore-learning-btn'),
                    onPressed: () => context.go(AppRoutes.curriculumExplorer),
                    icon: const Icon(Icons.explore_outlined, size: 16),
                    label: const Text('EXPLORE LEARNING'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LearnTzColors.primary,
                      side: const BorderSide(color: LearnTzColors.primary, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 22 : 16,
                        vertical: isDesktop ? 14 : 12,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 24 : 18),

              // Capability & Trust Strip
              Wrap(
                alignment: WrapAlignment.center,
                spacing: isDesktop ? 20 : 12,
                runSpacing: 8,
                children: const [
                  _TrustItem(icon: Icons.check_circle_outline, text: 'National Curricula Aligned'),
                  _TrustItem(icon: Icons.offline_bolt_outlined, text: 'Works 100% Offline'),
                  _TrustItem(icon: Icons.devices_outlined, text: 'Independent Child Device Access'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth entrance animation for the hero official brand logo
class _AnimatedHeroLogo extends StatefulWidget {
  const _AnimatedHeroLogo({
    required this.selectedCountry,
    required this.isDesktop,
  });

  final CountryConfiguration selectedCountry;
  final bool isDesktop;

  @override
  State<_AnimatedHeroLogo> createState() => _AnimatedHeroLogoState();
}

class _AnimatedHeroLogoState extends State<_AnimatedHeroLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: widget.selectedCountry.productName,
        child: AppBrandLogo(
          key: const Key('hero-official-brand-logo'),
          height: widget.isDesktop ? 76 : 48,
          productName: widget.selectedCountry.productName,
          countryBadge: widget.selectedCountry.countryCode,
          onTap: () => context.go(AppRoutes.welcome),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: LearnTzColors.secondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: LearnTzColors.neutral700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. LEARNING FEATURES (4 FEATURE CARDS WITH ROUTES)
// ============================================================================
class _LandingFeaturesSection extends StatelessWidget {
  const _LandingFeaturesSection({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 600 && width < 1100;

    final cards = [
      _FeatureCardData(
        icon: Icons.auto_stories_rounded,
        iconColor: LearnTzColors.primary,
        iconBgColor: LearnTzColors.primary50,
        badge: 'Syllabus Aligned',
        title: 'Curriculum-Aligned Lessons',
        description:
            'Structured lessons and reading materials crafted strictly to national curriculum standards across every primary and secondary grade.',
        actionLabel: 'Explore Syllabi →',
        route: AppRoutes.curriculumExplorer,
      ),
      _FeatureCardData(
        icon: Icons.quiz_rounded,
        iconColor: LearnTzColors.secondary,
        iconBgColor: LearnTzColors.secondary50,
        badge: 'Active Recall',
        title: 'Interactive Practice',
        description:
            'Topic-by-topic quizzes, instant model solutions, and spaced-repetition flashcard decks to reinforce concept mastery.',
        actionLabel: 'Start Practice →',
        route: AppRoutes.revisionCentre,
      ),
      _FeatureCardData(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: LearnTzColors.accent,
        iconBgColor: LearnTzColors.accent50,
        badge: 'National Mocks',
        title: 'Examination Preparation',
        description:
            'Standardized past papers, regional mocks, timed examination conditions, automated marking, and diagnostic performance analytics.',
        actionLabel: 'View Exam Centre →',
        route: AppRoutes.examCentre,
      ),
      _FeatureCardData(
        icon: Icons.insights_rounded,
        iconColor: const Color(0xFF4338CA),
        iconBgColor: const Color(0xFFEEF2FF),
        badge: 'Parent Oversight',
        title: 'Learning Progress & Analytics',
        description:
            'Real-time subject mastery scores, activity streaks, topic weakness diagnostics, and personalized recommendations for every learner.',
        actionLabel: 'See Analytics →',
        route: AppRoutes.parentDashboard,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : (width < 360 ? 14 : 20),
        vertical: isDesktop ? 48 : 32,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.primary50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LearnTzColors.primary200),
                ),
                child: const Text(
                  'COMPREHENSIVE LEARNING ECOSYSTEM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: LearnTzColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything Your Child Needs To Excel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: LearnTzColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: const Text(
                  'Four core pillars empowering African learners from classroom fundamentals to competitive national examinations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: LearnTzColors.neutral600,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 32 : 24),

              // Responsive Feature Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  if (isDesktop) {
                    // 4 columns in one row
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(child: _FeatureCard(data: cards[i])),
                        ],
                      ],
                    );
                  } else if (isTablet) {
                    // 2x2 grid
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _FeatureCard(data: cards[0])),
                            const SizedBox(width: 16),
                            Expanded(child: _FeatureCard(data: cards[1])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _FeatureCard(data: cards[2])),
                            const SizedBox(width: 16),
                            Expanded(child: _FeatureCard(data: cards[3])),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // 1 column stacked
                    return Column(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _FeatureCard(data: cards[i]),
                        ],
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.badge,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String badge;
  final String title;
  final String description;
  final String actionLabel;
  final String route;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(data.route),
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        borderColor: LearnTzColors.neutral200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: data.iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 20),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LearnTzColors.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.neutral700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: LearnTzColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.description,
              style: const TextStyle(
                fontSize: 12,
                color: LearnTzColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  child: Text(
                    data.actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: data.iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. PARENT & LEARNER EXPERIENCE (DUAL ARCHITECTURE)
// ============================================================================
class _LandingExperienceSection extends StatelessWidget {
  const _LandingExperienceSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 600 && width < 1100;

    final pillars = [
      _ExperiencePillarData(
        icon: Icons.diversity_3_rounded,
        color: LearnTzColors.secondary,
        title: 'One Parent, Multiple Learners',
        description:
            'A single parent account effortlessly manages multiple children across primary and secondary grades, with instantaneous profile switching.',
      ),
      _ExperiencePillarData(
        icon: Icons.query_stats_rounded,
        color: LearnTzColors.primary,
        title: 'Parents Monitor Learning Progress',
        description:
            'Review real-time study hours, lesson completions, quiz results, and personalized diagnostic recommendations directly on the parent dashboard.',
      ),
      _ExperiencePillarData(
        icon: Icons.phonelink_setup_rounded,
        color: LearnTzColors.accent,
        title: 'Children Access on Separate Devices',
        description:
            'Learners log in independently on their own phone, tablet, or computer using a secure, easy-to-remember PIN without parent password sharing.',
      ),
      _ExperiencePillarData(
        icon: Icons.cloud_sync_rounded,
        color: const Color(0xFF0D9488),
        title: 'Progress Synchronizes Everywhere',
        description:
            'Study history, exam mock attempts, bookmarks, and offline downloads stay automatically in sync across all supported family devices.',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : (width < 360 ? 14 : 20),
        vertical: isDesktop ? 48 : 32,
      ),
      decoration: const BoxDecoration(
        color: LearnTzColors.neutral50,
        border: Border.symmetric(
          horizontal: BorderSide(color: LearnTzColors.neutral200),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.secondary50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LearnTzColors.secondary300),
                ),
                child: const Text(
                  'PARENT & LEARNER COLLABORATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: LearnTzColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built for Parents. Designed for Independent Learners.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: LearnTzColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: const Text(
                  'LearnTZ seamlessly combines comprehensive parental supervision with distraction-free student autonomy across mobile phones, tablets, and computers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: LearnTzColors.neutral600,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 32 : 24),

              // Responsive Pillars Grid
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < pillars.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: _ExperiencePillarCard(data: pillars[i])),
                    ],
                  ],
                )
              else if (isTablet)
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ExperiencePillarCard(data: pillars[0])),
                        const SizedBox(width: 16),
                        Expanded(child: _ExperiencePillarCard(data: pillars[1])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ExperiencePillarCard(data: pillars[2])),
                        const SizedBox(width: 16),
                        Expanded(child: _ExperiencePillarCard(data: pillars[3])),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < pillars.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _ExperiencePillarCard(data: pillars[i]),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperiencePillarData {
  const _ExperiencePillarData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}

class _ExperiencePillarCard extends StatelessWidget {
  const _ExperiencePillarCard({required this.data});

  final _ExperiencePillarData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      borderColor: LearnTzColors.neutral200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LearnTzColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 12,
              color: LearnTzColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. REGISTRATION & SIGN-IN CALL-TO-ACTION BANNER
// ============================================================================
class _LandingCtaBanner extends StatelessWidget {
  const _LandingCtaBanner({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : (isNarrow ? 16 : 20),
        vertical: isDesktop ? 36 : 24,
      ),
      decoration: const BoxDecoration(
        color: LearnTzColors.primary,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'JOIN THOUSANDS OF AMBITIOUS LEARNERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'YOUR CHILD\'S LEARNING JOURNEY STARTS HERE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 24 : (isNarrow ? 17 : 19),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: const Text(
                  'Empower your child with curriculum-aligned lessons, assessments, and academic confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 24 : 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const Key('landing-cta-register-parent-btn'),
                    onPressed: () => context.go(AppRoutes.onboardingCountry),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('REGISTER AS A PARENT'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LearnTzColors.accent,
                      foregroundColor: LearnTzColors.neutral900,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 22 : 16,
                        vertical: isDesktop ? 14 : 12,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('landing-cta-sign-in-btn'),
                    onPressed: () => context.go(AppRoutes.signIn),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('SIGN IN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 22 : 16,
                        vertical: isDesktop ? 14 : 12,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. CLEAN ENTERPRISE FOOTER
// ============================================================================
class _LandingFooter extends StatelessWidget {
  const _LandingFooter({required this.selectedCountry});

  final CountryConfiguration selectedCountry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: isDesktop ? 24 : 18,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: const [
                  Text('🇹🇿 Tanzania', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                  Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  Text('🇰🇪 Kenya', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                  Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  Text('🇺🇬 Uganda', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                  Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  Text('🇷🇼 Rwanda', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                  Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  Text('🇧🇮 Burundi', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                  Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  Text('🇸🇸 South Sudan', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  InkWell(
                    onTap: () => context.go(AppRoutes.about),
                    child: const Text('About LearnTZ', style: TextStyle(fontSize: 11, color: LearnTzColors.primary)),
                  ),
                  const Text('•', style: TextStyle(fontSize: 11, color: LearnTzColors.neutral400)),
                  InkWell(
                    onTap: () => context.go(AppRoutes.help),
                    child: const Text('Help & Support', style: TextStyle(fontSize: 11, color: LearnTzColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '© 2026 LearnTZ Platform. Learn Anywhere, Anytime. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: LearnTzColors.neutral500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _countryFlag(String countryCode) {
  return switch (countryCode.toUpperCase()) {
    'TZ' => '🇹🇿',
    'KE' => '🇰🇪',
    'UG' => '🇺🇬',
    'RW' => '🇷🇼',
    'BI' => '🇧🇮',
    'SS' => '🇸🇸',
    _ => '🌍',
  };
}
