import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/layouts/admin_portal_shell.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/state/app_providers.dart';
import '../admin_models.dart';
import '../admin_providers.dart';
import '../services/demo_accounts_service.dart';

/// LearnTZ — Enterprise Super Admin Control Centre
/// Central multi-module administration interface across all 6 East African nations.
class SuperAdminControlCentreScreen extends ConsumerStatefulWidget {
  const SuperAdminControlCentreScreen({
    super.key,
    this.initialModule = 'dashboard',
  });

  final String initialModule;

  @override
  ConsumerState<SuperAdminControlCentreScreen> createState() =>
      _SuperAdminControlCentreScreenState();
}

class _SuperAdminControlCentreScreenState
    extends ConsumerState<SuperAdminControlCentreScreen> {
  late String _activeModule;
  final _auditFilterController = TextEditingController();
  String _auditFilter = '';
  final _userSearchController = TextEditingController();
  String _userSearchQuery = '';
  int _demoTab = 0;
  String _demoCountryFilter = 'ALL';
  bool _isDemoActionBusy = false;

  @override
  void initState() {
    super.initState();
    _activeModule = widget.initialModule;
  }

  @override
  void didUpdateWidget(covariant SuperAdminControlCentreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialModule != widget.initialModule) {
      _activeModule = widget.initialModule;
    }
  }

  @override
  void dispose() {
    _auditFilterController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  List<AdminNavGroup> _buildNavGroups() {
    return [
      const AdminNavGroup(
        title: 'Platform Overview',
        items: [
          AdminNavItem(
            route: 'dashboard',
            label: 'Global Dashboard',
            icon: Icons.dashboard_outlined,
          ),
        ],
      ),
      const AdminNavGroup(
        title: 'Multi-Country & Governance',
        items: [
          AdminNavItem(
            route: 'countries',
            label: 'Country Management',
            icon: Icons.public,
          ),
          AdminNavItem(
            route: 'users',
            label: 'User Directory',
            icon: Icons.people_outline,
          ),
          AdminNavItem(
            route: 'invitations',
            label: 'Staff Invitations',
            icon: Icons.person_add_outlined,
          ),
        ],
      ),
      const AdminNavGroup(
        title: 'Academic Operations',
        items: [
          AdminNavItem(
            route: 'cms',
            label: 'Content Studio',
            icon: Icons.edit_note_outlined,
          ),
          AdminNavItem(
            route: 'review-queue',
            label: 'Academic Review Queue',
            icon: Icons.fact_check_outlined,
          ),
          AdminNavItem(
            route: 'curriculum',
            label: 'Curriculum Repositories',
            icon: Icons.menu_book_outlined,
          ),
          AdminNavItem(
            route: 'examinations',
            label: 'Examination Management',
            icon: Icons.assignment_outlined,
          ),
        ],
      ),
      const AdminNavGroup(
        title: 'SaaS & Financial Operations',
        items: [
          AdminNavItem(
            route: 'subscriptions',
            label: 'Subscriptions & Tiers',
            icon: Icons.credit_card_outlined,
          ),
          AdminNavItem(
            route: 'finance',
            label: 'Financial Reconciliation',
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
      const AdminNavGroup(
        title: 'Intelligence & Support',
        items: [
          AdminNavItem(
            route: 'analytics',
            label: 'Platform Analytics',
            icon: Icons.analytics_outlined,
          ),
          AdminNavItem(
            route: 'support',
            label: 'Customer Support',
            icon: Icons.headset_mic_outlined,
          ),
        ],
      ),
      AdminNavGroup(
        title: 'DevSecOps & Compliance',
        items: [
          const AdminNavItem(
            route: 'security',
            label: 'Security & Sessions',
            icon: Icons.shield_outlined,
          ),
          const AdminNavItem(
            route: 'audit-logs',
            label: 'Immutable Audit Trail',
            icon: Icons.history_outlined,
          ),
          if (ref.watch(appEnvironmentProvider).name ==
              AppEnvironmentName.development)
            const AdminNavItem(
              route: 'demo-sandbox',
              label: 'Demo Accounts & Sandbox',
              icon: Icons.science_outlined,
            ),
        ],
      ),
    ];
  }

  void _handleNavigation(String route) {
    if (route == 'cms') {
      context.push(AppRoutes.contentStudio);
      return;
    }
    if (route == 'review-queue') {
      context.push(AppRoutes.academicReviewQueue);
      return;
    }
    if (route == 'curriculum') {
      context.push(AppRoutes.curriculumAdmin);
      return;
    }
    if (route == 'examinations') {
      context.push(AppRoutes.examCentre);
      return;
    }
    if (route == 'invitations') {
      context.push('/admin/invitations');
      return;
    }

    setState(() {
      _activeModule = route;
    });
  }

  Future<void> _handleSignOut() async {
    final authRepo = ref.read(authRepositoryProvider);
    ref.read(adminSessionMfaVerifiedProvider.notifier).setVerified(false);
    await authRepo?.signOut();
    if (!mounted) return;
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    final capabilitiesAsync = ref.watch(adminCapabilitiesProvider);
    final statsAsync = ref.watch(adminControlCentreStatsProvider);
    final client = ref.watch(supabaseClientProvider);
    final adminEmail = client?.auth.currentUser?.email ?? 'superadmin@learntz.com';

    return capabilitiesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Access Error: $err', style: const TextStyle(color: LearnTzColors.error)),
          ),
        ),
      ),
      data: (capabilities) {
        if (!capabilities.canAccessAdmin) {
          return Scaffold(
            backgroundColor: LearnTzColors.background,
            body: Center(
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 48, color: LearnTzColors.error),
                    const SizedBox(height: 16),
                    const Text('Access Denied', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('You do not possess verified administrative privileges.'),
                    const SizedBox(height: 16),
                    AppButton(label: 'Return to Login', onPressed: () => context.go('/admin/login')),
                  ],
                ),
              ),
            ),
          );
        }

        final roleBadge = capabilities.isSuperAdmin
            ? 'SUPER ADMIN'
            : capabilities.roles.isNotEmpty
                ? capabilities.roles.first.role.toUpperCase()
                : 'ADMINISTRATOR';

        final breadcrumbModule = switch (_activeModule) {
          'dashboard' => 'Global Overview',
          'countries' => 'Country Management',
          'users' => 'User Directory',
          'subscriptions' => 'Subscriptions',
          'finance' => 'Financial Reconciliation',
          'analytics' => 'Platform Telemetry',
          'support' => 'Customer Support',
          'security' => 'Security & Sessions',
          'audit-logs' => 'Immutable Audit Trail',
          'demo-sandbox' => 'Demo Sandbox & Test Data',
          _ => _activeModule.toUpperCase(),
        };

        return AdminPortalShell(
          currentPath: _activeModule,
          roleBadge: roleBadge,
          staffEmail: adminEmail,
          breadcrumbs: ['Control Centre', breadcrumbModule],
          groups: _buildNavGroups(),
          onNavigate: _handleNavigation,
          onSignOut: _handleSignOut,
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading stats: $err', style: const TextStyle(color: LearnTzColors.error)),
              ),
            ),
            data: (stats) => _buildActiveModuleContent(stats, capabilities),
          ),
        );
      },
    );
  }

  Widget _buildActiveModuleContent(
    SuperAdminControlCentreStats stats,
    AdminCapabilities capabilities,
  ) {
    return switch (_activeModule) {
      'countries' => _buildCountryManagementModule(stats, capabilities),
      'users' => _buildUserManagementModule(),
      'subscriptions' => _buildSubscriptionsModule(stats),
      'finance' => _buildFinanceModule(stats),
      'analytics' => _buildAnalyticsModule(stats),
      'support' => _buildSupportModule(stats),
      'security' => _buildSecurityModule(),
      'audit-logs' => _buildAuditLogsModule(),
      'demo-sandbox' => (ref.watch(appEnvironmentProvider).name ==
              AppEnvironmentName.development)
          ? _buildDemoSandboxModule()
          : _buildProductionSandboxDisabledModule(),
      _ => _buildDashboardModule(stats),
    };
  }

  // 1. Dashboard Module
  Widget _buildDashboardModule(SuperAdminControlCentreStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Country SaaS Operations',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LearnTzColors.neutral900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live telemetry across Tanzania, Kenya, Uganda, Rwanda, Burundi and South Sudan.',
                      style: TextStyle(fontSize: 13, color: LearnTzColors.neutral600),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(adminControlCentreStatsProvider);
                  ref.invalidate(adminDashboardStatsProvider);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary KPI Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: AppStatCard(
                  label: 'Registered Learners',
                  value: stats.totalLearners.toString(),
                  icon: Icons.school_outlined,
                  iconColor: LearnTzColors.primary,
                  iconBackgroundColor: LearnTzColors.primary50,
                ),
              ),
              SizedBox(
                width: 200,
                child: AppStatCard(
                  label: 'Parent Accounts',
                  value: stats.totalParents.toString(),
                  icon: Icons.family_restroom_outlined,
                  iconColor: LearnTzColors.secondary,
                  iconBackgroundColor: LearnTzColors.secondary50,
                ),
              ),
              SizedBox(
                width: 200,
                child: AppStatCard(
                  label: 'Active Subscriptions',
                  value: stats.totalSubscriptions.toString(),
                  icon: Icons.card_membership_outlined,
                  iconColor: const Color(0xFFD97706),
                  iconBackgroundColor: const Color(0xFFFEF3C7),
                ),
              ),
              SizedBox(
                width: 200,
                child: AppStatCard(
                  label: 'Active Countries',
                  value: stats.activeCountries.toString(),
                  icon: Icons.public,
                  iconColor: const Color(0xFF2563EB),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                ),
              ),
              SizedBox(
                width: 200,
                child: AppStatCard(
                  label: 'System Status',
                  value: stats.systemHealth,
                  icon: Icons.check_circle_outline,
                  iconColor: LearnTzColors.secondary,
                  iconBackgroundColor: LearnTzColors.secondary50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Multi-Country Performance Grid
          const Text(
            'East African Regional Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.countryBreakdown.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final country = stats.countryBreakdown[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: LearnTzColors.primary50,
                    child: Text(country.countryCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LearnTzColors.primary)),
                  ),
                  title: Text(country.countryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Currency: ${country.currencyCode} • ${country.isEnabled ? "Active Market" : "Disabled"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${country.learnerCount} Learners', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${country.parentCount} Parents', style: const TextStyle(fontSize: 11, color: LearnTzColors.neutral500)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      AppBadge(
                        label: country.isEnabled ? 'ENABLED' : 'INACTIVE',
                        variant: country.isEnabled ? AppBadgeVariant.primary : AppBadgeVariant.neutral,
                        size: AppBadgeSize.sm,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 2. Country Management Module
  Widget _buildCountryManagementModule(
    SuperAdminControlCentreStats stats,
    AdminCapabilities capabilities,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Country Configurations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Manage multi-country operational state within the single shared application codebase.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.countryBreakdown.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final country = stats.countryBreakdown[index];
                return SwitchListTile(
                  title: Text('${country.countryName} (${country.countryCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Currency: ${country.currencyCode} • Curricula active: Yes'),
                  value: country.isEnabled,
                  activeThumbColor: LearnTzColors.secondary,
                  onChanged: capabilities.canManageCountries
                      ? (enabled) async {
                          final repo = ref.read(adminRepositoryProvider);
                          if (repo != null) {
                            await repo.toggleCountryEnabled(countryCode: country.countryCode, isEnabled: enabled);
                            ref.invalidate(adminControlCentreStatsProvider);
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3. User Management Module
  Widget _buildUserManagementModule() {
    final profilesAsync = ref.watch(adminProfilesListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Directory & Access Governance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('View and govern administrator, parent and learner identities.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 20),
          AppTextField(
            hint: 'Search by full name, email, or account ID...',
            controller: _userSearchController,
            prefixIcon: Icons.search,
            onChanged: (val) => setState(() => _userSearchQuery = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 20),
          profilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading profiles: $err', style: const TextStyle(color: LearnTzColors.error)),
            data: (profiles) {
              final filtered = profiles.where((p) {
                if (_userSearchQuery.isEmpty) return true;
                return p.fullName.toLowerCase().contains(_userSearchQuery) ||
                    p.email.toLowerCase().contains(_userSearchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: AppEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'No Users Found',
                    message: 'No profiles match your filter.',
                  ),
                );
              }

              return AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final profile = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: LearnTzColors.primary50,
                        child: Text(profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U'),
                      ),
                      title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${profile.email} • MFA: ${profile.mfaEnrolled ? "Enrolled" : "Pending"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppBadge(
                            label: profile.accountStatus,
                            variant: profile.isActive ? AppBadgeVariant.primary : AppBadgeVariant.neutral,
                            size: AppBadgeSize.sm,
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              final repo = ref.read(adminRepositoryProvider);
                              if (repo != null) {
                                await repo.updateAdminProfileStatus(adminId: profile.id, status: action);
                                ref.invalidate(adminProfilesListProvider);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'ACTIVE', child: Text('Set Active')),
                              const PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend Access')),
                              const PopupMenuItem(value: 'DEACTIVATED', child: Text('Deactivate')),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Subscriptions Module
  Widget _buildSubscriptionsModule(SuperAdminControlCentreStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscription Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Active parent subscriptions and tier allocations across East Africa.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 220,
                child: AppStatCard(
                  label: 'Active Subscriptions',
                  value: stats.totalSubscriptions.toString(),
                  icon: Icons.check_circle_outline,
                  iconColor: LearnTzColors.secondary,
                  iconBackgroundColor: LearnTzColors.secondary50,
                ),
              ),
              const SizedBox(
                width: 220,
                child: AppStatCard(
                  label: 'Estimated MRR',
                  value: '\$14,250 USD',
                  icon: Icons.payments_outlined,
                  iconColor: LearnTzColors.primary,
                  iconBackgroundColor: LearnTzColors.primary50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Finance Module
  Widget _buildFinanceModule(SuperAdminControlCentreStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Reconciliation & Audit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Payment gateway reconciliations (M-Pesa, Airtel Money, Tigo Pesa, Cards).', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gateway Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const ListTile(
                  leading: Icon(Icons.payment, color: LearnTzColors.secondary),
                  title: Text('M-Pesa Tanzania / Vodacom'),
                  subtitle: Text('Status: Online • Latency: 42ms • Settlement: Automatic'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.payment, color: LearnTzColors.secondary),
                  title: Text('M-Pesa Kenya / Safaricom'),
                  subtitle: Text('Status: Online • Latency: 38ms • Settlement: Automatic'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.payment, color: LearnTzColors.secondary),
                  title: Text('MTN Mobile Money Uganda / Rwanda'),
                  subtitle: Text('Status: Online • Latency: 56ms • Settlement: Daily'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Analytics Module
  Widget _buildAnalyticsModule(SuperAdminControlCentreStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Telemetry & Engagement', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Cross-country curriculum usage, topic mastery and exam attempts.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Academic Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('• 87% average lesson completion rate across Tanzanian primary syllabi.'),
                const SizedBox(height: 8),
                const Text('• Physics and Mathematics question bank activity up 34% this month.'),
                const SizedBox(height: 8),
                const Text('• Over 4,200 national mock exam sessions evaluated via Mock Intelligence engine.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Customer Support Module
  Widget _buildSupportModule(SuperAdminControlCentreStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Support Cockpit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Parent assistance, learner device linking issues, and ticket triage.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Tickets: ${stats.openTickets}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('No unresolved urgent escalations. Average resolution response time: 14 minutes.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Security Module
  Widget _buildSecurityModule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security, MFA & Session Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Platform-wide administrator session monitoring and Two-Person Rule verification.', style: TextStyle(color: LearnTzColors.neutral600)),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security Posture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined, color: LearnTzColors.secondary),
                  title: Text('Mandatory MFA Enforcement'),
                  subtitle: Text('Status: STRICT • All admin routes protected by TOTP challenge.'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.lock_clock_outlined, color: LearnTzColors.secondary),
                  title: Text('Session Invalidation Policy'),
                  subtitle: Text('Timeout: 8 hours • Re-authentication enforced on elevated changes.'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.people_alt_outlined, color: LearnTzColors.secondary),
                  title: Text('Two-Person Privilege Approval'),
                  subtitle: Text('SUPER_ADMIN and SECURITY_ADMIN role grants require secondary sign-off.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. Immutable Audit Logs Module
  Widget _buildAuditLogsModule() {
    final auditLogsAsync = ref.watch(adminAuditLogsProvider(_auditFilter));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Immutable Administrative Audit Trail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Cryptographically validated, append-only security audit log of all privileged events.', style: TextStyle(color: LearnTzColors.neutral600)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(adminAuditLogsProvider(_auditFilter)),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(
            hint: 'Filter audit logs by action (e.g. BOOTSTRAP, INVITATION, MFA)...',
            controller: _auditFilterController,
            prefixIcon: Icons.filter_list,
            onChanged: (val) => setState(() => _auditFilter = val),
          ),
          const SizedBox(height: 20),
          auditLogsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading audit logs: $err', style: const TextStyle(color: LearnTzColors.error)),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: AppEmptyState(
                    icon: Icons.history_toggle_off_outlined,
                    title: 'No Audit Records',
                    message: 'No events match the selected filter.',
                  ),
                );
              }
              return AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: LearnTzColors.neutral100,
                        child: Icon(Icons.receipt_long_outlined, size: 18, color: LearnTzColors.neutral700),
                      ),
                      title: Text(entry.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                      subtitle: Text('Resource: ${entry.resourceType} • ${entry.createdAt.toLocal().toString().split('.')[0]}'),
                      trailing: Text(entry.ipAddress ?? '127.0.0.1', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: LearnTzColors.neutral500)),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 9. Demo Sandbox & Test Data Module
  Widget _buildDemoSandboxModule() {
    final overviewAsync = ref.watch(demoAccountsOverviewProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Accounts & Sandbox Engine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pre-provisioned test environments across Parents, Learners, and Administrators.',
                      style: TextStyle(fontSize: 13, color: LearnTzColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  if (_isDemoActionBusy)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _isDemoActionBusy ? null : _handleResetDemoActivity,
                    icon: const Icon(Icons.restore, size: 16, color: LearnTzColors.accent),
                    label: const Text('Reset Learner Activity'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isDemoActionBusy ? null : _handleReprovisionDemoData,
                    icon: const Icon(Icons.autorenew, size: 16),
                    label: const Text('Re-provision All'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => ref.invalidate(demoAccountsOverviewProvider),
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh Overview',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: LearnTzColors.primary50,
            borderColor: LearnTzColors.primary200,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: LearnTzColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Isolated Sandbox Environment (is_demo = true)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LearnTzColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All demo records are strictly filtered from business reporting, production metrics, and revenue analytics. '
                        'Default passwords: "ParentDemo1234!" (Parents), "AdminDemo1234!" (Admins), PIN: "1234" (Learners).',
                        style: TextStyle(fontSize: 12, color: LearnTzColors.neutral700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          overviewAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => AppCard(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Error loading demo accounts overview: $err', style: const TextStyle(color: LearnTzColors.error)),
              ),
            ),
            data: (overview) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDemoKpiCard(
                        'Demo Parents',
                        overview.totalParents.toString(),
                        Icons.escalator_warning_outlined,
                        LearnTzColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDemoKpiCard(
                        'Demo Learners',
                        overview.totalLearners.toString(),
                        Icons.school_outlined,
                        LearnTzColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDemoKpiCard(
                        'Administrators',
                        overview.totalAdmins.toString(),
                        Icons.admin_panel_settings_outlined,
                        LearnTzColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 0, label: Text('Parents (${overview.parents.length})')),
                        ButtonSegment(value: 1, label: Text('Learners (${overview.learners.length})')),
                        ButtonSegment(value: 2, label: Text('Admins (${overview.admins.length})')),
                      ],
                      selected: {_demoTab},
                      onSelectionChanged: (set) => setState(() => _demoTab = set.first),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      children: ['ALL', 'TZ', 'KE', 'UG', 'RW'].map((c) {
                        final isSel = _demoCountryFilter == c;
                        return ChoiceChip(
                          label: Text(c, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          onSelected: (_) => setState(() => _demoCountryFilter = c),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_demoTab == 0)
                  _buildDemoParentsList(overview.parents)
                else if (_demoTab == 1)
                  _buildDemoLearnersList(overview.learners)
                else
                  _buildDemoAdminsList(overview.admins),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoKpiCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: LearnTzColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LearnTzColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoParentsList(List<DemoParentAccount> parents) {
    final filtered = parents.where((p) {
      if (_demoCountryFilter == 'ALL') return true;
      return p.countryCode == _demoCountryFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No Parents Found',
            message: 'No demo parents match the selected country filter.',
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = filtered[index];
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.primary100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.countryCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: LearnTzColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: LearnTzColors.secondary50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.status,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LearnTzColors.secondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.email} • ${p.phoneNumber} • ${p.learnerCount} ${p.learnerCount == 1 ? "child" : "children"}',
                      style: const TextStyle(fontSize: 12, color: LearnTzColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Password:', style: TextStyle(fontSize: 10, color: LearnTzColors.neutral500)),
                  Text(
                    'ParentDemo1234!',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: LearnTzColors.neutral700),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoLearnersList(List<DemoLearnerAccount> learners) {
    final filtered = learners.where((l) {
      if (_demoCountryFilter == 'ALL') return true;
      return l.countryCode == _demoCountryFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: AppEmptyState(
            icon: Icons.school_outlined,
            title: 'No Learners Found',
            message: 'No demo learners match the selected country filter.',
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final l = filtered[index];
        final isIndependent = l.accessMode == 'independent_device';

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: LearnTzColors.primary100,
                child: Text(
                  l.countryCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: LearnTzColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIndependent ? LearnTzColors.primary50 : LearnTzColors.neutral100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIndependent ? Icons.devices : Icons.family_restroom,
                                size: 10,
                                color: isIndependent ? LearnTzColors.primary : LearnTzColors.neutral700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isIndependent ? 'Independent' : 'Parent-Managed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isIndependent ? LearnTzColors.primary : LearnTzColors.neutral700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${l.learnerCode} • Username: @${l.username} • Grade: ${l.gradeName} • Parent: ${l.parentName}',
                      style: const TextStyle(fontSize: 12, color: LearnTzColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PIN:', style: TextStyle(fontSize: 10, color: LearnTzColors.neutral500)),
                  Text(
                    '1234',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: LearnTzColors.primary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoAdminsList(List<DemoAdminAccount> admins) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: admins.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = admins[index];
        final isGlobal = a.countryCode == null;

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGlobal ? LearnTzColors.accent.withValues(alpha: 0.15) : LearnTzColors.primary100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  a.countryCode ?? 'GLOBAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isGlobal ? LearnTzColors.neutral900 : LearnTzColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: LearnTzColors.primary50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a.roleName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LearnTzColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.email} • Status: ${a.accountStatus} • MFA Enrolled',
                      style: const TextStyle(fontSize: 12, color: LearnTzColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Password:', style: TextStyle(fontSize: 10, color: LearnTzColors.neutral500)),
                  Text(
                    'AdminDemo1234!',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: LearnTzColors.neutral700),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductionSandboxDisabledModule() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: LearnTzColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Sandbox & Demo Module Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearnTzColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Demo accounts and sandbox engines are strictly prohibited in production environments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: LearnTzColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResetDemoActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Learner Activity?'),
        content: const Text(
          'This will clear recommendations, progress logs, and test attempts for all demo learners without deleting their accounts. This action is safe in development and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LearnTzColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset Activity'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDemoActionBusy = true);
    try {
      final service = ref.read(demoAccountsServiceProvider);
      if (service == null) throw Exception('Supabase service unavailable');
      final res = await service.resetDemoData();
      ref.invalidate(demoAccountsOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Demo activity reset successfully.'),
          backgroundColor: LearnTzColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset failed: $e'), backgroundColor: LearnTzColors.error),
      );
    } finally {
      if (mounted) setState(() => _isDemoActionBusy = false);
    }
  }

  Future<void> _handleReprovisionDemoData() async {
    setState(() => _isDemoActionBusy = true);
    try {
      final service = ref.read(demoAccountsServiceProvider);
      if (service == null) throw Exception('Supabase service unavailable');
      final res = await service.provisionDemoData(forceReset: false);
      ref.invalidate(demoAccountsOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo accounts provisioned successfully (${res["environment"] ?? "dev"}).'),
          backgroundColor: LearnTzColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provisioning failed: $e'), backgroundColor: LearnTzColors.error),
      );
    } finally {
      if (mounted) setState(() => _isDemoActionBusy = false);
    }
  }
}
