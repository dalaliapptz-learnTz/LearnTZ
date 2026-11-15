class AdminRoleAssignment {
  const AdminRoleAssignment({required this.role, this.countryCode});

  factory AdminRoleAssignment.fromJson(Map<String, dynamic> json) {
    return AdminRoleAssignment(
      role: json['role'] as String,
      countryCode: json['country_code'] as String?,
    );
  }

  final String role;
  final String? countryCode;
}

class AdminCapabilities {
  const AdminCapabilities({
    required this.canAccessAdmin,
    required this.isSuperAdmin,
    required this.isCountryAdmin,
    required this.isSupportAdmin,
    required this.isCurriculumStaff,
    required this.roles,
    this.isFinanceAdmin = false,
    this.isContentAdmin = false,
    this.isAnalyticsAdmin = false,
    this.isSecurityAdmin = false,
    this.isMfaEnrolled = false,
    this.assignedCountries = const [],
  });

  const AdminCapabilities.empty()
    : canAccessAdmin = false,
      isSuperAdmin = false,
      isCountryAdmin = false,
      isSupportAdmin = false,
      isCurriculumStaff = false,
      isFinanceAdmin = false,
      isContentAdmin = false,
      isAnalyticsAdmin = false,
      isSecurityAdmin = false,
      isMfaEnrolled = false,
      assignedCountries = const [],
      roles = const [];

  factory AdminCapabilities.fromJson(Map<String, dynamic> json) {
    final rawRoles = (json['roles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminRoleAssignment.fromJson)
        .toList();

    final roleNames = rawRoles.map((r) => r.role.toLowerCase()).toSet();
    final isSuper = (json['is_super_admin'] as bool? ?? false) ||
        roleNames.contains('super_admin');
    final isCountry = (json['is_country_admin'] as bool? ?? false) ||
        roleNames.contains('country_admin');
    final isSupport = (json['is_support_admin'] as bool? ?? false) ||
        roleNames.contains('support_admin');
    final isCurriculum = (json['is_curriculum_staff'] as bool? ?? false) ||
        roleNames.contains('curriculum_admin') ||
        roleNames.contains('curriculum_editor');
    final isFinance = roleNames.contains('finance_admin');
    final isContent = roleNames.contains('content_admin');
    final isAnalytics = roleNames.contains('analytics_admin');
    final isSecurity = roleNames.contains('security_admin');

    final canAccess = (json['can_access_admin'] as bool? ?? false) ||
        isSuper ||
        isCountry ||
        isSupport ||
        isCurriculum ||
        isFinance ||
        isContent ||
        isAnalytics ||
        isSecurity;

    final countries = rawRoles
        .map((r) => r.countryCode)
        .whereType<String>()
        .toSet()
        .toList();

    return AdminCapabilities(
      canAccessAdmin: canAccess,
      isSuperAdmin: isSuper,
      isCountryAdmin: isCountry,
      isSupportAdmin: isSupport,
      isCurriculumStaff: isCurriculum,
      isFinanceAdmin: isFinance,
      isContentAdmin: isContent,
      isAnalyticsAdmin: isAnalytics,
      isSecurityAdmin: isSecurity,
      isMfaEnrolled: json['mfa_enrolled'] as bool? ?? true,
      assignedCountries: countries,
      roles: rawRoles,
    );
  }

  final bool canAccessAdmin;
  final bool isSuperAdmin;
  final bool isCountryAdmin;
  final bool isSupportAdmin;
  final bool isCurriculumStaff;
  final bool isFinanceAdmin;
  final bool isContentAdmin;
  final bool isAnalyticsAdmin;
  final bool isSecurityAdmin;
  final bool isMfaEnrolled;
  final List<String> assignedCountries;
  final List<AdminRoleAssignment> roles;

  bool get canManageAccountRequests => isSuperAdmin || isSupportAdmin;
  bool get canManageCountries => isSuperAdmin;
  bool get canManageInvitations => isSuperAdmin || isSecurityAdmin;
  bool get canManageCms => isSuperAdmin || isContentAdmin || isCurriculumStaff;
  bool get canManageExams => isSuperAdmin || isContentAdmin || isCountryAdmin;
  bool get canViewFinance => isSuperAdmin || isFinanceAdmin;
  bool get canViewAnalytics => isSuperAdmin || isAnalyticsAdmin || isCountryAdmin;
  bool get canAuditSecurity => isSuperAdmin || isSecurityAdmin;

  bool hasCountryAccess(String countryCode) {
    if (isSuperAdmin) return true;
    return assignedCountries.contains(countryCode.toUpperCase());
  }
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.enabledCountries,
    required this.parentAccounts,
    required this.activeLearners,
    required this.pendingAccountRequests,
    required this.pendingCurriculumImports,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      enabledCountries: (json['enabled_countries'] as num?)?.toInt() ?? 0,
      parentAccounts: (json['parent_accounts'] as num?)?.toInt() ?? 0,
      activeLearners: (json['active_learners'] as num?)?.toInt() ?? 0,
      pendingAccountRequests:
          (json['pending_account_requests'] as num?)?.toInt() ?? 0,
      pendingCurriculumImports:
          (json['pending_curriculum_imports'] as num?)?.toInt() ?? 0,
    );
  }

  final int enabledCountries;
  final int parentAccounts;
  final int activeLearners;
  final int pendingAccountRequests;
  final int pendingCurriculumImports;
}

