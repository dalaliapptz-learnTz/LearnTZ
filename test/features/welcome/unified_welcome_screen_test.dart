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
  group('LearnTZ Unified Welcome & Home Landing Page', () {
    testWidgets('renders unified landing page with static branding immediately without animation delay', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      // Pump single frame — must be rendered immediately
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Section A: Header & Static Brand Logo
      expect(find.byType(AppBrandLogo), findsAtLeastNWidgets(1));
      expect(find.byKey(const ValueKey('nav-/country')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-sign-in-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-get-started-btn')), findsOneWidget);

      // Section B: Hero Section
      expect(find.text('LEARN ANYWHERE, ANYTIME.'), findsOneWidget);
      expect(find.text('A smarter way to learn, practise, prepare for examinations and achieve your academic goals.'), findsOneWidget);
      expect(find.byKey(const Key('landing-get-started-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-explore-learning-btn')), findsOneWidget);
      expect(find.text('EXPLORE LEARNING'), findsOneWidget);

      // Section C: Features Section
      expect(find.text('WHAT LEARNTZ OFFERS'), findsOneWidget);
      expect(find.text('Personalised Learning'), findsOneWidget);
      expect(find.text('Interactive Lessons'), findsOneWidget);
      expect(find.text('Practice and Assessments'), findsOneWidget);
      expect(find.text('Revision Centre'), findsOneWidget);
      expect(find.text('Mock Examinations'), findsOneWidget);
      expect(find.text('Learning Communities'), findsOneWidget);

      // Section D: How It Works
      expect(find.text('HOW IT WORKS'), findsOneWidget);
      expect(find.text('Parent creates account'), findsOneWidget);
      expect(find.text('Parent adds child'), findsOneWidget);
      expect(find.text('Learner accesses profile'), findsOneWidget);
      expect(find.text('Learner studies and practises'), findsOneWidget);
      expect(find.text('LearnTZ tracks progress'), findsOneWidget);
      expect(find.text('Parent monitors improvement'), findsOneWidget);

      // Section E: Examination Preparation
      expect(find.text('EXAMINATION PREPARATION'), findsOneWidget);
      expect(find.text('Rigorous Preparation for Real National Exams'), findsOneWidget);
      expect(find.text('Past Examination Papers'), findsOneWidget);

      // Section F: Multi-Country Section
      expect(find.text('ONE APPLICATION • MULTIPLE AFRICAN NATIONS'), findsOneWidget);
      expect(find.text('African-Ready Multi-Curriculum Engine'), findsOneWidget);

      // Section G: Call to Action Banner
      expect(find.text("YOUR CHILD'S LEARNING JOURNEY STARTS HERE."), findsOneWidget);
      expect(find.byKey(const Key('landing-cta-register-parent-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-cta-sign-in-btn')), findsOneWidget);

      // Section H: Footer
      expect(find.text('About LearnTZ'), findsOneWidget);
      expect(find.text('Help Centre'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.textContaining('All rights reserved'), findsOneWidget);

      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders desktop header with tagline and full navigation links on wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Learn Anywhere, Anytime.'), findsWidgets);
      expect(find.byKey(const ValueKey('nav-/about')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-/help')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-sign-in-btn')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-get-started-btn')), findsOneWidget);

      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
