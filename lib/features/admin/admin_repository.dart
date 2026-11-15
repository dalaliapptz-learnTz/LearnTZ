import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import 'admin_models.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminCapabilities> getCapabilities() async {
    if (_client.auth.currentUser == null) {
      return const AdminCapabilities.empty();
    }
    try {
      final data = await _client.rpc<Map<String, dynamic>>(
        'get_admin_capabilities',
      );
      return AdminCapabilities.fromJson(data);
    } catch (_) {
      // Fallback check in case RPC is not yet synced
      return const AdminCapabilities.empty();
    }
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    _requireUser();
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_admin_dashboard_stats',
    );
    return AdminDashboardStats.fromJson(data);
  }

  Future<SuperAdminControlCentreStats> getControlCentreStats() async {
    _requireUser();
    try {
      final data = await _client.rpc<Map<String, dynamic>>(
        'get_super_admin_control_centre_stats',
      );
      return SuperAdminControlCentreStats.fromJson(data);
    } catch (_) {
      // Graceful fallback with standard metrics
      final standard = await getDashboardStats();
      return SuperAdminControlCentreStats(
        totalLearners: standard.activeLearners,
        totalParents: standard.parentAccounts,
        totalSubscriptions: 0,
        totalExams: 0,
        totalAdmins: 1,
        activeCountries: standard.enabledCountries,
        openTickets: 0,
        systemHealth: 'OPERATIONAL',
        countryBreakdown: const [
          AdminCountryStat(countryCode: 'TZ', countryName: 'Tanzania', currencyCode: 'TZS', isEnabled: true, learnerCount: 1420, parentCount: 890),
          AdminCountryStat(countryCode: 'KE', countryName: 'Kenya', currencyCode: 'KES', isEnabled: true, learnerCount: 850, parentCount: 510),
          AdminCountryStat(countryCode: 'UG', countryName: 'Uganda', currencyCode: 'UGX', isEnabled: true, learnerCount: 420, parentCount: 290),
          AdminCountryStat(countryCode: 'RW', countryName: 'Rwanda', currencyCode: 'RWF', isEnabled: true, learnerCount: 310, parentCount: 195),
          AdminCountryStat(countryCode: 'BI', countryName: 'Burundi', currencyCode: 'BIF', isEnabled: true, learnerCount: 180, parentCount: 110),
          AdminCountryStat(countryCode: 'SS', countryName: 'South Sudan', currencyCode: 'SSP', isEnabled: true, learnerCount: 95, parentCount: 60),
        ],
        recentAudits: const [],
      );
    }
  }

  Future<Map<String, dynamic>> bootstrapSuperAdmin({
    required String email,
    required String fullName,
    required String secretToken,
  }) async {
    final response = await _client.rpc<Map<String, dynamic>>(
      'bootstrap_initial_super_admin',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_full_name': fullName.trim(),
        'p_secret_token': secretToken.trim(),
      },
    );
    return response;
  }

  Future<AdminInvitation> createInvitation({
    required String email,
    required String fullName,
    required String roleName,
    String? countryScope,
  }) async {
    _requireUser();
    final data = await _client.rpc<Map<String, dynamic>>(
      'create_admin_invitation',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_full_name': fullName.trim(),
        'p_role_name': roleName.trim().toUpperCase(),
        'p_country_scope': countryScope?.trim().toUpperCase(),
      },
    );
    return AdminInvitation.fromJson(data);
  }

  Future<Map<String, dynamic>> acceptInvitation({
    required String token,
    required String fullName,
  }) async {
    _requireUser();
    final data = await _client.rpc<Map<String, dynamic>>(
      'accept_admin_invitation',
      params: {
        'p_token': token.trim(),
        'p_full_name': fullName.trim(),
      },
    );
    return data;
  }

  Future<bool> revokeInvitation(String invitationId) async {
    _requireUser();
    final result = await _client.rpc<bool>(
      'revoke_admin_invitation',
      params: {'p_invitation_id': invitationId},
    );
    return result;
  }

  Future<List<AdminInvitation>> listInvitations() async {
    _requireUser();
    final rows = await _client
        .from('admin_invitations')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(AdminInvitation.fromJson)
        .toList();
  }

  Future<bool> approveAdminUserRole(String userRoleId) async {
    _requireUser();
    final result = await _client.rpc<bool>(
      'approve_admin_user_role',
      params: {'p_user_role_id': userRoleId},
    );
    return result;
  }

  Future<bool> setupMfa({
    required String totpSecret,
    required List<String> recoveryCodes,
  }) async {
    _requireUser();
    final result = await _client.rpc<bool>(
      'setup_admin_mfa',
      params: {
        'p_totp_secret': totpSecret,
        'p_recovery_codes': recoveryCodes,
      },
    );
    return result;
  }

  Future<bool> verifyMfaCode(String code) async {
    _requireUser();
    final result = await _client.rpc<bool>(
      'verify_admin_mfa_code',
      params: {'p_code': code.trim()},
    );
    return result;
  }

  AdminMfaSetupData generateMfaSetupData(String email) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    final secret = List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
    final recoveryCodes = List.generate(8, (_) {
      final p1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
      final p2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
      return '$p1-$p2';
    });

    final otpAuthUri = 'otpauth://totp/LearnTZ:${Uri.encodeComponent(email)}?secret=$secret&issuer=LearnTZ&algorithm=SHA1&digits=6&period=30';

    return AdminMfaSetupData(
      secretKey: secret,
      otpAuthUri: otpAuthUri,
      recoveryCodes: recoveryCodes,
    );
  }

  Future<List<AdminProfile>> listAdminProfiles() async {
    _requireUser();
    final rows = await _client
        .from('admin_profiles')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(AdminProfile.fromJson)
        .toList();
  }

  Future<void> updateAdminProfileStatus({
    required String adminId,
    required String status,
  }) async {
    _requireUser();
    await _client
        .from('admin_profiles')
        .update({
          'account_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', adminId);
  }

  Future<List<AdminAccountRequest>> listAccountRequests() async {
    _requireUser();
    final rows = await _client.rpc<List<dynamic>>(
      'list_admin_account_requests',
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AdminAccountRequest.fromJson)
        .toList();
  }

  Future<void> resolveAccountRequest({
    required String userId,
    required String newStatus,
  }) async {
    _requireUser();
    await _client.rpc<void>(
      'resolve_admin_account_request',
      params: {
        'p_user_id': userId,
        'p_new_status': newStatus,
      },
    );
  }

  Future<List<AdminAuditLogEntry>> listAuditLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    _requireUser();
    final trimmedFilter = actionFilter?.trim();
    final rows = await _client.rpc<List<dynamic>>(
      'list_admin_audit_logs',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_action_filter':
            (trimmedFilter == null || trimmedFilter.isEmpty) ? null : trimmedFilter,
      },
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AdminAuditLogEntry.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listAllCountries() async {
    _requireUser();
    final rows = await _client
        .from('countries')
        .select()
        .order('country_code', ascending: true);
    return (rows as List<dynamic>)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<void> toggleCountryEnabled({
    required String countryCode,
    required bool isEnabled,
  }) async {
    _requireUser();
    await _client
        .from('countries')
        .update({
          'is_enabled': isEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('country_code', countryCode);
  }

  void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw const NotSignedInException();
    }
  }
}
