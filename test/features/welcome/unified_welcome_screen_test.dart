import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/config/country_configuration.dart';
import 'package:learntz/core/design_system/components/app_brand_logo.dart';
import 'package:learntz/core/state/app_providers.dart';
import 'package:learntz/features/welcome/welcome_screen.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

class _TestCountryNotifier extends SelectedCountryNotifier {
  _TestCountryNotifier(this._country);
  final CountryConfiguration _country;

  @override
  CountryConfiguration build() => _country;
}

Widget _buildTestApp({
  CountryConfiguration? country,
}) {
  return ProviderScope(
    overrides: [
      if (country != null)
        selectedCountryProvider.overrideWith(() => _TestCountryNotifier(country)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
}

void main() {
  group('LearnTZ Streamlined Welcome & Home Landing Page', () {
    testWidgets('renders streamlined landing page fitting cleanly on screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pump single frame — must be rendered immediately
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Section A: Header & Static Brand Logo
      expect(find.byType(AppBrandLogo), findsAtLeastNWidgets(1));
      expect(find.byKey(const ValueKey('nav-/country')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-sign-in-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-get-started-btn')), findsOneWidget);

      // Section B: Hero Section with Prominent Official Logo
      expect(find.byKey(const Key('hero-official-brand-logo')), findsOneWidget);
      expect(find.text('LEARN ANYWHERE, ANYTIME.'), findsNothing);
      expect(find.textContaining('Learning, rooted in'), findsNothing);
      expect(find.text('A smarter way to learn, practise, prepare for examinations and achieve your academic goals.'), findsOneWidget);
      expect(find.byKey(const Key('landing-get-started-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-explore-learning-btn')), findsOneWidget);
      expect(find.text('EXPLORE LEARNING'), findsOneWidget);

      // Section G: Call to Action Banner
      expect(find.text("YOUR CHILD'S LEARNING JOURNEY STARTS HERE."), findsOneWidget);
      expect(find.byKey(const Key('landing-cta-register-parent-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-cta-sign-in-btn')), findsOneWidget);

      // Verify crowded sections and curriculum illustration card have been removed to fit cleanly on screen
      expect(find.text('WHAT LEARNTZ OFFERS'), findsNothing);
      expect(find.text('HOW IT WORKS'), findsNothing);
      expect(find.text('EXAMINATION PREPARATION'), findsNothing);
      expect(find.text('ONE APPLICATION • MULTIPLE AFRICAN NATIONS'), findsNothing);
      expect(find.text('About LearnTZ'), findsNothing);
      expect(find.textContaining('TIE Tanzania'), findsNothing);
      expect(find.textContaining('KICD Kenya'), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders desktop header with tagline and full navigation links on wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Learn Anywhere, Anytime.'), findsWidgets);
      expect(find.byKey(const ValueKey('nav-/about')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-/help')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-sign-in-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-get-started-btn')), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('dynamically adapts to country configuration', (
      tester,
    ) async {
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

      await tester.pumpWidget(_buildTestApp(country: kenyaConfig));
      await tester.pump();

      expect(find.text('KE'), findsWidgets);
      expect(find.textContaining('LearnKE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
