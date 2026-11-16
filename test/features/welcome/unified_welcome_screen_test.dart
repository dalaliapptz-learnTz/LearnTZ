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

        // 2. Hero Section (Image-Only Official Logo, "Learn Anywhere, Anytime.")
        expect(
          find.byKey(const Key('hero-official-brand-logo')),
          findsOneWidget,
        );
        expect(find.text('Learn Anywhere, Anytime.'), findsWidgets);

        // 3. Four Core Learning Feature Cards (2x2 on mobile)
        expect(find.text('National Syllabi Coverage'), findsOneWidget);
        expect(find.text('Interactive Practice'), findsOneWidget);
        expect(find.text('Examination Preparation'), findsOneWidget);
        expect(find.text('Learning Progress & Analytics'), findsOneWidget);
        expect(find.text('Explore Syllabi →'), findsOneWidget);
        expect(find.text('Start Practice →'), findsOneWidget);
        expect(find.text('View Exam Centre →'), findsOneWidget);
        expect(find.text('See Analytics →'), findsOneWidget);

        // 4. Call to Action Banner
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
          expect(find.text('National Syllabi Coverage'), findsOneWidget);
          expect(find.text('PARENT ONBOARDING'), findsOneWidget);
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
  });
}
