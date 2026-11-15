import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/country_configuration.dart';
import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// LearnTZ Unified Welcome & Home Landing Page
/// Streamlined, uncrowded landing page designed to fit cleanly on screen.
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

            // SECTION G — CALL TO ACTION (CTA BANNER)
            _LandingCtaBanner(
              selectedCountry: selectedCountry,
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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LearnTzColors.neutral200)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 36 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: _buildHeroCopy(context),
        ),
      ),
    );
  }

  Widget _buildHeroCopy(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prominent Official Brand Logo (Properly Aligned & Centered)
        Center(
          child: Semantics(
            label: selectedCountry.productName,
            child: AppBrandLogo(
              key: const Key('hero-official-brand-logo'),
              height: isDesktop ? 76 : 48,
              productName: selectedCountry.productName,
              countryBadge: selectedCountry.countryCode,
              onTap: () => context.go(AppRoutes.welcome),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Localized headline text
        Text(
          l10n.welcomeHeadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 18 : 15,
            fontWeight: FontWeight.w700,
            color: LearnTzColors.secondary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),

        // Supporting Text
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'A smarter way to learn, practise, prepare for examinations and achieve your academic goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              height: 1.45,
              color: LearnTzColors.neutral700,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            l10n.welcomeDescription(selectedCountry.productName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: LearnTzColors.neutral500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Primary and Secondary CTAs
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Trust strip
        Wrap(
          alignment: WrapAlignment.center,
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
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: LearnTzColors.neutral700,
          ),
        ),
      ],
    );
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: isDesktop ? 24 : 16,
      ),
      decoration: const BoxDecoration(
        color: LearnTzColors.primary,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
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
              const SizedBox(height: 10),
              Text(
                'YOUR CHILD\'S LEARNING JOURNEY STARTS HERE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 22 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Empower your child with curriculum-aligned lessons, assessments, and academic confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 12,
                  color: const Color(0xFFE2E8F0),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const Key('landing-cta-register-parent-btn'),
                    onPressed: () => context.go(AppRoutes.onboardingRegister),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('REGISTER AS A PARENT'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LearnTzColors.accent,
                      foregroundColor: LearnTzColors.neutral900,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
