import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/country_configuration.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// LearnTZ — Enterprise Public Home & Landing Page
/// Modern, responsive, mobile-first educational platform landing page.
/// Preserves single multi-country architecture, Supabase authentication,
/// and bilingual (English / Kiswahili) localization.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = ref.watch(selectedCountryProvider);
    final authEvent = ref.watch(authStateChangesProvider).asData?.value;
    final client = ref.watch(supabaseClientProvider);
    final isSignedIn =
        authEvent?.session != null || client?.auth.currentSession != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Page background #F8FAFC
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sticky, Overflow-Proof Header Navigation
            _LandingHeader(
              selectedCountry: selectedCountry,
              l10n: l10n,
              isSignedIn: isSignedIn,
            ),

            // 2. Uncluttered, Centered Hero Section with Image-Only Animated Logo
            const _LandingHeroSection(),

            // 3. Four Core Learning Feature Cards (Mobile: 2x2, Tablet: 2x2, Desktop: 4 cols)
            _LandingFeaturesSection(
              selectedCountry: selectedCountry,
              l10n: l10n,
            ),

            // 4. Conversion Call-to-Action Banner
            _LandingCtaBanner(selectedCountry: selectedCountry, l10n: l10n),
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
    required this.isSignedIn,
  });

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 380;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : (isNarrow ? 10 : 16),
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Section: Official LearnTZ Logo + Dynamic Active-Country Badge (Click -> '/')
            Semantics(
              label: '${selectedCountry.productName} Home',
              child: InkWell(
                key: const Key('header-brand-logo-btn'),
                onTap: () => context.go(AppRoutes.welcome),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/branding/learntz_logo.png',
                        height: isDesktop ? 36 : (isNarrow ? 26 : 30),
                        width: (isDesktop ? 36 : (isNarrow ? 26 : 30)) * 1.17,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: isDesktop ? 36 : 28,
                          width: isDesktop ? 36 : 28,
                          decoration: BoxDecoration(
                            color: LearnTzColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      if (isDesktop || width >= 600) ...[
                        const SizedBox(width: 8),
                        Text(
                          selectedCountry.productName,
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Dynamic Active Country Badge (Flag + Code)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LearnTzColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LearnTzColors.primary200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countryFlag(selectedCountry.countryCode),
                              style: TextStyle(fontSize: isDesktop ? 12 : 11),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              selectedCountry.countryCode,
                              style: TextStyle(
                                fontSize: isDesktop ? 11 : 10,
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right Section: Country Selector | Language Selector | Notifications | Auth State
            Expanded(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Text(l10n.navigationAbout),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Country Selector (Opens SelectCountryScreen)
                    InkWell(
                      key: const ValueKey('nav-/country'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.go(AppRoutes.country),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 10 : (isNarrow ? 5 : 7),
                          vertical: isDesktop ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: LearnTzColors.neutral100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countryFlag(selectedCountry.countryCode),
                              style: TextStyle(fontSize: isDesktop ? 13 : 11),
                            ),
                            const SizedBox(width: 4),
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
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: LearnTzColors.neutral600,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 3 : 6),

                    // Language Selector (Globe icon, supports English & Kiswahili)
                    PopupMenuButton<Locale>(
                      key: const Key('header-language-menu-btn'),
                      tooltip: l10n.language,
                      icon: Icon(
                        Icons.language_rounded,
                        size: isDesktop ? 20 : 18,
                        color: LearnTzColors.neutral700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onSelected: ref
                          .read(appLocaleProvider.notifier)
                          .setLocale,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                        PopupMenuItem(
                          value: Locale('sw'),
                          child: Text('Kiswahili'),
                        ),
                      ],
                    ),
                    SizedBox(width: isNarrow ? 3 : 6),

                    // Notifications Icon (Connected to existing notification centre)
                    IconButton(
                      key: const Key('header-notifications-btn'),
                      tooltip: 'Notifications',
                      icon: Icon(
                        Icons.notifications_outlined,
                        size: isDesktop ? 20 : 18,
                        color: LearnTzColors.neutral700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => context.go(AppRoutes.notifications),
                    ),
                    SizedBox(width: isNarrow ? 4 : 8),

                    // Authentication State Driven Actions
                    if (isSignedIn) ...[
                      IconButton(
                        key: const ValueKey('account-action'),
                        tooltip: l10n.accountTitle,
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: LearnTzColors.primary,
                        ),
                        onPressed: () => context.go(AppRoutes.account),
                      ),
                    ] else ...[
                      // Sign In Button
                      SizedBox(
                        height: isDesktop ? 36 : 30,
                        child: OutlinedButton(
                          key: const Key('landing-header-sign-in-btn'),
                          onPressed: () => context.go(AppRoutes.signIn),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            visualDensity: const VisualDensity(
                              horizontal: -3,
                              vertical: -3,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: LearnTzColors.primary,
                            side: const BorderSide(
                              color: LearnTzColors.primary,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 14 : (isNarrow ? 6 : 10),
                              vertical: isDesktop ? 8 : 4,
                            ),
                            textStyle: TextStyle(
                              fontSize: isDesktop ? 13 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(l10n.signInAction),
                        ),
                      ),
                      SizedBox(width: isNarrow ? 4 : 8),

                      // Get Started Button
                      SizedBox(
                        height: isDesktop ? 36 : 30,
                        child: FilledButton(
                          key: const Key('landing-header-get-started-btn'),
                          onPressed: () =>
                              context.go(AppRoutes.onboardingCountry),
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            visualDensity: const VisualDensity(
                              horizontal: -3,
                              vertical: -3,
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                    ],
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
  const _LandingHeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 360;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : (isNarrow ? 14 : 20),
        vertical: isDesktop ? 48 : 30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Prominent Official Brand Logo Only (Smooth entrance animation, NO words, NO TZ badge)
              _AnimatedHeroLogo(isDesktop: isDesktop),
              SizedBox(height: isDesktop ? 24 : 16),

              // Main Headline: "Learn Anywhere, Anytime."
              Text(
                'Learn Anywhere, Anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 38 : (isNarrow ? 22 : 28),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.18,
                  color: LearnTzColors.primary, // Deep Academic Blue #0F4C81
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth, lightweight entrance animation for the hero official brand logo.
/// Displays the logo image ONLY (no text "LearnTZ", no country badge).
class _AnimatedHeroLogo extends StatefulWidget {
  const _AnimatedHeroLogo({required this.isDesktop});

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
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoHeight = widget.isDesktop ? 88.0 : 60.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: Semantics(
        label: 'LearnTZ Official Logo',
        child: InkWell(
          key: const Key('hero-official-brand-logo'),
          onTap: () => context.go(AppRoutes.welcome),
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/branding/learntz_logo.png',
            height: logoHeight,
            width: logoHeight * 1.17,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: logoHeight,
              width: logoHeight,
              decoration: BoxDecoration(
                color: LearnTzColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: logoHeight * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. FOUR CORE LEARNING FEATURE CARDS
// Responsive Grid: Mobile: 2x2, Tablet: 2x2, Desktop: 4 Columns
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
    final isNarrow = width < 360;
    final isSwahili = Localizations.localeOf(context).languageCode == 'sw';

    final cards = [
      _FeatureCardData(
        icon: Icons.menu_book_rounded,
        iconColor: LearnTzColors.primary,
        iconBgColor: LearnTzColors.primary50,
        badge: isSwahili ? 'Mtaala wa Taifa' : 'Curriculum Aligned',
        title: isSwahili ? 'Mitaala ya Kitaifa' : 'National Syllabi Coverage',
        description: isSwahili
            ? 'Ujifunzaji unaozingatia mitaala ya kitaifa katika nchi zote zinazoungwa mkono.'
            : 'Curriculum-aligned learning across supported countries.',
        actionLabel: isSwahili ? 'Tazama Mitaala →' : 'Explore Syllabi →',
        route: AppRoutes.curriculumExplorer,
      ),
      _FeatureCardData(
        icon: Icons.quiz_rounded,
        iconColor: LearnTzColors.secondary,
        iconBgColor: LearnTzColors.secondary50,
        badge: isSwahili ? 'Mazoezi Shirikishi' : 'Active Practice',
        title: isSwahili ? 'Mazoezi Shirikishi' : 'Interactive Practice',
        description: isSwahili
            ? 'Maswali, mazoezi na shughuli za kuvutia za kujifunzia.'
            : 'Exercises, questions and engaging learning activities.',
        actionLabel: isSwahili ? 'Anza Mazoezi →' : 'Start Practice →',
        route: AppRoutes.revisionCentre,
      ),
      _FeatureCardData(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: LearnTzColors.accent,
        iconBgColor: LearnTzColors.accent50,
        badge: isSwahili ? 'Mitihani ya Taifa' : 'Exam Preparation',
        title: isSwahili ? 'Maandalizi ya Mitihani' : 'Examination Preparation',
        description: isSwahili
            ? 'Marudio, mitihani ya majaribio na maandalizi ya tathmini.'
            : 'Revision, mock examinations and assessment preparation.',
        actionLabel: isSwahili ? 'Kituo cha Mitihani →' : 'View Exam Centre →',
        route: AppRoutes.examCentre,
      ),
      _FeatureCardData(
        icon: Icons.insights_rounded,
        iconColor: const Color(0xFF0D9488),
        iconBgColor: const Color(0xFFCCFBF1),
        badge: isSwahili ? 'Usimamizi wa Mzazi' : 'Parent Oversight',
        title: isSwahili
            ? 'Takwimu za Maendeleo'
            : 'Learning Progress & Analytics',
        description: isSwahili
            ? 'Ufuatiliaji wa maendeleo, viashiria vya umahiri na mapendekezo ya masomo.'
            : 'Performance tracking, mastery indicators and learning recommendations.',
        actionLabel: isSwahili ? 'Tazama Takwimu →' : 'See Analytics →',
        route: AppRoutes.parentDashboard,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : (isNarrow ? 12 : 18),
        vertical: isDesktop ? 48 : 32,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Header Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: LearnTzColors.primary50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LearnTzColors.primary200),
                ),
                child: Text(
                  isSwahili
                      ? 'MFUMO KAMILI WA MAFUNZO'
                      : 'COMPREHENSIVE LEARNING ECOSYSTEM',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: LearnTzColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? 'Kila Kitu Anachohitaji Mtoto Wako Kufanikiwa'
                    : 'Everything Your Child Needs To Excel',
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
                child: Text(
                  isSwahili
                      ? 'Nyanja nne kuu zinazomwezesha mwanafunzi kuanzia msingi wa darasani hadi kufaulu mitihani ya kitaifa.'
                      : 'Four core pillars empowering African learners from classroom fundamentals to competitive national examinations.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearnTzColors.neutral600,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 32 : 20),

              // Responsive Feature Grid: Desktop = 4 Columns, Mobile & Tablet = 2x2 Grid
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(data: cards[i], isCompact: false),
                      ),
                    ],
                  ],
                )
              else
                // 2x2 Grid for Mobile and Tablet
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FeatureCard(data: cards[0], isCompact: true),
                        ),
                        SizedBox(width: isNarrow ? 8 : 12),
                        Expanded(
                          child: _FeatureCard(data: cards[1], isCompact: true),
                        ),
                      ],
                    ),
                    SizedBox(height: isNarrow ? 8 : 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FeatureCard(data: cards[2], isCompact: true),
                        ),
                        SizedBox(width: isNarrow ? 8 : 12),
                        Expanded(
                          child: _FeatureCard(data: cards[3], isCompact: true),
                        ),
                      ],
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

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.data, required this.isCompact});

  final _FeatureCardData data;
  final bool isCompact;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isCompact = widget.isCompact;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showBadge = !isCompact || screenWidth >= 380;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? data.iconColor.withValues(alpha: 0.6)
                : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: data.iconColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(data.route),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.all(
                isCompact ? (screenWidth < 360 ? 10 : 12) : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: isCompact ? 32 : 38,
                        height: isCompact ? 32 : 38,
                        decoration: BoxDecoration(
                          color: data.iconBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          data.icon,
                          color: data.iconColor,
                          size: isCompact ? 18 : 20,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: LearnTzColors.neutral100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: LearnTzColors.neutral700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isCompact ? 10 : 14),
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      color: LearnTzColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.description,
                    maxLines: isCompact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: LearnTzColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 14),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.actionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
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
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. CONVERSION CALL-TO-ACTION BANNER
// ============================================================================
class _LandingCtaBanner extends StatelessWidget {
  const _LandingCtaBanner({required this.selectedCountry, required this.l10n});

  final CountryConfiguration selectedCountry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isNarrow = width < 360;
    final isSwahili = Localizations.localeOf(context).languageCode == 'sw';

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : (isNarrow ? 12 : 16),
          vertical: isDesktop ? 40 : 28,
        ),
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : (isNarrow ? 16 : 24),
                vertical: isDesktop ? 40 : 28,
              ),
              decoration: BoxDecoration(
                color: LearnTzColors.primary, // Deep Academic Blue #0F4C81
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: LearnTzColors.primary.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Badge: "PARENT ONBOARDING" in Kilimanjaro Gold #F59E0B
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LearnTzColors.accent.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LearnTzColors.accent, width: 1.2),
                    ),
                    child: Text(
                      isSwahili ? 'USAJILI WA MZAZI' : 'PARENT ONBOARDING',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: LearnTzColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Heading
                  Text(
                    isSwahili
                        ? 'SAFARI YA MASOMO YA MTOTO WAKO INAANZIA HAPA.'
                        : 'YOUR CHILD\'S LEARNING JOURNEY STARTS HERE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDesktop ? 25 : (isNarrow ? 17 : 20),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      isSwahili
                          ? 'Fungua akaunti ya mzazi, ongeza watoto wako, na ufungue masomo yote yanayozingatia mtaala kamili.'
                          : 'Set up your parent account, add your children, and unlock complete curriculum-aligned learning.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE2E8F0),
                        height: 1.45,
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 26 : 20),

                  // Dual Buttons: REGISTER AS A PARENT + PARENT SIGN IN
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        key: const Key('landing-cta-register-parent-btn'),
                        onPressed: () => context.go(AppRoutes.onboardingCountry),
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: Text(
                          isSwahili
                              ? 'JISAJILI KAMA MZAZI'
                              : 'REGISTER AS A PARENT',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              LearnTzColors.secondary, // Savannah Green #15803D
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 18,
                            vertical: isDesktop ? 14 : 12,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('landing-cta-sign-in-btn'),
                        onPressed: () => context.go(AppRoutes.signIn),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: Text(
                          isSwahili ? 'INGIA KAMA MZAZI' : 'PARENT SIGN IN',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 18,
                            vertical: isDesktop ? 14 : 12,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
