import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/config/country_configuration.dart';
import 'package:learntz/core/state/app_providers.dart';
import 'package:learntz/features/welcome/welcome_screen.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

class _TestCountryNotifier extends SelectedCountryNotifier {
  _TestCountryNotifier(this._country);
  final CountryConfiguration _country;

  @override
  CountryConfiguration build() => _country;
}

Widget _buildTestApp({CountryConfiguration? country}) {
  return ProviderScope(
    overrides: [
      if (country != null)
        selectedCountryProvider.overrideWith(
          () => _TestCountryNotifier(country),
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
}

void main() {
  group('LearnTZ Enterprise Home Page UI/UX Implementation', () {
    testWidgets(
      'renders enterprise landing page with all core sections and typography',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 1. Header Navigation
        expect(find.byKey(const Key('header-brand-logo-btn')), findsOneWidget);
        expect(find.byKey(const ValueKey('nav-/country')), findsOneWidget);
        expect(
          find.byKey(const Key('header-language-menu-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('header-notifications-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-header-sign-in-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-header-get-started-btn')),
          findsOneWidget,
        );

        // 2. Hero Section (Image-Only Official Logo, "Learn Anywhere, Anytime.", CTAs)
        expect(
          find.byKey(const Key('hero-official-brand-logo')),
          findsOneWidget,
        );
        expect(find.text('Learn Anywhere, Anytime.'), findsWidgets);
        expect(
          find.text('Learning that moves with your child.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Curriculum-aligned lessons, interactive practice and examination preparation, wherever learning happens.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-get-started-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-explore-learning-btn')),
          findsOneWidget,
        );
        expect(find.text('GET STARTED'), findsWidgets);
        expect(find.text('EXPLORE LEARNING'), findsOneWidget);

        // Four Proportional Trust Strip Indicators
        expect(find.text('National Curriculum'), findsOneWidget);
        expect(find.text('Self-Paced Learning'), findsOneWidget);
        expect(find.text('Child Device Access'), findsOneWidget);
        expect(find.text('Offline Capable'), findsOneWidget);

        // 3. Four Core Learning Feature Cards (2x2 on mobile)
        expect(find.text('National Syllabi Coverage'), findsOneWidget);
        expect(find.text('Interactive Practice'), findsOneWidget);
        expect(find.text('Examination Preparation'), findsOneWidget);
        expect(find.text('Learning Progress & Analytics'), findsOneWidget);
        expect(find.text('Explore Syllabi →'), findsOneWidget);
        expect(find.text('Start Practice →'), findsOneWidget);
        expect(find.text('View Exam Centre →'), findsOneWidget);
        expect(find.text('See Analytics →'), findsOneWidget);

        // 4. Parent & Learner Experience Section (Dual Architecture)
        expect(
          find.text('Built for Parents. Designed for Independent Learners.'),
          findsOneWidget,
        );
        expect(find.text('One Parent, Multiple Learners'), findsOneWidget);
        expect(find.text('Parents Monitor Learning Progress'), findsOneWidget);
        expect(
          find.text('Children Access on Separate Devices'),
          findsOneWidget,
        );
        expect(find.text('Progress Synchronizes Everywhere'), findsOneWidget);

        // 5. Call to Action Banner
        expect(find.text("PARENT ONBOARDING"), findsOneWidget);
        expect(
          find.text("YOUR CHILD'S LEARNING JOURNEY STARTS HERE."),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-cta-register-parent-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('landing-cta-sign-in-btn')),
          findsOneWidget,
        );
        expect(find.text('REGISTER AS A PARENT'), findsOneWidget);
        expect(find.text('PARENT SIGN IN'), findsOneWidget);

        // 6. Enterprise Footer
        expect(find.textContaining('Tanzania'), findsOneWidget);
        expect(find.textContaining('Kenya'), findsOneWidget);
        expect(find.textContaining('Uganda'), findsOneWidget);
        expect(find.textContaining('Rwanda'), findsOneWidget);
        expect(find.textContaining('Burundi'), findsOneWidget);
        expect(find.textContaining('South Sudan'), findsOneWidget);
        expect(find.byKey(const Key('footer-about-link')), findsOneWidget);
        expect(find.byKey(const Key('footer-contact-link')), findsOneWidget);
        expect(find.byKey(const Key('footer-help-link')), findsOneWidget);
        expect(find.byKey(const Key('footer-privacy-link')), findsOneWidget);
        expect(find.byKey(const Key('footer-terms-link')), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'responsive layout renders without overflow across all 7 viewports',
      (tester) async {
        final viewports = [
          const Size(320, 640), // 320px mobile
          const Size(360, 780), // 360px mobile
          const Size(390, 844), // 390px mobile
          const Size(430, 932), // 430px mobile
          const Size(768, 1024), // 768px tablet
          const Size(1024, 768), // 1024px laptop/tablet
          const Size(1440, 900), // 1440px desktop
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;

          await tester.pumpWidget(_buildTestApp());
          await tester.pumpAndSettle();

          expect(find.text('Learn Anywhere, Anytime.'), findsWidgets);
          expect(
            find.byKey(const Key('hero-official-brand-logo')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('landing-get-started-btn')),
            findsOneWidget,
          );
          expect(find.text('National Syllabi Coverage'), findsOneWidget);
          expect(
            find.text('Built for Parents. Designed for Independent Learners.'),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed at viewport: ${size.width}x${size.height}',
          );
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets('dynamically adapts to country configuration', (tester) async {
      const kenyaConfig = CountryConfiguration(
        countryCode: 'KE',
        displayName: 'Kenya',
        productName: 'LearnKE',
        primaryBrandColor: 0xFF6A1B9A,
        accentBrandColor: 0xFFEF6C00,
        currencyCode: 'KES',
        educationSystem: 'CBC Curriculum',
        supportedLanguageCodes: ['en', 'sw'],
        isDefault: false,
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(country: kenyaConfig));
      await tester.pumpAndSettle();

      expect(find.text('KE'), findsWidgets);
      expect(find.text('🇰🇪'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer legal dialogs open and close cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Test Privacy Policy dialog
      await tester.scrollUntilVisible(
        find.byKey(const Key('footer-privacy-link')),
        500,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('footer-privacy-link')));
      await tester.pumpAndSettle();
      expect(
        find.text('Privacy Policy & Child Data Protection'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy & Child Data Protection'), findsNothing);

      // Test Terms & Conditions dialog
      await tester.scrollUntilVisible(
        find.byKey(const Key('footer-terms-link')),
        500,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('footer-terms-link')));
      await tester.pumpAndSettle();
      expect(
        find.text('Terms & Conditions'),
        findsNWidgets(2),
      ); // link + dialog title
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Terms & Conditions'), findsOneWidget); // link remains
    });
  });
}
