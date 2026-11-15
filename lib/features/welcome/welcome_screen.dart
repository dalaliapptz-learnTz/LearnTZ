import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/country_configuration.dart';
import '../../core/config/country_providers.dart';
import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// LearnTZ Unified Welcome & Home Landing Page
/// Combines the brand introduction, value propositions, multi-country education,
/// and primary conversion flows into a single, fast-loading, professional screen.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = ref.watch(selectedCountryProvider);
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION A — HEADER
            _LandingHeader(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION B — HERO SECTION
            _LandingHeroSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION C — WHAT LEARNTZ OFFERS
            _LandingFeaturesSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION D — HOW IT WORKS
            _LandingHowItWorksSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION E — EXAMINATION PREPARATION
            _LandingExamPrepSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION F — MULTI-COUNTRY EDUCATION
            _LandingMultiCountrySection(
              selectedCountry: selectedCountry,
              countriesAsync: countriesAsync,
              l10n: l10n,
            ),

            // SECTION G — CALL TO ACTION (CTA BANNER)
            _LandingCtaBanner(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // SECTION H — FOOTER
            _LandingFooter(
              selectedCountry: selectedCountry,
              countriesAsync: countriesAsync,
              l10n: l10n,
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
// SECTION A — HEADER
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
    final isTablet = width >= 600 && width < 900;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 8,
        vertical: isDesktop ? 12 : 6,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Group: Static Brand Logo & Optional Desktop Tagline
            Row(
              key: const Key('header-left-group'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: selectedCountry.productName,
                  child: AppBrandLogo(
                    height: isDesktop ? 38 : 26,
                    productName: (isDesktop || isTablet) ? selectedCountry.productName : null,
                    showTagline: false,
                    countryBadge: (isDesktop || isTablet) ? selectedCountry.countryCode : null,
                    onTap: () => context.go(AppRoutes.welcome),
                  ),
                ),
                if (isDesktop) ...[
                  Container(
                    height: 20,
                    width: 1,
                    color: LearnTzColors.neutral300,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const Text(
                    'Learn Anywhere, Anytime.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LearnTzColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),

            // Right Group: Navigation, Country, Language, Sign In, Get Started
            Row(
              key: const Key('header-right-group'),
              mainAxisSize: MainAxisSize.min,
              children: [
                // Desktop navigation links
                if (isDesktop) ...[
                  TextButton(
                    key: const ValueKey('nav-/about'),
                    onPressed: () => context.go(AppRoutes.about),
                    child: Text(l10n.navigationAbout),
                  ),
                  TextButton(
                    key: const ValueKey('nav-/help'),
                    onPressed: () => context.go(AppRoutes.help),
                    child: Text(l10n.navigationHelp),
                  ),
                  const SizedBox(width: 4),
                ],

                // Country Selector Pill
                InkWell(
                  key: const ValueKey('nav-/country'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go(AppRoutes.country),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 4,
                      vertical: isDesktop ? 6 : 2,
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
                        const SizedBox(width: 2),
                        Text(
                          selectedCountry.countryCode,
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
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
                SizedBox(width: isDesktop ? 8 : 2),

                // Language Selector
                PopupMenuButton<Locale>(
                  tooltip: l10n.language,
                  icon: Icon(Icons.language, size: isDesktop ? 20 : 16, color: LearnTzColors.neutral700),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onSelected: ref.read(appLocaleProvider.notifier).setLocale,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: Locale('en'), child: Text('English')),
                    PopupMenuItem(value: Locale('sw'), child: Text('Kiswahili')),
                  ],
                ),
                SizedBox(width: isDesktop ? 8 : 2),

                // Sign In Button
                SizedBox(
                  height: isDesktop ? 36 : 28,
                  child: OutlinedButton(
                    key: const Key('landing-header-sign-in-btn'),
                    onPressed: () => context.go(AppRoutes.signIn),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: LearnTzColors.primary,
                      side: const BorderSide(color: LearnTzColors.primary),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 14 : 5,
                        vertical: isDesktop ? 6 : 0,
                      ),
                      textStyle: TextStyle(
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.signInAction),
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 2),

                // Get Started Button
                SizedBox(
                  height: isDesktop ? 36 : 28,
                  child: FilledButton(
                    key: const Key('landing-header-get-started-btn'),
                    onPressed: () => context.go(AppRoutes.onboardingCountry),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: LearnTzColors.secondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : 6,
                        vertical: isDesktop ? 6 : 0,
                      ),
                      textStyle: TextStyle(
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Get Started'),
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
// SECTION B — HERO SECTION
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LearnTzColors.neutral200)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isDesktop ? 56 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildHeroCopy(context),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 5,
                      child: _buildHeroIllustration(context),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCopy(context),
                    const SizedBox(height: 32),
                    _buildHeroIllustration(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Badge & Country Tag
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LearnTzColors.primary50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LearnTzColors.primary200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 14, color: LearnTzColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.welcomeBadge(selectedCountry.displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: LearnTzColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: LearnTzColors.secondary50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LearnTzColors.secondary300),
              ),
              child: Text(
                l10n.tagline,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Main Heading
        const Text(
          'LEARN ANYWHERE, ANYTIME.',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: LearnTzColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        // Localized headline text
        Text(
          l10n.welcomeHeadline,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LearnTzColors.secondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),

        // Supporting Text
        const Text(
          'A smarter way to learn, practise, prepare for examinations and achieve your academic goals.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: LearnTzColors.neutral700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.welcomeDescription(selectedCountry.productName),
          style: const TextStyle(
            fontSize: 13,
            color: LearnTzColors.neutral500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Primary and Secondary CTAs
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('landing-get-started-btn'),
              onPressed: () => context.go(AppRoutes.onboardingCountry),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('GET STARTED'),
              style: FilledButton.styleFrom(
                backgroundColor: LearnTzColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('landing-explore-learning-btn'),
              onPressed: () => context.go(AppRoutes.curriculumExplorer),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('EXPLORE LEARNING'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LearnTzColors.primary,
                side: const BorderSide(color: LearnTzColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Trust strip
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: const [
            _TrustItem(icon: Icons.check_circle_outline, text: 'National Curricula Aligned'),
            _TrustItem(icon: Icons.offline_bolt_outlined, text: 'Works Offline'),
            _TrustItem(icon: Icons.devices_outlined, text: 'Child Device Access'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroIllustration(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF1E3A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: LearnTzColors.primary.withAlpha(50),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium, size: 14, color: LearnTzColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      selectedCountry.displayName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.school_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.homeTitle(selectedCountry.productName),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.homeDescription(selectedCountry.productName),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFE2E8F0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroBadge(label: '🇹🇿 TIE Tanzania'),
              _HeroBadge(label: '🇰🇪 KICD Kenya'),
              _HeroBadge(label: '🇺🇬 NCDC Uganda'),
              _HeroBadge(label: '🇷🇼 REB Rwanda'),
              _HeroBadge(label: '🇧🇮 Burundi'),
              _HeroBadge(label: '🇸🇸 South Sudan'),
            ],
          ),
        ],
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
        Icon(icon, size: 16, color: LearnTzColors.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LearnTzColors.neutral700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION C — WHAT LEARNTZ OFFERS
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
    final features = [
      const _FeatureItem(
        icon: Icons.psychology_outlined,
        iconBg: LearnTzColors.primary50,
        iconFg: LearnTzColors.primary,
        title: 'Personalised Learning',
        description: 'Adaptive study paths that adjust to each learner\'s pace, topic strengths, and syllabus requirements.',
        route: AppRoutes.curriculumExplorer,
        actionLabel: 'Explore Syllabi',
      ),
      const _FeatureItem(
        icon: Icons.menu_book_outlined,
        iconBg: LearnTzColors.secondary50,
        iconFg: LearnTzColors.secondary,
        title: 'Interactive Lessons',
        description: 'Rich multimedia lessons broken into bite-sized concepts with practical examples and checkpoint quizzes.',
        route: AppRoutes.learn,
        actionLabel: 'Browse Lessons',
      ),
      const _FeatureItem(
        icon: Icons.fact_check_outlined,
        iconBg: Color(0xFFFEF3C7),
        iconFg: Color(0xFFD97706),
        title: 'Practice and Assessments',
        description: 'Thousands of topical practice questions with instant scoring, step-by-step guidance, and mastery tracking.',
        route: AppRoutes.revisionCentre,
        actionLabel: 'Try Practice Quizzes',
      ),
      const _FeatureItem(
        icon: Icons.style_outlined,
        iconBg: Color(0xFFEFF6FF),
        iconFg: Color(0xFF2563EB),
        title: 'Revision Centre',
        description: 'Digital flashcards, concise topic revision summaries, formula sheets, and offline downloadable guides.',
        route: AppRoutes.revisionCentre,
        actionLabel: 'Open Revision Hub',
      ),
      const _FeatureItem(
        icon: Icons.timer_outlined,
        iconBg: Color(0xFFFDF2F8),
        iconFg: Color(0xFFDB2777),
        title: 'Mock Examinations',
        description: 'National and regional timed mock examination simulations with Mock Intelligence scoring and percentiles.',
        route: AppRoutes.examCentre,
        actionLabel: 'View Exam Repositories',
      ),
      const _FeatureItem(
        icon: Icons.groups_outlined,
        iconBg: Color(0xFFF0FDF4),
        iconFg: Color(0xFF16A34A),
        title: 'Learning Communities',
        description: 'Safe, moderated peer study communities, subject discussions, and weekly academic challenges.',
        route: AppRoutes.communities,
        actionLabel: 'Join Study Circles',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'WHAT LEARNTZ OFFERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: LearnTzColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete Academic Toolkit for Every Learner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: LearnTzColors.neutral900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: const Text(
                  'Everything learners need to master concepts, revise efficiently, and gain the confidence required to excel in national examinations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: LearnTzColors.neutral600, height: 1.4),
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 220,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final item = features[index];
                      return AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, color: item.iconFg, size: 24),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                item.description,
                                style: const TextStyle(fontSize: 12, color: LearnTzColors.neutral600, height: 1.35),
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go(item.route),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.actionLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: item.iconFg,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 14, color: item.iconFg),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.description,
    required this.route,
    required this.actionLabel,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String description;
  final String route;
  final String actionLabel;
}

// ============================================================================
// SECTION D — HOW IT WORKS
// ============================================================================
class _LandingHowItWorksSection extends StatelessWidget {
  const _LandingHowItWorksSection({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _StepData(
        stepNumber: '1',
        title: 'Parent creates account',
        description: 'Quick sign-up with phone or email verification in under two minutes.',
      ),
      const _StepData(
        stepNumber: '2',
        title: 'Parent adds child',
        description: 'Select country curriculum, education level, and class stream.',
      ),
      const _StepData(
        stepNumber: '3',
        title: 'Learner accesses profile',
        description: 'Child mode on parent device or independent login with Student ID & PIN.',
      ),
      const _StepData(
        stepNumber: '4',
        title: 'Learner studies and practises',
        description: 'Interactive syllabus lessons, topical drills, and mock exams.',
      ),
      const _StepData(
        stepNumber: '5',
        title: 'LearnTZ tracks progress',
        description: 'Automated skill diagnostics, mastery scoring, and revision advice.',
      ),
      const _StepData(
        stepNumber: '6',
        title: 'Parent monitors improvement',
        description: 'Live parent dashboard tracking subject trends, scores, and study streaks.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: LearnTzColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A simple learning journey for parents and learners',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: LearnTzColors.neutral900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final s = steps[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: LearnTzColors.neutral50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LearnTzColors.neutral200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: LearnTzColors.primary,
                              child: Text(
                                s.stepNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: LearnTzColors.neutral900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: LearnTzColors.neutral600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  final String stepNumber;
  final String title;
  final String description;
}

// ============================================================================
// SECTION E — EXAMINATION PREPARATION
// ============================================================================
class _LandingExamPrepSection extends StatelessWidget {
  const _LandingExamPrepSection({
    required this.selectedCountry,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: AppCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LearnTzColors.secondary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_outlined, color: LearnTzColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXAMINATION PREPARATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: LearnTzColors.secondary,
                            ),
                          ),
                          Text(
                            'Rigorous Preparation for Real National Exams',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'LearnTZ features a verified repository of past national examinations, district mock papers, and timed simulations designed to build speed and accuracy:',
                  style: TextStyle(fontSize: 14, color: LearnTzColors.neutral700, height: 1.4),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: const [
                    _ExamFeaturePill(title: 'Past Examination Papers', desc: 'Real papers categorized by year & subject'),
                    _ExamFeaturePill(title: 'District & Regional Mocks', desc: 'Authentic school district mock papers'),
                    _ExamFeaturePill(title: 'Standardized Mock Exams', desc: 'Full-syllabus mock tests matching exam blueprints'),
                    _ExamFeaturePill(title: 'Timed Practice Runner', desc: 'Realistic countdown timers and pacing guides'),
                    _ExamFeaturePill(title: 'Performance Analytics', desc: 'Instant score breakdown and topic strength heatmaps'),
                    _ExamFeaturePill(title: 'Personalised Revision', desc: 'Targeted study focus on incorrectly answered items'),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.examCentre),
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: const Text('Open National Examination Centre'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LearnTzColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

class _ExamFeaturePill extends StatelessWidget {
  const _ExamFeaturePill({required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LearnTzColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LearnTzColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: LearnTzColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: LearnTzColors.neutral600)),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION F — MULTI-COUNTRY EDUCATION
// ============================================================================
class _LandingMultiCountrySection extends ConsumerWidget {
  const _LandingMultiCountrySection({
    required this.selectedCountry,
    required this.countriesAsync,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AsyncValue<List<CountryConfiguration>> countriesAsync;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'ONE APPLICATION • MULTIPLE AFRICAN NATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: LearnTzColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'African-Ready Multi-Curriculum Engine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: LearnTzColors.neutral900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: const Text(
                  'LearnTZ dynamically configures its curriculum explorer, lessons, exam repositories, and languages according to each national education system.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: LearnTzColors.neutral600, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),

              // Country cards rendered dynamically from configuration engine
              countriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _buildFallbackCountryGrid(context, ref),
                data: (countries) {
                  if (countries.isEmpty) {
                    return _buildFallbackCountryGrid(context, ref);
                  }
                  return _buildCountryGrid(context, ref, countries);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryGrid(
    BuildContext context,
    WidgetRef ref,
    List<CountryConfiguration> countries,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final c = countries[index];
            final isSelected = c.countryCode == selectedCountry.countryCode;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ref.read(selectedCountryProvider.notifier).selectCountry(c);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? LearnTzColors.primary50 : LearnTzColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? LearnTzColors.primary : LearnTzColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_countryFlag(c.countryCode), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? LearnTzColors.primary : LearnTzColors.neutral900,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const AppBadge(
                            label: 'ACTIVE',
                            variant: AppBadgeVariant.primary,
                            size: AppBadgeSize.sm,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.educationSystem.isNotEmpty ? c.educationSystem : '${c.displayName} Curriculum',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: LearnTzColors.neutral600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFallbackCountryGrid(BuildContext context, WidgetRef ref) {
    const fallbackList = [
      tanzaniaConfiguration,
      CountryConfiguration(
        countryCode: 'KE',
        displayName: 'Kenya',
        productName: 'LearnKE',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'KES',
        educationSystem: 'Kenya CBC (KICD)',
        supportedLanguageCodes: ['en', 'sw'],
        isDefault: false,
      ),
      CountryConfiguration(
        countryCode: 'UG',
        displayName: 'Uganda',
        productName: 'LearnUG',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'UGX',
        educationSystem: 'Uganda NCDC Curriculum',
        supportedLanguageCodes: ['en'],
        isDefault: false,
      ),
      CountryConfiguration(
        countryCode: 'RW',
        displayName: 'Rwanda',
        productName: 'LearnRW',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'RWF',
        educationSystem: 'Rwanda Basic Education Board (REB)',
        supportedLanguageCodes: ['en', 'fr'],
        isDefault: false,
      ),
      CountryConfiguration(
        countryCode: 'BI',
        displayName: 'Burundi',
        productName: 'LearnBI',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'BIF',
        educationSystem: 'Burundi Ministère de l\'Éducation',
        supportedLanguageCodes: ['fr', 'rn'],
        isDefault: false,
      ),
      CountryConfiguration(
        countryCode: 'SS',
        displayName: 'South Sudan',
        productName: 'LearnSS',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'SSP',
        educationSystem: 'Ministry of General Education',
        supportedLanguageCodes: ['en'],
        isDefault: false,
      ),
    ];
    return _buildCountryGrid(context, ref, fallbackList);
  }
}

// ============================================================================
// SECTION G — CALL TO ACTION (CTA BANNER)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: const BoxDecoration(
        color: LearnTzColors.primary,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'JOIN THOUSANDS OF AMBITIOUS LEARNERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'YOUR CHILD\'S LEARNING JOURNEY STARTS HERE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Empower your child with curriculum-aligned lessons, topical past-paper assessments, and the confidence to succeed in school and national exams.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFFE2E8F0), height: 1.4),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const Key('landing-cta-register-parent-btn'),
                    onPressed: () => context.go(AppRoutes.onboardingRegister),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('REGISTER AS A PARENT'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LearnTzColors.accent,
                      foregroundColor: LearnTzColors.neutral900,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('landing-cta-sign-in-btn'),
                    onPressed: () => context.go(AppRoutes.signIn),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('SIGN IN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
// SECTION H — FOOTER
// ============================================================================
class _LandingFooter extends StatelessWidget {
  const _LandingFooter({
    required this.selectedCountry,
    required this.countriesAsync,
    required this.l10n,
  });

  final CountryConfiguration selectedCountry;
  final AsyncValue<List<CountryConfiguration>> countriesAsync;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Container(
      color: const Color(0xFF0B132B),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 36,
                runSpacing: 24,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Brand & Tagline
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppBrandLogo(height: 34, showTagline: false),
                        SizedBox(height: 10),
                        Text(
                          'Learn Anywhere, Anytime.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Africa\'s unified digital learning platform powering academic excellence from primary through high school.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // Quick Navigation
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PLATFORM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                      const SizedBox(height: 12),
                      _FooterLink(label: 'About LearnTZ', onTap: () => context.go(AppRoutes.about)),
                      _FooterLink(label: 'Curriculum Explorer', onTap: () => context.go(AppRoutes.curriculumExplorer)),
                      _FooterLink(label: 'Examination Centre', onTap: () => context.go(AppRoutes.examCentre)),
                      _FooterLink(label: 'Student Login', onTap: () => context.go(AppRoutes.learnerLogin)),
                    ],
                  ),

                  // Help & Legal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUPPORT & LEGAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                      const SizedBox(height: 12),
                      _FooterLink(label: 'Help Centre', onTap: () => context.go(AppRoutes.help)),
                      _FooterLink(label: 'Contact', onTap: () => context.go(AppRoutes.help)),
                      _FooterLink(
                        label: 'Privacy Policy',
                        onTap: () => _showInfoDialog(context, 'Privacy Policy', 'LearnTZ strictly guards personal and learning data. Student profiles are protected with strict parental controls.'),
                      ),
                      _FooterLink(
                        label: 'Terms & Conditions',
                        onTap: () => _showInfoDialog(context, 'Terms and Conditions', 'LearnTZ provides multi-country subscription access aligned with authorized national curricula.'),
                      ),
                    ],
                  ),

                  // Supported Countries
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUPPORTED COUNTRIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                      const SizedBox(height: 12),
                      const Text('🇹🇿 Tanzania (TIE / NECTA)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      const Text('🇰🇪 Kenya (KICD / CBC)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      const Text('🇺🇬 Uganda (NCDC / UNEB)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      const Text('🇷🇼 Rwanda (REB)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      const Text('🇧🇮 Burundi • 🇸🇸 South Sudan', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} LearnTZ Educational Technologies. All rights reserved. Learn Anywhere, Anytime.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