class AdminAccountRequest {
  const AdminAccountRequest({
    required this.userId,
    required this.fullName,
    required this.status,
    required this.requestedAt,
    this.countryCode,
    this.requestReason,
  });

  factory AdminAccountRequest.fromJson(Map<String, dynamic> json) {
    return AdminAccountRequest(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      countryCode: json['country_code'] as String?,
      status: json['status'] as String,
      requestReason: json['request_reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }

  final String userId;
  final String fullName;
  final String? countryCode;
  final String status;
  final String? requestReason;
  final DateTime requestedAt;
}

class AdminAuditLogEntry {
  const AdminAuditLogEntry({
    required this.id,
    required this.action,
    required this.metadata,
    required this.createdAt,
    this.actorUserId,
    this.targetUserId,
    this.resourceType = 'system',
    this.resourceId,
    this.ipAddress,
  });

  factory AdminAuditLogEntry.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return AdminAuditLogEntry(
      id: (json['id'] as num).toInt(),
      actorUserId: json['actor_user_id'] as String? ?? json['admin_id'] as String?,
      targetUserId: json['target_user_id'] as String?,
      resourceType: json['resource_type'] as String? ?? 'system',
      resourceId: json['resource_id'] as String?,
      ipAddress: json['ip_address'] as String?,
      action: json['action'] as String,
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String? actorUserId;
  final String? targetUserId;
  final String resourceType;
  final String? resourceId;
  final String? ipAddress;
  final String action;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

/// Logical entity: admin_profiles
class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accountStatus,
    required this.mfaEnrolled,
    required this.createdAt,
    this.authUserId,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accountStatus: json['account_status'] as String? ?? 'PENDING_VERIFICATION',
      mfaEnrolled: json['mfa_enrolled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String? authUserId;
  final String fullName;
  final String email;
  final String accountStatus;
  final bool mfaEnrolled;
  final DateTime createdAt;

  bool get isActive => accountStatus == 'ACTIVE';
}

/// Logical entity: admin_invitations
class AdminInvitation {
  const AdminInvitation({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleName,
    required this.expiresAt,
    required this.createdAt,
    this.countryScope,
    this.token,
    this.acceptedAt,
    this.revokedAt,
  });

  factory AdminInvitation.fromJson(Map<String, dynamic> json) {
    return AdminInvitation(
      id: json['id'] as String? ?? json['invitation_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      roleName: json['role_name'] as String? ?? json['role'] as String? ?? '',
      countryScope: json['country_scope'] as String?,
      token: json['token'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String roleName;
  final String? countryScope;
  final String? token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;

  bool get isAccepted => acceptedAt != null;
  bool get isRevoked => revokedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => !isAccepted && !isRevoked && !isExpired;
}

/// Country metrics breakdown
class AdminCountryStat {
  const AdminCountryStat({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.isEnabled,
    required this.learnerCount,
    required this.parentCount,
  });

  factory AdminCountryStat.fromJson(Map<String, dynamic> json) {
    return AdminCountryStat(
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? false,
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      parentCount: (json['parent_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String countryCode;
  final String countryName;
  final String currencyCode;
  final bool isEnabled;
  final int learnerCount;
  final int parentCount;
}

/// Comprehensive metrics for the Super Admin Control Centre
class SuperAdminControlCentreStats {
  const SuperAdminControlCentreStats({
    required this.totalLearners,
    required this.totalParents,
    required this.totalSubscriptions,
    required this.totalExams,
    required this.totalAdmins,
    required this.activeCountries,
    required this.openTickets,
    required this.systemHealth,
    required this.countryBreakdown,
    required this.recentAudits,
  });

  factory SuperAdminControlCentreStats.fromJson(Map<String, dynamic> json) {
    final rawCountries = (json['country_breakdown'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminCountryStat.fromJson)
        .toList();

    final rawAudits = (json['recent_audits'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminAuditLogEntry.fromJson)
        .toList();

    return SuperAdminControlCentreStats(
      totalLearners: (json['total_learners'] as num?)?.toInt() ?? 0,
      totalParents: (json['total_parents'] as num?)?.toInt() ?? 0,
      totalSubscriptions: (json['total_subscriptions'] as num?)?.toInt() ?? 0,
      totalExams: (json['total_exams'] as num?)?.toInt() ?? 0,
      totalAdmins: (json['total_admins'] as num?)?.toInt() ?? 0,
      activeCountries: (json['active_countries'] as num?)?.toInt() ?? 0,
      openTickets: (json['open_tickets'] as num?)?.toInt() ?? 0,
      systemHealth: json['system_health'] as String? ?? 'OPERATIONAL',
      countryBreakdown: rawCountries,
      recentAudits: rawAudits,
    );
  }

  final int totalLearners;
  final int totalParents;
  final int totalSubscriptions;
  final int totalExams;
  final int totalAdmins;
  final int activeCountries;
  final int openTickets;
  final String systemHealth;
  final List<AdminCountryStat> countryBreakdown;
  final List<AdminAuditLogEntry> recentAudits;
}

/// TOTP MFA Enrolment payload
class AdminMfaSetupData {
  const AdminMfaSetupData({
    required this.secretKey,
    required this.otpAuthUri,
    required this.recoveryCodes,
  });

  final String secretKey;
  final String otpAuthUri;
  final List<String> recoveryCodes;
}
