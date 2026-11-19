import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/admin/services/demo_accounts_service.dart';
import 'package:learntz/features/admin/screens/super_admin_control_centre_screen.dart';
import 'package:learntz/features/admin/admin_providers.dart';
import 'package:learntz/features/admin/admin_models.dart';

void main() {
  group('Demo Accounts Models & Deserialization', () {
    test('DemoParentAccount parses valid payload correctly', () {
      final json = {
        'id': 'd1000000-0000-0000-0000-000000000001',
        'email': 'parent01@demo.learntz.test',
        'full_name': 'Juma Bakari',
        'country_code': 'TZ',
        'phone_number': '+255711000001',
        'status': 'COMPLETED',
        'learner_count': 1,
        'is_demo': true,
      };

      final parent = DemoParentAccount.fromJson(json);
      expect(parent.id, 'd1000000-0000-0000-0000-000000000001');
      expect(parent.email, 'parent01@demo.learntz.test');
      expect(parent.fullName, 'Juma Bakari');
      expect(parent.countryCode, 'TZ');
      expect(parent.phoneNumber, '+255711000001');
      expect(parent.status, 'COMPLETED');
      expect(parent.learnerCount, 1);
      expect(parent.isDemo, isTrue);
    });

    test('DemoLearnerAccount parses learner details and access mode correctly', () {
      final json = {
        'id': 'd2000000-0000-0000-0000-000000000001',
        'learner_code': 'TZ-LRN-0101',
        'username': 'amani_tz',
        'full_name': 'Amani Bakari',
        'country_code': 'TZ',
        'grade_name': 'Standard 4',
        'avatar_preset': 'owl_scholar',
        'access_mode': 'independent_device',
        'access_status': 'active',
        'parent_name': 'Juma Bakari',
        'is_demo': true,
      };

      final learner = DemoLearnerAccount.fromJson(json);
      expect(learner.id, 'd2000000-0000-0000-0000-000000000001');
      expect(learner.learnerCode, 'TZ-LRN-0101');
      expect(learner.username, 'amani_tz');
      expect(learner.fullName, 'Amani Bakari');
      expect(learner.countryCode, 'TZ');
      expect(learner.gradeName, 'Standard 4');
      expect(learner.avatarPreset, 'owl_scholar');
      expect(learner.accessMode, 'independent_device');
      expect(learner.accessStatus, 'active');
      expect(learner.parentName, 'Juma Bakari');
      expect(learner.isDemo, isTrue);
    });

    test('DemoAdminAccount parses roles and country boundaries', () {
      final json = {
        'id': 'd3000000-0000-0000-0000-000000000002',
        'email': 'admin.tz@demo.learntz.test',
        'full_name': 'Demo Tanzania Admin',
        'role_name': 'COUNTRY_ADMIN',
        'country_code': 'TZ',
        'account_status': 'ACTIVE',
        'is_demo': true,
      };

      final admin = DemoAdminAccount.fromJson(json);
      expect(admin.email, 'admin.tz@demo.learntz.test');
      expect(admin.fullName, 'Demo Tanzania Admin');
      expect(admin.roleName, 'COUNTRY_ADMIN');
      expect(admin.countryCode, 'TZ');
      expect(admin.accountStatus, 'ACTIVE');
      expect(admin.isDemo, isTrue);
    });

    test('DemoAccountsOverview parses aggregated summary across all user personas', () {
      final overviewJson = {
        'summary': {
          'total_parents': 5,
          'total_learners': 10,
          'total_admins': 6,
        },
        'parents': [
          {
            'id': 'd1000000-0000-0000-0000-000000000001',
            'email': 'parent01@demo.learntz.test',
            'full_name': 'Juma Bakari',
            'country_code': 'TZ',
            'learner_count': 1,
            'is_demo': true,
          },
          {
            'id': 'd1000000-0000-0000-0000-000000000002',
            'email': 'parent02@demo.learntz.test',
            'full_name': 'Rehema Mwangi',
            'country_code': 'TZ',
            'learner_count': 3,
            'is_demo': true,
          },
        ],
        'learners': [
          {
            'id': 'd2000000-0000-0000-0000-000000000001',
            'learner_code': 'TZ-LRN-0101',
            'full_name': 'Amani Bakari',
            'country_code': 'TZ',
            'access_mode': 'independent_device',
          },
        ],
        'admins': [
          {
            'id': 'd3000000-0000-0000-0000-000000000001',
            'email': 'superadmin@demo.learntz.test',
            'full_name': 'Demo Super Admin',
            'role_name': 'SUPER_ADMIN',
            'country_code': null,
          },
        ],
      };

      final overview = DemoAccountsOverview.fromJson(overviewJson);
      expect(overview.totalParents, 5);
      expect(overview.totalLearners, 10);
      expect(overview.totalAdmins, 6);
      expect(overview.parents, hasLength(2));
      expect(overview.learners, hasLength(1));
      expect(overview.admins, hasLength(1));
      expect(overview.parents.first.fullName, 'Juma Bakari');
      expect(overview.parents.last.learnerCount, 3);
      expect(overview.admins.first.roleName, 'SUPER_ADMIN');
    });

    test('DemoAccountsOverview handles empty or malformed payloads gracefully', () {
      final overview = DemoAccountsOverview.fromJson({});
      expect(overview.totalParents, 0);
      expect(overview.totalLearners, 0);
      expect(overview.totalAdmins, 0);
      expect(overview.parents, isEmpty);
      expect(overview.learners, isEmpty);
      expect(overview.admins, isEmpty);
    });
  });

  group('Super Admin Control Centre Demo Sandbox Widget', () {
    testWidgets('renders Demo Accounts and Sandbox Navigation and tab items', (tester) async {
      final mockOverview = DemoAccountsOverview(
        parents: const [
          DemoParentAccount(
            id: 'd1000000-0000-0000-0000-000000000001',
            email: 'parent01@demo.learntz.test',
            fullName: 'Juma Bakari',
            countryCode: 'TZ',
            phoneNumber: '+255711000001',
            status: 'COMPLETED',
            learnerCount: 1,
            isDemo: true,
          ),
        ],
        learners: const [
          DemoLearnerAccount(
            id: 'd2000000-0000-0000-0000-000000000001',
            learnerCode: 'TZ-LRN-0101',
            username: 'amani_tz',
            fullName: 'Amani Bakari',
            countryCode: 'TZ',
            gradeName: 'Standard 4',
            avatarPreset: 'owl_scholar',
            accessMode: 'independent_device',
            accessStatus: 'active',
            parentName: 'Juma Bakari',
            isDemo: true,
          ),
        ],
        admins: const [
          DemoAdminAccount(
            id: 'd3000000-0000-0000-0000-000000000001',
            email: 'superadmin@demo.learntz.test',
            fullName: 'Demo Super Admin',
            roleName: 'SUPER_ADMIN',
            countryCode: null,
            accountStatus: 'ACTIVE',
            isDemo: true,
          ),
        ],
        totalParents: 1,
        totalLearners: 1,
        totalAdmins: 1,
      );

      final mockCapabilities = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': true,
        'roles': [
          {'role': 'super_admin', 'country_code': null},
        ],
      });

      final mockStats = SuperAdminControlCentreStats(
        totalLearners: 10,
        totalParents: 5,
        totalSubscriptions: 5,
        totalExams: 20,
        totalAdmins: 6,
        activeCountries: 4,
        openTickets: 0,
        systemHealth: 'HEALTHY',
        countryBreakdown: const [],
        recentAudits: const [],
      );

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminCapabilitiesProvider.overrideWith((ref) async => mockCapabilities),
            adminControlCentreStatsProvider.overrideWith((ref) async => mockStats),
            demoAccountsOverviewProvider.overrideWith((ref) async => mockOverview),
          ],
          child: const MaterialApp(
            home: SuperAdminControlCentreScreen(initialModule: 'demo-sandbox'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and management actions are rendered
      expect(find.text('Demo Accounts & Sandbox Engine'), findsOneWidget);
      expect(find.text('Reset Learner Activity'), findsOneWidget);
      expect(find.text('Re-provision All'), findsOneWidget);

      // Verify Tabs are present
      expect(find.text('Parents (1)'), findsOneWidget);
      expect(find.text('Learners (1)'), findsOneWidget);
      expect(find.text('Admins (1)'), findsOneWidget);

      // Verify parent row is rendered
      expect(find.text('Juma Bakari'), findsOneWidget);
      expect(find.textContaining('parent01@demo.learntz.test'), findsOneWidget);

      // Tap on Learners Tab
      await tester.tap(find.text('Learners (1)'));
      await tester.pumpAndSettle();

      // Verify learner row is rendered
      expect(find.text('Amani Bakari'), findsOneWidget);
      expect(find.textContaining('TZ-LRN-0101'), findsOneWidget);

      // Tap on Admins Tab
      await tester.tap(find.text('Admins (1)'));
      await tester.pumpAndSettle();

      // Verify admin row is rendered
      expect(find.text('Demo Super Admin'), findsOneWidget);
      expect(find.textContaining('superadmin@demo.learntz.test'), findsOneWidget);
    });
  });
}
