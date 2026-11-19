import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/admin/admin_models.dart';
import 'package:learntz/features/admin/admin_providers.dart';
import 'package:learntz/features/admin/screens/admin_invitations_screen.dart';
import 'package:learntz/features/admin/screens/admin_login_screen.dart';
import 'package:learntz/features/admin/screens/admin_mfa_setup_screen.dart';
import 'package:learntz/features/admin/screens/super_admin_control_centre_screen.dart';

void main() {
  group('Enterprise RBAC & Super Admin Capabilities', () {
    test('SUPER_ADMIN has platform-wide global capabilities', () {
      final superAdmin = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': true,
        'roles': [
          {'role': 'super_admin', 'country_code': null},
        ],
      });

      expect(superAdmin.canAccessAdmin, isTrue);
      expect(superAdmin.isSuperAdmin, isTrue);
      expect(superAdmin.canManageCountries, isTrue);
      expect(superAdmin.canManageInvitations, isTrue);
      expect(superAdmin.canManageCms, isTrue);
      expect(superAdmin.canManageExams, isTrue);
      expect(superAdmin.canViewFinance, isTrue);
      expect(superAdmin.canViewAnalytics, isTrue);
      expect(superAdmin.canAuditSecurity, isTrue);
      expect(superAdmin.hasCountryAccess('TZ'), isTrue);
      expect(superAdmin.hasCountryAccess('KE'), isTrue);
      expect(superAdmin.hasCountryAccess('UG'), isTrue);
    });

    test('COUNTRY_ADMIN is strictly bounded to assigned country scope', () {
      final countryAdmin = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': false,
        'is_country_admin': true,
        'roles': [
          {'role': 'country_admin', 'country_code': 'TZ'},
        ],
      });

      expect(countryAdmin.canAccessAdmin, isTrue);
      expect(countryAdmin.isSuperAdmin, isFalse);
      expect(countryAdmin.canManageCountries, isFalse); // Cannot change country configs globally
      expect(countryAdmin.canManageInvitations, isFalse);
      expect(countryAdmin.hasCountryAccess('TZ'), isTrue);
      expect(countryAdmin.hasCountryAccess('KE'), isFalse);
      expect(countryAdmin.hasCountryAccess('UG'), isFalse);
    });

    test('Least-privilege role bounds for FINANCE, CONTENT, and SUPPORT', () {
      final financeAdmin = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'roles': [
          {'role': 'finance_admin', 'country_code': null},
        ],
      });
      expect(financeAdmin.canViewFinance, isTrue);
      expect(financeAdmin.canManageCountries, isFalse);
      expect(financeAdmin.canManageCms, isFalse);

      final contentAdmin = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'roles': [
          {'role': 'content_admin', 'country_code': null},
        ],
      });
      expect(contentAdmin.canManageCms, isTrue);
      expect(contentAdmin.canViewFinance, isFalse);

      final supportAdmin = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_support_admin': true,
        'roles': [
          {'role': 'support_admin', 'country_code': null},
        ],
      });
      expect(supportAdmin.canManageAccountRequests, isTrue);
      expect(supportAdmin.canAuditSecurity, isFalse);
    });
  });

  group('Admin Invitations & MFA Data Models', () {
    test('AdminInvitation parses status, token and calculates expiry', () {
      final invitation = AdminInvitation.fromJson({
        'id': 'inv-001',
        'email': 'lecturer.mugisha@learntz.com',
        'full_name': 'Prof. Mugisha',
        'role_name': 'CONTENT_ADMIN',
        'country_scope': 'RW',
        'token': 'tok-super-secret-xyz',
        'expires_at': DateTime.now().add(const Duration(hours: 72)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(invitation.id, 'inv-001');
      expect(invitation.email, 'lecturer.mugisha@learntz.com');
      expect(invitation.roleName, 'CONTENT_ADMIN');
      expect(invitation.countryScope, 'RW');
      expect(invitation.token, 'tok-super-secret-xyz');
      expect(invitation.isExpired, isFalse);
      expect(invitation.isPending, isTrue);
      expect(invitation.isAccepted, isFalse);
      expect(invitation.isRevoked, isFalse);
    });

    test('SuperAdminControlCentreStats parses 6-country East African telemetry', () {
      final stats = SuperAdminControlCentreStats.fromJson({
        'total_learners': 3275,
        'total_parents': 2055,
        'total_subscriptions': 1450,
        'total_exams': 48,
        'total_admins': 8,
        'active_countries': 6,
        'open_tickets': 2,
        'system_health': 'OPERATIONAL',
        'country_breakdown': [
          {'country_code': 'TZ', 'country_name': 'Tanzania', 'currency_code': 'TZS', 'is_enabled': true, 'learner_count': 1420, 'parent_count': 890},
          {'country_code': 'KE', 'country_name': 'Kenya', 'currency_code': 'KES', 'is_enabled': true, 'learner_count': 850, 'parent_count': 510},
          {'country_code': 'UG', 'country_name': 'Uganda', 'currency_code': 'UGX', 'is_enabled': true, 'learner_count': 420, 'parent_count': 290},
          {'country_code': 'RW', 'country_name': 'Rwanda', 'currency_code': 'RWF', 'is_enabled': true, 'learner_count': 310, 'parent_count': 195},
          {'country_code': 'BI', 'country_name': 'Burundi', 'currency_code': 'BIF', 'is_enabled': true, 'learner_count': 180, 'parent_count': 110},
          {'country_code': 'SS', 'country_name': 'South Sudan', 'currency_code': 'SSP', 'is_enabled': true, 'learner_count': 95, 'parent_count': 60},
        ],
        'recent_audits': [
          {'id': 101, 'action': 'BOOTSTRAP_INITIAL_SUPER_ADMIN', 'resource_type': 'admin_profiles', 'created_at': '2026-11-15T10:00:00Z', 'metadata': {}},
        ],
      });

      expect(stats.totalLearners, 3275);
      expect(stats.totalParents, 2055);
      expect(stats.activeCountries, 6);
      expect(stats.countryBreakdown, hasLength(6));
      expect(stats.countryBreakdown.first.countryCode, 'TZ');
      expect(stats.countryBreakdown.first.learnerCount, 1420);
      expect(stats.recentAudits, hasLength(1));
      expect(stats.recentAudits.first.action, 'BOOTSTRAP_INITIAL_SUPER_ADMIN');
    });
  });

  group('Super Admin Screen Widget Tests', () {
    testWidgets('AdminLoginScreen renders restricted banner and auth inputs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminLoginScreen(),
          ),
        ),
      );

      expect(find.text('ADMINISTRATION PORTAL'), findsOneWidget);
      expect(find.textContaining('RESTRICTED ACCESS'), findsOneWidget);
      expect(find.byKey(const Key('admin-login-email-field')), findsOneWidget);
      expect(find.byKey(const Key('admin-login-password-field')), findsOneWidget);
      expect(find.byKey(const Key('admin-login-submit-btn')), findsOneWidget);
      expect(find.byKey(const Key('admin-bootstrap-modal-btn')), findsOneWidget);
    });

    testWidgets('AdminMfaSetupScreen renders 2FA steps and recovery code confirmation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminMfaSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multi-Factor Authentication Enrolment'), findsOneWidget);
      expect(find.text('Step 1: Add to Authenticator App'), findsOneWidget);
      expect(find.text('Step 2: Save Emergency Recovery Codes'), findsOneWidget);
      expect(find.text('Step 3: Confirm 6-Digit Verification Code'), findsOneWidget);
      expect(find.byKey(const Key('admin-mfa-setup-code-field')), findsOneWidget);
      expect(find.byKey(const Key('admin-mfa-setup-submit-btn')), findsOneWidget);
    });

    testWidgets('AdminInvitationsScreen renders list and issue invitation button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminInvitationsProvider.overrideWith((ref) async => [
              AdminInvitation(
                id: 'inv-1',
                email: 'test@learntz.com',
                fullName: 'Dr. John Doe',
                roleName: 'COUNTRY_ADMIN',
                countryScope: 'TZ',
                expiresAt: DateTime.now().add(const Duration(hours: 48)),
                createdAt: DateTime.now(),
              ),
            ]),
          ],
          child: const MaterialApp(
            home: AdminInvitationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrator Invitations'), findsOneWidget);
      expect(find.byKey(const Key('admin-issue-invitation-btn')), findsOneWidget);
      expect(find.text('Dr. John Doe'), findsOneWidget);
      expect(find.text('COUNTRY_ADMIN'), findsOneWidget);
    });

    testWidgets('SuperAdminControlCentreScreen renders Control Centre shell and KPI cards', (tester) async {
      final mockStats = SuperAdminControlCentreStats(
        totalLearners: 3275,
        totalParents: 2055,
        totalSubscriptions: 1450,
        totalExams: 48,
        totalAdmins: 8,
        activeCountries: 6,
        openTickets: 0,
        systemHealth: 'OPERATIONAL',
        countryBreakdown: const [
          AdminCountryStat(countryCode: 'TZ', countryName: 'Tanzania', currencyCode: 'TZS', isEnabled: true, learnerCount: 1420, parentCount: 890),
          AdminCountryStat(countryCode: 'KE', countryName: 'Kenya', currencyCode: 'KES', isEnabled: true, learnerCount: 850, parentCount: 510),
        ],
        recentAudits: const [],
      );

      final mockCapabilities = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': true,
        'roles': [
          {'role': 'super_admin', 'country_code': null},
        ],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminCapabilitiesProvider.overrideWith((ref) async => mockCapabilities),
            adminControlCentreStatsProvider.overrideWith((ref) async => mockStats),
          ],
          child: const MaterialApp(
            home: SuperAdminControlCentreScreen(initialModule: 'dashboard'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUPER ADMIN'), findsWidgets);
      expect(find.text('Multi-Country SaaS Operations'), findsOneWidget);
      expect(find.text('Registered Learners'), findsOneWidget);
      expect(find.text('3275'), findsOneWidget);
      expect(find.text('Tanzania'), findsOneWidget);
      expect(find.text('Kenya'), findsOneWidget);
    });
  });
}
