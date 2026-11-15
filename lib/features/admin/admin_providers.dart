import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import 'admin_models.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AdminRepository(client);
});

final adminCapabilitiesProvider = FutureProvider<AdminCapabilities>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) return const AdminCapabilities.empty();
  return repository.getCapabilities();
});

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getDashboardStats();
});

final adminControlCentreStatsProvider = FutureProvider<SuperAdminControlCentreStats>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getControlCentreStats();
});

final adminAccountRequestsProvider =
    FutureProvider<List<AdminAccountRequest>>((ref) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(adminRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listAccountRequests();
    });

final adminAuditLogsProvider =
    FutureProvider.family<List<AdminAuditLogEntry>, String?>((
      ref,
      actionFilter,
    ) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(adminRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listAuditLogs(actionFilter: actionFilter);
    });

final adminCountriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) return [];
  return repository.listAllCountries();
});

final adminInvitationsProvider =
    FutureProvider<List<AdminInvitation>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) return [];
  return repository.listInvitations();
});

final adminProfilesListProvider =
    FutureProvider<List<AdminProfile>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) return [];
  return repository.listAdminProfiles();
});

/// Administrative session MFA status in current memory session
final adminSessionMfaVerifiedProvider =
    NotifierProvider<AdminSessionMfaNotifier, bool>(
      AdminSessionMfaNotifier.new,
    );

class AdminSessionMfaNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setVerified(bool value) => state = value;
}
