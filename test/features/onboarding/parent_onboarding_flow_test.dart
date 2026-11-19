import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/app.dart';
import 'package:learntz/core/config/country_configuration.dart';
import 'package:learntz/core/routing/app_router.dart';
import 'package:learntz/features/onboarding/models/child_draft.dart';
import 'package:learntz/features/onboarding/models/onboarding_session.dart';
import 'package:learntz/features/onboarding/models/onboarding_step.dart';
import 'package:learntz/features/onboarding/providers/onboarding_providers.dart';
import 'package:learntz/features/onboarding/screens/onboarding_add_child_screen.dart';
import 'package:learntz/features/onboarding/screens/onboarding_confirm_screen.dart';
import 'package:learntz/features/onboarding/screens/onboarding_country_screen.dart';
import 'package:learntz/features/onboarding/screens/onboarding_otp_screen.dart';
import 'package:learntz/features/onboarding/screens/onboarding_register_screen.dart';
import 'package:learntz/features/onboarding/services/onboarding_storage_service.dart';

void main() {
  group('Parent Onboarding State Machine & Models', () {
    test('OnboardingStep progression and prerequisite validation', () {
      expect(OnboardingStep.notStarted.index, 0);
      expect(OnboardingStep.completed.index, 8);

      expect(OnboardingStep.notStarted.canAdvanceTo(OnboardingStep.countrySelected), isTrue);
      expect(OnboardingStep.notStarted.canAdvanceTo(OnboardingStep.completed), isFalse);

      expect(OnboardingStep.fromSerialized('NOT_STARTED'), OnboardingStep.notStarted);
      expect(OnboardingStep.fromSerialized('COUNTRY_SELECTED'), OnboardingStep.countrySelected);
      expect(OnboardingStep.fromSerialized('PARENT_REGISTERED'), OnboardingStep.parentRegistered);
      expect(OnboardingStep.fromSerialized('PHONE_VERIFICATION_PENDING'), OnboardingStep.phoneVerificationPending);
      expect(OnboardingStep.fromSerialized('PHONE_VERIFIED'), OnboardingStep.phoneVerified);
      expect(OnboardingStep.fromSerialized('CHILDREN_ADDED'), OnboardingStep.childrenAdded);
      expect(OnboardingStep.fromSerialized('COMPLETED'), OnboardingStep.completed);
    });

    test('ChildDraft calculates age correctly and serializes to JSON', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 10, now.month, now.day);
      final draft = ChildDraft(
        id: 'test-child-1',
        firstName: 'Sarah',
        middleName: 'Amina',
        lastName: 'Mwangi',
        dateOfBirth: dob,
        gender: 'female',
        countryCode: 'TZ',
        educationSystemId: 'sys-1',
        systemName: 'Tanzania Institute of Education',
        curriculumId: 'cur-1',
        curriculumName: 'National Curriculum',
        educationLevelId: 'lvl-1',
        levelName: 'Primary',
        gradeId: 'grd-4',
        gradeName: 'Standard 4',
        schoolName: 'Olympic Primary',
        avatarPreset: 'lion_reader',
      );

      expect(draft.fullName, 'Sarah Amina Mwangi');
      expect(draft.ageYears, 10);

      final json = draft.toJson();
      expect(json['first_name'], 'Sarah');
      expect(json['avatar_preset'], 'lion_reader');

      final reconstructed = ChildDraft.fromJson(json);
      expect(reconstructed.id, 'test-child-1');
      expect(reconstructed.fullName, 'Sarah Amina Mwangi');
      expect(reconstructed.avatarPreset, 'lion_reader');
    });

    test('OnboardingStorageService saves and loads session across restarts', () async {
      final storage = OnboardingStorageService();
      final session = OnboardingSession(
        step: OnboardingStep.phoneVerified,
        countryCode: 'TZ',
        countryName: 'Tanzania',
        parentFullName: 'David Mwangi',
        phoneNumber: '+255712345678',
        email: 'david@example.com',
        isPhoneVerified: true,
        acceptedTerms: true,
        acceptedPrivacy: true,
        lastUpdated: DateTime.now(),
      );

      await storage.saveSession(session);
      final loaded = await storage.loadSession();

      expect(loaded, isNotNull);
      expect(loaded!.parentFullName, 'David Mwangi');
      expect(loaded.phoneNumber, '+255712345678');
      expect(loaded.step, OnboardingStep.phoneVerified);

      await storage.clearSession();
      final afterClear = await storage.loadSession();
      expect(afterClear, isNull);
    });

    test('OnboardingSessionNotifier updates and stages multiple children', () {
      final container = ProviderContainer();
      final notifier = container.read(onboardingSessionProvider.notifier);

      expect(container.read(onboardingSessionProvider).step, OnboardingStep.notStarted);

      // 1. Select Country
      notifier.selectCountry(tanzaniaConfiguration);
      expect(container.read(onboardingSessionProvider).countryCode, 'TZ');
      expect(container.read(onboardingSessionProvider).step, OnboardingStep.countrySelected);

      // 2. Set Parent
      notifier.setParentRegistration(
        fullName: 'Grace Mwangi',
        phoneNumber: '+255712345678',
        email: 'grace@example.com',
      );
      expect(container.read(onboardingSessionProvider).parentFullName, 'Grace Mwangi');
      expect(container.read(onboardingSessionProvider).step, OnboardingStep.phoneVerificationPending);

      // 3. Mark Phone Verified
      notifier.markPhoneVerified();
      expect(container.read(onboardingSessionProvider).isPhoneVerified, isTrue);
      expect(container.read(onboardingSessionProvider).step, OnboardingStep.phoneVerified);

      // 4. Add Child 1
      final child1 = ChildDraft(
        id: 'child-1',
        firstName: 'Juma',
        lastName: 'Mwangi',
        dateOfBirth: DateTime(2016, 5, 12),
        countryCode: 'TZ',
        educationSystemId: 'sys-1',
        systemName: 'TIE',
        curriculumId: 'cur-1',
        curriculumName: 'National',
        educationLevelId: 'lvl-1',
        levelName: 'Primary',
        gradeId: 'grd-3',
        gradeName: 'Standard 3',
        avatarPreset: 'cheetah_runner',
      );
      notifier.addChildDraft(child1);
      expect(container.read(onboardingSessionProvider).children.length, 1);
      expect(container.read(onboardingSessionProvider).step, OnboardingStep.childrenAdded);

      // 5. Add Child 2
      final child2 = ChildDraft(
        id: 'child-2',
        firstName: 'Neema',
        lastName: 'Mwangi',
        dateOfBirth: DateTime(2018, 9, 20),
        countryCode: 'TZ',
        educationSystemId: 'sys-1',
        systemName: 'TIE',
        curriculumId: 'cur-1',
        curriculumName: 'National',
        educationLevelId: 'lvl-1',
        levelName: 'Primary',
        gradeId: 'grd-1',
        gradeName: 'Standard 1',
        avatarPreset: 'owl_scholar',
      );
      notifier.addChildDraft(child2);
      expect(container.read(onboardingSessionProvider).children.length, 2);

      // 6. Remove Child 1
      notifier.removeChildDraft('child-1');
      expect(container.read(onboardingSessionProvider).children.length, 1);
      expect(container.read(onboardingSessionProvider).children.first.firstName, 'Neema');

      container.dispose();
    });
  });

  group('Parent Onboarding Screen Widgets', () {
    testWidgets('OnboardingCountryScreen renders 6 East African countries with flags', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OnboardingCountryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Your Country'), findsOneWidget);
      expect(find.text('Tanzania'), findsWidgets);
      expect(find.text('Kenya'), findsOneWidget);
      expect(find.text('Uganda'), findsOneWidget);
      expect(find.text('Rwanda'), findsOneWidget);
      expect(find.text('Burundi'), findsOneWidget);
      expect(find.text('South Sudan'), findsOneWidget);

      expect(find.text('🇹🇿'), findsWidgets);
      expect(find.text('🇰🇪'), findsOneWidget);
      expect(find.text('🇺🇬'), findsOneWidget);

      expect(find.text('Continue with Tanzania'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('OnboardingRegisterScreen validates form and privacy acceptance', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OnboardingRegisterScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Parent Account'), findsOneWidget);
      expect(find.text('Child Privacy & Data Protection Guarantee'), findsOneWidget);
      expect(find.text('Parent / Guardian Full Name'), findsOneWidget);
      expect(find.text('Mobile Phone Number'), findsOneWidget);
      expect(find.text('Security Password'), findsOneWidget);

      // Tap submit with empty fields
      await tester.tap(find.text('Create Account & Verify Phone'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Mobile phone number is required'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('OnboardingOtpScreen renders 6 PIN boxes, resend timer, and instant test fill', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OnboardingOtpScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify Phone Number'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Confirm & Continue'), findsOneWidget);
      expect(find.text('Edit Phone Number'), findsOneWidget);
      expect(find.text('Instant Verification (Testing Mode)'), findsOneWidget);
      expect(find.text('Quick Fill Test Code (123456)'), findsOneWidget);

      await tester.tap(find.text('Quick Fill Test Code (123456)'));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields.length, 6);
      expect(fields[0].controller?.text, '1');
      expect(fields[1].controller?.text, '2');
      expect(fields[2].controller?.text, '3');
      expect(fields[3].controller?.text, '4');
      expect(fields[4].controller?.text, '5');
      expect(fields[5].controller?.text, '6');

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('OnboardingAddChildScreen renders headline, avatar selector, and form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OnboardingAddChildScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("LET'S ADD YOUR FIRST CHILD"), findsOneWidget);
      expect(find.text('1. Child Identity & Basic Details'), findsOneWidget);
      expect(find.text('2. Choose Learning Avatar'), findsOneWidget);
      expect(find.text('Wise Owl'), findsOneWidget);
      expect(find.text('Brave Lion'), findsOneWidget);
      expect(find.text('3. Education System & Class Level'), findsOneWidget);
      expect(find.text('+ Add Another Child'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('OnboardingConfirmScreen displays summary and confirm button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;

      final container = ProviderContainer();
      container.read(onboardingSessionProvider.notifier).setParentRegistration(
            fullName: 'Amina Mwangi',
            phoneNumber: '+255712345678',
            email: 'amina@example.com',
          );
      container.read(onboardingSessionProvider.notifier).addChildDraft(
            ChildDraft(
              id: 'child-c1',
              firstName: 'Baraka',
              lastName: 'Mwangi',
              dateOfBirth: DateTime(2015, 3, 10),
              countryCode: 'TZ',
              educationSystemId: 'sys-1',
              systemName: 'TIE',
              curriculumId: 'cur-1',
              curriculumName: 'National',
              educationLevelId: 'lvl-1',
              levelName: 'Primary Education',
              gradeId: 'grd-5',
              gradeName: 'Standard 5',
              schoolName: 'Kisutu Primary School',
              avatarPreset: 'owl_scholar',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: OnboardingConfirmScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Family Learning Profile'), findsOneWidget);
      expect(find.text('Amina Mwangi'), findsOneWidget);
      expect(find.text('Phone Verified'), findsOneWidget);
      expect(find.text('Baraka Mwangi'), findsOneWidget);
      expect(find.text('Standard 5 • Primary Education'), findsOneWidget);
      expect(find.text('Kisutu Primary School'), findsOneWidget);
      expect(find.text('CONFIRM AND CONTINUE'), findsOneWidget);

      container.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('GoRouter allows transition from OTP to Add Child when phone is verified', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;

      final container = ProviderContainer();
      container.read(onboardingSessionProvider.notifier).setParentRegistration(
            fullName: 'David Mwangi',
            phoneNumber: '+255712345678',
          );
      container.read(onboardingSessionProvider.notifier).markPhoneVerified();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LearnTzApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go(AppRoutes.onboardingAddChild);
      await tester.pumpAndSettle();

      expect(find.text("LET'S ADD YOUR FIRST CHILD"), findsOneWidget);
      expect(find.text('Create Parent Account'), findsNothing);

      container.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
