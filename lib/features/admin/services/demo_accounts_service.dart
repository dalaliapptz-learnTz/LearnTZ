import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/state/app_providers.dart';

/// Models representing provisioned demo accounts across Parents, Learners, and Admins.
class DemoParentAccount {
  const DemoParentAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.countryCode,
    required this.phoneNumber,
    required this.status,
    required this.learnerCount,
    required this.isDemo,
  });

  factory DemoParentAccount.fromJson(Map<String, dynamic> json) {
    return DemoParentAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      phoneNumber: json['phone_number'] as String? ?? '',
      status: json['status'] as String? ?? 'COMPLETED',
      learnerCount: json['learner_count'] as int? ?? 0,
      isDemo: json['is_demo'] as bool? ?? true,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String countryCode;
  final String phoneNumber;
  final String status;
  final int learnerCount;
  final bool isDemo;
}

class DemoLearnerAccount {
  const DemoLearnerAccount({
    required this.id,
    required this.learnerCode,
    required this.username,
    required this.fullName,
    required this.countryCode,
    required this.gradeName,
    required this.avatarPreset,
    required this.accessMode,
    required this.accessStatus,
    required this.parentName,
    required this.isDemo,
  });

  factory DemoLearnerAccount.fromJson(Map<String, dynamic> json) {
    return DemoLearnerAccount(
      id: json['id'] as String? ?? '',
      learnerCode: json['learner_code'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      gradeName: json['grade_name'] as String? ?? 'N/A',
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
      accessMode: json['access_mode'] as String? ?? 'parent_managed',
      accessStatus: json['access_status'] as String? ?? 'active',
      parentName: json['parent_name'] as String? ?? 'N/A',
      isDemo: json['is_demo'] as bool? ?? true,
    );
  }

  final String id;
  final String learnerCode;
  final String username;
  final String fullName;
  final String countryCode;
  final String gradeName;
  final String avatarPreset;
  final String accessMode;
  final String accessStatus;
  final String parentName;
  final bool isDemo;
}

class DemoAdminAccount {
  const DemoAdminAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleName,
    required this.countryCode,
    required this.accountStatus,
    required this.isDemo,
  });

  factory DemoAdminAccount.fromJson(Map<String, dynamic> json) {
    return DemoAdminAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      roleName: json['role_name'] as String? ?? 'ADMIN',
      countryCode: json['country_code'] as String?,
      accountStatus: json['account_status'] as String? ?? 'ACTIVE',
      isDemo: json['is_demo'] as bool? ?? true,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String roleName;
  final String? countryCode;
  final String accountStatus;
  final bool isDemo;
}

class DemoAccountsOverview {
  const DemoAccountsOverview({
    required this.parents,
    required this.learners,
    required this.admins,
    required this.totalParents,
    required this.totalLearners,
    required this.totalAdmins,
  });

  factory DemoAccountsOverview.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final parentsRaw = json['parents'] as List<dynamic>? ?? [];
    final learnersRaw = json['learners'] as List<dynamic>? ?? [];
    final adminsRaw = json['admins'] as List<dynamic>? ?? [];

    return DemoAccountsOverview(
      parents: parentsRaw
          .whereType<Map<String, dynamic>>()
          .map(DemoParentAccount.fromJson)
          .toList(),
      learners: learnersRaw
          .whereType<Map<String, dynamic>>()
          .map(DemoLearnerAccount.fromJson)
          .toList(),
      admins: adminsRaw
          .whereType<Map<String, dynamic>>()
          .map(DemoAdminAccount.fromJson)
          .toList(),
      totalParents: summary['total_parents'] as int? ?? parentsRaw.length,
      totalLearners: summary['total_learners'] as int? ?? learnersRaw.length,
      totalAdmins: summary['total_admins'] as int? ?? adminsRaw.length,
    );
  }

  final List<DemoParentAccount> parents;
  final List<DemoLearnerAccount> learners;
  final List<DemoAdminAccount> admins;
  final int totalParents;
  final int totalLearners;
  final int totalAdmins;
}

class DemoAccountsService {
  const DemoAccountsService(this._client);

  final SupabaseClient _client;

  Future<DemoAccountsOverview> getOverview() async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_demo_accounts_overview',
    );
    return DemoAccountsOverview.fromJson(data);
  }

  Future<Map<String, dynamic>> provisionDemoData({bool forceReset = false}) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'provision_demo_data',
      params: {'p_force_reset': forceReset},
    );
    return data;
  }

  Future<Map<String, dynamic>> resetDemoData() async {
    final data = await _client.rpc<Map<String, dynamic>>('reset_demo_data');
    return data;
  }
}

final demoAccountsServiceProvider = Provider<DemoAccountsService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return DemoAccountsService(client);
});

final demoAccountsOverviewProvider = FutureProvider<DemoAccountsOverview>((ref) async {
  final service = ref.watch(demoAccountsServiceProvider);
  if (service == null) {
    return const DemoAccountsOverview(
      parents: [],
      learners: [],
      admins: [],
      totalParents: 0,
      totalLearners: 0,
      totalAdmins: 0,
    );
  }
  return service.getOverview();
});
