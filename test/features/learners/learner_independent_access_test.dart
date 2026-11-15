// LearnTZ — Independent Learner Access & Device Linking Test Suite

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/learners/models/learner_access_models.dart';
import 'package:learntz/features/learners/screens/child_device_management_screen.dart';
import 'package:learntz/features/learners/screens/learner_login_screen.dart';
import 'package:learntz/features/learners/services/learner_auth_service.dart';

void main() {
  group('Learner Access Models & Token Tests', () {
    test('LearnerAccessMode parses code and falls back to parentManaged', () {
      expect(LearnerAccessMode.fromCode('independent_device'),
          LearnerAccessMode.independentDevice);
      expect(LearnerAccessMode.fromCode('setup_later'),
          LearnerAccessMode.setupLater);
      expect(LearnerAccessMode.fromCode('parent_managed'),
          LearnerAccessMode.parentManaged);
      expect(LearnerAccessMode.fromCode('unknown_code'),
          LearnerAccessMode.parentManaged);
      expect(LearnerAccessMode.fromCode(null),
          LearnerAccessMode.parentManaged);
    });

    test('LearnerActivationToken validates expiry and serializes to JSON', () {
      final token = LearnerActivationToken(
        tokenId: 'tok_123',
        tokenCode: 'LTZ-4921',
        learnerId: 'lrn_456',
        learnerCode: 'LTZ-26-881920',
        learnerName: 'Baraka Mrema',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        expiresInSeconds: 900,
        qrPayload: '{"action":"link_device","code":"LTZ-4921"}',
      );

      expect(token.isExpired, isFalse);
      expect(token.tokenCode, 'LTZ-4921');

      final json = token.toJson();
      final revived = LearnerActivationToken.fromJson(json);
      expect(revived.tokenCode, 'LTZ-4921');
      expect(revived.learnerCode, 'LTZ-26-881920');
      expect(revived.isExpired, isFalse);

      final expiredToken = LearnerActivationToken(
        tokenId: 'tok_expired',
        tokenCode: 'EXP-0001',
        learnerId: 'lrn_456',
        learnerCode: 'LTZ-26-881920',
        learnerName: 'Baraka Mrema',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        expiresInSeconds: 0,
      );
      expect(expiredToken.isExpired, isTrue);
    });

    test('LearnerSession correctly handles parentManaged and independentDevice modes', () {
      final independentSession = LearnerSession(
        sessionToken: 'sess_abc123',
        sessionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        deviceId: 'dev_galaxy_tab',
        isParentManagedMode: false,
        learner: const LearnerSessionProfile(
          id: 'lrn_001',
          firstName: 'Neema',
          lastName: 'Kweka',
          fullName: 'Neema Kweka',
          learnerCode: 'LTZ-26-102938',
          avatarPreset: 'cheetah_runner',
          countryCode: 'TZ',
          educationSystemId: 'sys-tz',
          curriculumId: 'cur-necta',
          educationLevelId: 'lvl-pri',
          gradeId: 'grd-std3',
          accessMode: LearnerAccessMode.independentDevice,
        ),
      );

      expect(independentSession.isParentManagedMode, isFalse);
      expect(independentSession.isExpired, isFalse);
      expect(independentSession.learner.accessMode, LearnerAccessMode.independentDevice);

      final json = independentSession.toJson();
      final revived = LearnerSession.fromJson(json);
      expect(revived.sessionToken, 'sess_abc123');
      expect(revived.learner.learnerCode, 'LTZ-26-102938');
      expect(revived.isParentManagedMode, isFalse);
    });

    test('LearnerDevice serializes and tracks active status', () {
      final now = DateTime.now();
      final device = LearnerDevice(
        id: 'dev_001',
        deviceIdentifier: 'android_tab_s8',
        deviceName: "Baraka's Tablet",
        deviceType: 'tablet',
        isActive: true,
        lastActiveAt: now,
        lastSyncAt: now,
        createdAt: now.subtract(const Duration(days: 5)),
      );

      expect(device.isActive, isTrue);
      expect(device.deviceType, 'tablet');

      final json = device.toJson();
      final revived = LearnerDevice.fromJson(json);
      expect(revived.id, 'dev_001');
      expect(revived.deviceName, "Baraka's Tablet");
      expect(revived.isActive, isTrue);
    });
  });

  group('LearnerAuthService Unit Tests', () {
    late LearnerAuthService service;

    setUp(() {
      service = LearnerAuthService();
    });

    test('authenticates credential and persists session', () async {
      final session = await service.authenticateCredential(
        identifier: 'LTZ-26-881920',
        secret: '4921',
        deviceName: "Baraka's Phone",
        deviceType: 'phone',
      );

      expect(session.sessionToken, isNotEmpty);
      expect(session.learner.learnerCode, 'LTZ-26-881920');
      expect(session.isExpired, isFalse);

      final stored = await service.getActiveSession();
      expect(stored, isNotNull);
      expect(stored!.learner.learnerCode, 'LTZ-26-881920');

      await service.signOut();
      expect(await service.getActiveSession(), isNull);
    });

    test('links device via activation code', () async {
      final session = await service.linkDevice(
        tokenCode: 'A7K9X2',
        deviceName: 'Living Room iPad',
        deviceType: 'tablet',
      );

      expect(session.sessionToken, isNotEmpty);
      expect(session.learner.fullName, 'Neema Kweka');

      final stored = await service.getActiveSession();
      expect(stored, isNotNull);
      expect(stored!.learner.fullName, 'Neema Kweka');
    });

    test('starts and exits parent-managed child session', () async {
      final session = await service.startParentManagedChildSession(
        learnerId: 'lrn_pm_01',
        firstName: 'Juma',
        lastName: 'Bakari',
        learnerCode: 'LTZ-26-773322',
        avatarPreset: 'elephant_math',
        countryCode: 'TZ',
        educationSystemId: 'sys-tz',
        curriculumId: 'cur-necta',
        educationLevelId: 'lvl-pri',
        gradeId: 'grd-std5',
      );

      expect(session.isParentManagedMode, isTrue);
      expect(session.learner.firstName, 'Juma');
      expect(session.learner.accessMode, LearnerAccessMode.parentManaged);

      final stored = await service.getActiveSession();
      expect(stored, isNotNull);
      expect(stored!.isParentManagedMode, isTrue);

      await service.signOut();
      expect(await service.getActiveSession(), isNull);
    });

    test('parent management methods: generate token, reset PIN, revoke device', () async {
      final token = await service.generateActivationToken('lrn_test_01');
      expect(token.tokenCode, isNotEmpty);
      expect(token.isExpired, isFalse);

      final resetOk = await service.resetPin(
        learnerId: 'lrn_test_01',
        newPin: '5829',
      );
      expect(resetOk, isTrue);

      final revokeOk = await service.revokeDevice(
        learnerId: 'lrn_test_01',
        deviceId: 'dev_rev_01',
      );
      expect(revokeOk, isTrue);

      final suspendOk = await service.toggleAccessStatus(
        learnerId: 'lrn_test_01',
        suspend: true,
      );
      expect(suspendOk, isTrue);

      final syncRes = await service.syncOfflineActivity(
        learnerId: 'lrn_test_01',
        events: [
          {
            'client_event_id': 'evt_001',
            'event_type': 'lesson_completed',
            'client_recorded_at': DateTime.now().toIso8601String(),
          }
        ],
      );
      expect(syncRes['processed_count'], 1);
    });
  });

  group('Learner Portal Widgets Tests', () {
    testWidgets('LearnerLoginScreen renders tabs, inputs, and help modal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LearnerLoginScreen(),
          ),
        ),
      );

      expect(find.text('STUDENT PORTAL'), findsOneWidget);
      expect(find.text('Welcome to LearnTZ!'), findsOneWidget);
      expect(find.text('Learner ID & PIN'), findsOneWidget);
      expect(find.text('Link Device'), findsOneWidget);
      expect(find.text('Learner ID or Username'), findsOneWidget);
      expect(find.text('PIN or Password'), findsOneWidget);
      expect(find.text('SIGN IN TO LEARNTZ'), findsOneWidget);

      // Tap Need Help / Forgot PIN
      await tester.tap(find.text('Forgot PIN / Need Help?'));
      await tester.pumpAndSettle();

      expect(find.text('Need Help Signing In?'), findsOneWidget);
      expect(find.text('Ask your parent or guardian to help you:'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      // Switch to Link Device tab
      await tester.tap(find.text('Link Device'));
      await tester.pumpAndSettle();

      expect(find.text('Activation Code (6 Characters)'), findsOneWidget);
      expect(find.text('LINK MY ACCOUNT'), findsOneWidget);
    });

    testWidgets('ChildDeviceManagementScreen renders controls and triggers code generation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChildDeviceManagementScreen(learnerId: 'mock_learner_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Child Device Management'), findsOneWidget);
      expect(find.text('Baraka Mrema'), findsOneWidget);
      expect(find.text('ID: LTZ-26-881920'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Generate Device Activation Code'), findsOneWidget);
      expect(find.text('Reset PIN'), findsOneWidget);
      expect(find.text('Suspend Child Access'), findsOneWidget);

      // Tap Generate Device Activation Code
      await tester.tap(find.text('Generate Device Activation Code'));
      await tester.pumpAndSettle();

      expect(find.text('Active Single-Use Code'), findsOneWidget);
      expect(find.textContaining('Expires in'), findsOneWidget);
    });
  });
}
