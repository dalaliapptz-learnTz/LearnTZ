import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/design_system/components/components.dart' as ds;
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../admin/admin_providers.dart';
import '../curriculum/curriculum_providers.dart';
import '../gamification/gamification_models.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/widgets/gamification_widgets.dart';
import '../learning/learning_models.dart';
import '../learning/learning_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../learners/learner_models.dart';
import '../learners/learner_providers.dart';
import '../auth/auth_screens.dart';
import 'account_providers.dart';
import 'account_repository.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  String _initials(String name, String email) {
    final clean = name.trim();
    if (clean.isNotEmpty) {
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'LT';
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider)?.signOut();
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
    final profile = ref.watch(parentProfileProvider);
    final learners = ref.watch(parentLearnersProvider);
    final overviewAsync = ref.watch(parentDashboardOverviewProvider);
    final gamificationAsync = ref.watch(parentChildrenGamificationSummaryProvider);
    final adminAccess = ref.watch(adminCapabilitiesProvider);
    final curriculumAccess = ref.watch(curriculumStaffCapabilitiesProvider);
    final incomingInvitations = ref.watch(incomingGuardianInvitationsProvider);

    final canAccessAdmin = adminAccess.asData?.value.canAccessAdmin ?? false;
    final canAccessCurriculum =
        curriculumAccess.asData?.value.canAccess ?? false;
    final hasStaffWorkspaces = canAccessAdmin || canAccessCurriculum;

    final learnerList = learners.asData?.value ?? const <Learner>[];
    final overviewList = overviewAsync.asData?.value ?? const <ParentLearnerOverview>[];
    final gamifList = gamificationAsync.asData?.value ?? const <ParentChildGamificationSummary>[];

    return Container(
      color: LearnTzColors.background,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Warm Full-Width Identity & Status Header Card
                      _buildIdentityHeader(
                        context: context,
                        l10n: l10n,
                        profile: profile,
                        email: user?.email ?? '',
                        canAccessAdmin: canAccessAdmin,
                        canAccessCurriculum: canAccessCurriculum,
                      ),
                      const SizedBox(height: 14),

                      // Incoming Guardian Invitations (if any)
                      incomingInvitations.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (invitations) => invitations.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _IncomingInvitationsCard(
                                  invitations: invitations,
                                ),
                              ),
                      ),

                      // 2. Colourful Interactive Family Quick Analytics Snapshot KPIs
                      _FamilyQuickAnalyticsStrip(
                        learners: learnerList,
                        overviews: overviewList,
                        gamification: gamifList,
                      ),
                      const SizedBox(height: 18),

                      // 3. Learners At-a-Glance Visual Snapshot Cards
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learners at a Glance',
                                  style: LearnTzTypography.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Track mastery, streaks, XP, and recent badges in one view.',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ds.AppButton(
                            label: l10n.addLearnerAction,
                            icon: Icons.person_add_alt_1_rounded,
                            variant: ds.AppButtonVariant.primary,
                            size: ds.AppButtonSize.sm,
                            onPressed: () => context.go(AppRoutes.addLearner),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      learners.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => AuthInlineMessage(
                          message: _accountErrorMessage(error, l10n),
                          isError: true,
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return _EmptyLearnersSnapshotCard(
                              l10n: l10n,
                              onAddLearner: () =>
                                  context.go(AppRoutes.addLearner),
                            );
                          }
                          final overviewById = {
                            for (final o in overviewList) o.learnerId: o,
                          };
                          final gamifById = {
                            for (final g in gamifList) g.learnerId: g,
                          };
                          return Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                _LearnerSnapshotAnalyticsCard(
                                  learner: items[i],
                                  overview: overviewById[items[i].id],
                                  gamification: gamifById[items[i].id],
                                  colorIndex: i,
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          );
                        },
                      ),

                      // 4. Role-Gated Staff & Academic Workspaces (only shown to staff/admins)
                      if (hasStaffWorkspaces) ...[
                        const SizedBox(height: 10),
                        _buildStaffWorkspacesSection(
                          context: context,
                          l10n: l10n,
                          canAccessAdmin: canAccessAdmin,
                          canAccessCurriculum: canAccessCurriculum,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Bottom Menu Icon Bar (Settings holds Edit profile, Subscriptions, Account settings, Sign out)
          _AccountBottomMenuBar(
            l10n: l10n,
            onOpenSettings: () => _showSettingsMenu(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: LearnTzTypography.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LearnTzColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('settings-menu-edit-profile'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0F4C81),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.editProfileAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Update your name and country details'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(AppRoutes.editParentProfile);
                },
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('settings-menu-subscriptions'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.credit_card_outlined,
                    color: Color(0xFF15803D),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.viewSubscriptionsAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Family subscription plan and billing'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(AppRoutes.subscriptions);
                },
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('settings-menu-account-settings'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF334155),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.accountSettingsAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Password, security, and account preferences'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(AppRoutes.accountSettings);
                },
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('settings-menu-sign-out'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.signOutAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
                subtitle: const Text('Sign out of your LearnTZ account'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _signOut(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required AsyncValue<ParentProfile> profile,
    required String email,
    required bool canAccessAdmin,
    required bool canAccessCurriculum,
  }) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LearnTzColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F4C81), Color(0xFF15803D)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: profile.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => AuthInlineMessage(
                message: _accountErrorMessage(error, l10n),
                isError: true,
              ),
              data: (value) {
                final initials = _initials(value.fullName, email);
                final displayName = value.fullName.trim().isNotEmpty
                    ? value.fullName
                        .trim()
                        .split(RegExp(r'\s+'))
                        .map((w) => w.isEmpty
                            ? w
                            : '${w[0].toUpperCase()}${w.substring(1)}')
                        .join(' ')
                    : l10n.parentDashboardTitle;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF0F4C81),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                displayName,
                                style: LearnTzTypography.h3.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: LearnTzColors.textPrimary,
                                ),
                              ),
                              ds.AppBadge(
                                label: value.countryCode,
                                variant: ds.AppBadgeVariant.neutral,
                                size: ds.AppBadgeSize.sm,
                              ),
                              if (canAccessAdmin)
                                const ds.AppBadge(
                                  label: 'Admin',
                                  variant: ds.AppBadgeVariant.primary,
                                  size: ds.AppBadgeSize.sm,
                                )
                              else if (canAccessCurriculum)
                                const ds.AppBadge(
                                  label: 'Curriculum Staff',
                                  variant: ds.AppBadgeVariant.success,
                                  size: ds.AppBadgeSize.sm,
                                )
                              else
                                const ds.AppBadge(
                                  label: 'Parent',
                                  variant: ds.AppBadgeVariant.primary,
                                  size: ds.AppBadgeSize.sm,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: LearnTzTypography.bodySmall.copyWith(
                              color: LearnTzColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffWorkspacesSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool canAccessAdmin,
    required bool canAccessCurriculum,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F4C81).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C81),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff & Academic Workspaces',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                    Text(
                      'Role-gated platform operations',
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (canAccessAdmin) ...[
            _WorkspaceShortcutTile(
              icon: Icons.dashboard_customize_outlined,
              title: l10n.adminPortalAction,
              subtitle: 'Platform users, countries & governance',
              onTap: () => context.go(AppRoutes.adminDashboard),
            ),
            const SizedBox(height: 8),
          ],
          _WorkspaceShortcutTile(
            icon: Icons.school_outlined,
            title: 'Examination Centre 2.0',
            subtitle: '5-step curriculum exams, bank & paper builder',
            onTap: () => context.push(AppRoutes.examCentreV2),
          ),
          const SizedBox(height: 8),
          _WorkspaceShortcutTile(
            icon: Icons.edit_note_outlined,
            title: 'Content Management Studio',
            subtitle: 'Author curriculum-aligned lessons & media',
            onTap: () => context.push(AppRoutes.contentStudio),
          ),
          const SizedBox(height: 8),
          _WorkspaceShortcutTile(
            icon: Icons.fact_check_outlined,
            title: 'Academic Review Queue',
            subtitle: 'Review, approve & publish submitted lessons',
            onTap: () => context.push(AppRoutes.academicReviewQueue),
          ),
          if (canAccessCurriculum) ...[
            const SizedBox(height: 8),
            _WorkspaceShortcutTile(
              icon: Icons.menu_book_outlined,
              title: l10n.curriculumAdminTitle,
              subtitle: 'Manage official national curricula & versions',
              onTap: () => context.go(AppRoutes.curriculumAdmin),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountBottomMenuBar extends StatelessWidget {
  const _AccountBottomMenuBar({
    required this.l10n,
    required this.onOpenSettings,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final items = <(
      String key,
      IconData icon,
      String label,
      bool isActive,
      VoidCallback onTap,
    )>[
      (
        'account-nav-home',
        Icons.home_rounded,
        'Home',
        true,
        () => context.go(AppRoutes.account),
      ),
      (
        'account-nav-learning',
        Icons.school_outlined,
        l10n.learningHubTitle,
        false,
        () => context.go(AppRoutes.learn),
      ),
      (
        'account-nav-progress',
        Icons.analytics_outlined,
        'Progress',
        false,
        () => context.go(AppRoutes.parentDashboard),
      ),
      (
        'account-nav-settings',
        Icons.settings_outlined,
        'Settings',
        false,
        onOpenSettings,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: InkWell(
                      key: Key(item.$1),
                      onTap: item.$5,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.$2,
                              size: 22,
                              color: item.$4
                                  ? const Color(0xFF0F4C81)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: item.$4
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: item.$4
                                    ? const Color(0xFF0F4C81)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyQuickAnalyticsStrip extends StatelessWidget {
  const _FamilyQuickAnalyticsStrip({
    required this.learners,
    required this.overviews,
    required this.gamification,
  });

  final List<Learner> learners;
  final List<ParentLearnerOverview> overviews;
  final List<ParentChildGamificationSummary> gamification;

  @override
  Widget build(BuildContext context) {
    final totalLearners = learners.length;
    final avgMastery = overviews.isEmpty
        ? 0
        : (overviews.fold<int>(0, (sum, o) => sum + o.masteryPercent) /
                overviews.length)
            .round();
    final totalXp = gamification.fold<int>(0, (sum, g) => sum + g.totalXp);
    final weeklyXp = gamification.fold<int>(0, (sum, g) => sum + g.weeklyXp);
    final bestStreak = gamification.fold<int>(
      overviews.fold<int>(0, (m, o) => o.streakDays > m ? o.streakDays : m),
      (m, g) => g.currentStreak > m ? g.currentStreak : m,
    );
    final totalBadges =
        gamification.fold<int>(0, (sum, g) => sum + g.earnedBadgesCount);

    final cards = <Widget>[
      _SnapshotKpiCard(
        icon: Icons.groups_rounded,
        title: 'Learners',
        accent: const Color(0xFF0F4C81),
        tint: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        onTap: () => context.go(AppRoutes.addLearner),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$totalLearners',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const Spacer(),
            if (learners.isNotEmpty)
              SizedBox(
                height: 26,
                width: (learners.take(3).length * 18.0) + 10,
                child: Stack(
                  children: [
                    for (var i = 0; i < learners.take(3).length; i++)
                      Positioned(
                        left: i * 16.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? const Color(0xFF0F4C81)
                                : const Color(0xFF15803D),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            learners[i].firstName.isNotEmpty
                                ? learners[i].firstName[0].toUpperCase()
                                : 'L',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        footer: Text(
          totalLearners == 1 ? 'Active profile' : 'Active profiles',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      _SnapshotKpiCard(
        icon: Icons.auto_graph_rounded,
        title: 'Avg Mastery',
        accent: const Color(0xFF15803D),
        tint: const Color(0xFFF0FDF4),
        border: const Color(0xFFBBF7D0),
        onTap: () => context.go(AppRoutes.parentDashboard),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$avgMastery%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: avgMastery.clamp(0, 100) / 100.0,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFDCFCE7),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                ),
              ),
            ),
          ],
        ),
        footer: const Text(
          'Curriculum progress',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      _SnapshotKpiCard(
        icon: Icons.bolt_rounded,
        title: 'Verified XP',
        accent: const Color(0xFFD97706),
        tint: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
        onTap: () => context.go(AppRoutes.parentDashboard),
        body: Text(
          '$totalXp XP',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        footer: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+$weeklyXp XP this week',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFFB45309),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      _SnapshotKpiCard(
        icon: Icons.emoji_events_rounded,
        title: 'Streaks & Badges',
        accent: const Color(0xFF6D28D9),
        tint: const Color(0xFFF5F3FF),
        border: const Color(0xFFDDD6FE),
        onTap: () => context.go(AppRoutes.parentDashboard),
        body: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: Color(0xFFEA580C),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${bestStreak}d',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: Color(0xFF6D28D9),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$totalBadges',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B21B6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        footer: Text(
          'Top streak · ${totalBadges == 1 ? '1 badge' : '$totalBadges badges'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 10.0;
        final width = (constraints.maxWidth - (spacing * (cols - 1))) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _SnapshotKpiCard extends StatelessWidget {
  const _SnapshotKpiCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.footer,
    required this.accent,
    required this.tint,
    required this.border,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final Widget footer;
  final Color accent;
  final Color tint;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, tint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              body,
              const SizedBox(height: 6),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLearnersSnapshotCard extends StatelessWidget {
  const _EmptyLearnersSnapshotCard({
    required this.l10n,
    required this.onAddLearner,
  });

  final AppLocalizations l10n;
  final VoidCallback onAddLearner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noLearnersTitle,
            textAlign: TextAlign.center,
            style: LearnTzTypography.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noLearnersDescription,
            textAlign: TextAlign.center,
            style: LearnTzTypography.bodySmall.copyWith(
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddLearner,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(l10n.addLearnerAction),
          ),
        ],
      ),
    );
  }
}

class _LearnerSnapshotAnalyticsCard extends ConsumerWidget {
  const _LearnerSnapshotAnalyticsCard({
    required this.learner,
    required this.overview,
    required this.gamification,
    required this.colorIndex,
  });

  final Learner learner;
  final ParentLearnerOverview? overview;
  final ParentChildGamificationSummary? gamification;
  final int colorIndex;

  static const _palettes = <(Color accent, Color tint, Color border)>[
    (Color(0xFF0F4C81), Color(0xFFEFF6FF), Color(0xFFBFDBFE)),
    (Color(0xFF15803D), Color(0xFFF0FDF4), Color(0xFFBBF7D0)),
    (Color(0xFFD97706), Color(0xFFFFFBEB), Color(0xFFFDE68A)),
    (Color(0xFF0D9488), Color(0xFFF0FDFA), Color(0xFF99F6E4)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(educationCatalogProvider).asData?.value;
    final palette = _palettes[colorIndex % _palettes.length];
    final accent = palette.$1;
    final tint = palette.$2;
    final border = palette.$3;

    final gradeName = overview?.gradeName.isNotEmpty == true
        ? overview!.gradeName
        : (catalog?.grade(learner.gradeId)?.name ?? '');
    final levelName = catalog?.level(learner.educationLevelId)?.name ?? '';
    final mastery = (overview?.masteryPercent ?? 0).clamp(0, 100);
    final completed = overview?.completedLessons ?? 0;
    final totalLessons = overview?.totalLessons ?? 0;
    final avgQuiz = overview?.averageQuizScorePercent ?? 0;
    final xp = gamification?.totalXp ?? 0;
    final streak = gamification?.currentStreak ?? overview?.streakDays ?? 0;
    final badgesCount = gamification?.earnedBadgesCount ?? 0;
    final recentBadges = gamification?.recentBadges ?? const <ParentChildBadgePreview>[];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colourful Top Accent Bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.55)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Visual Circular Mastery Ring + Learner Name + Quick Edit
                Row(
                  children: [
                    // Circular Mastery Progress Ring Graphic
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: mastery / 100.0,
                            strokeWidth: 6.5,
                            backgroundColor: tint,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$mastery%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                                const Text(
                                  'mastery',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                learner.fullName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _learnerStatus(learner.status, l10n),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [levelName, gradeName, learner.countryCode]
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.editLearnerAction,
                      onPressed: () =>
                          context.go(AppRoutes.editLearner(learner.id)),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Colourful Quick Analytics Metric Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickStatPill(
                      icon: Icons.menu_book_rounded,
                      label: '$completed/$totalLessons lessons',
                      color: const Color(0xFF0F4C81),
                      bg: const Color(0xFFEFF6FF),
                    ),
                    _QuickStatPill(
                      icon: Icons.quiz_rounded,
                      label: '$avgQuiz% quiz avg',
                      color: const Color(0xFF15803D),
                      bg: const Color(0xFFF0FDF4),
                    ),
                    _QuickStatPill(
                      icon: Icons.bolt_rounded,
                      label: '$xp XP',
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                    ),
                    _QuickStatPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${streak}d streak',
                      color: const Color(0xFFEA580C),
                      bg: const Color(0xFFFFF7ED),
                    ),
                    _QuickStatPill(
                      icon: Icons.emoji_events_rounded,
                      label: '$badgesCount badges',
                      color: const Color(0xFF6D28D9),
                      bg: const Color(0xFFF5F3FF),
                    ),
                  ],
                ),

                // Recent Earned Badges Preview (if any)
                if (recentBadges.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final b in recentBadges.take(3))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gamificationBadgeIcon(b.iconName),
                                size: 13,
                                color: gamificationTierColor(b.tier),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Direct Action Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(activeLearnerProvider.notifier)
                            .select(learner.id);
                        if (context.mounted) {
                          context.go(AppRoutes.learn);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(l10n.learningHubTitle),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go(AppRoutes.childDevices(learner.id)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.devices_outlined, size: 16),
                      label: const Text('Devices'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatPill extends StatelessWidget {
  const _QuickStatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceShortcutTile extends StatelessWidget {
  const _WorkspaceShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LearnTzColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0F4C81)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: LearnTzColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditParentProfileScreen extends ConsumerWidget {
  const EditParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(parentProfileProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(24),
            child: AuthInlineMessage(
              message: _accountErrorMessage(error, l10n),
              isError: true,
            ),
          ),
          data: (profile) =>
              _ProfileEditForm(key: ValueKey(profile.userId), profile: profile),
        );
  }
}

class _ProfileEditForm extends ConsumerStatefulWidget {
  const _ProfileEditForm({required this.profile, super.key});

  final ParentProfile profile;

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(accountRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await repository.updateFullName(_name.text);
      ref.invalidate(parentProfileProvider);
      if (mounted) context.go(AppRoutes.account);
    } on PostgrestException {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.requestFailed);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.editProfileTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.fullNameLabel),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : value.trim().length > 120
                        ? l10n.nameTooLong
                        : null,
                  ),
                  if (_error != null)
                    AuthInlineMessage(message: _error!, isError: true),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.saveChangesAction,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _statusFormKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _reason = TextEditingController();
  String? _emailMessage;
  String? _passwordMessage;
  String? _statusMessage;
  bool _emailMessageIsError = false;
  bool _passwordMessageIsError = false;
  bool _statusMessageIsError = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  bool _isRequestingStatus = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: ref.read(supabaseClientProvider)?.auth.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingEmail = true;
      _emailMessage = null;
      _emailMessageIsError = false;
    });
    try {
      await repository.requestEmailChange(_email.text);
      if (mounted) setState(() => _emailMessage = l10n.emailChangeRequested);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _emailMessage = error.message;
          _emailMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isUpdatingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingPassword = true;
      _passwordMessage = null;
      _passwordMessageIsError = false;
    });
    try {
      await repository.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (mounted) {
        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
        setState(() => _passwordMessage = l10n.passwordUpdated);
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _passwordMessage = error.message;
          _passwordMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _requestAccountStatus(String status) async {
    if (!_statusFormKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final isDeletion = status == 'deletion_requested';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDeletion
              ? l10n.requestDeletionTitle
              : l10n.requestDeactivationTitle,
        ),
        content: Text(
          isDeletion
              ? l10n.requestDeletionConfirmation
              : l10n.requestDeactivationConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.submitRequestAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _isRequestingStatus = true;
      _statusMessage = null;
      _statusMessageIsError = false;
    });
    try {
      await repository.requestAccountStatus(
        status: status,
        reason: _reason.text,
      );
      ref.invalidate(accountStatusProvider);
      if (mounted) setState(() => _statusMessage = l10n.accountRequestReceived);
    } on PostgrestException {
      if (mounted) {
        setState(() {
          _statusMessage = l10n.requestFailed;
          _statusMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isRequestingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(accountStatusProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.accountSettingsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.changeEmailTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: l10n.newEmailLabel,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => _validEmail(value, l10n),
                      ),
                      if (_emailMessage != null)
                        AuthInlineMessage(
                          message: _emailMessage!,
                          isError: _emailMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.requestEmailChangeAction,
                        onPressed: _isUpdatingEmail ? null : _updateEmail,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.changePasswordTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPassword,
                        decoration: InputDecoration(
                          labelText: l10n.currentPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassword,
                        decoration: InputDecoration(
                          labelText: l10n.newPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => _validPassword(value, l10n),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassword,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => value != _newPassword.text
                            ? l10n.passwordsDoNotMatch
                            : null,
                      ),
                      if (_passwordMessage != null)
                        AuthInlineMessage(
                          message: _passwordMessage!,
                          isError: _passwordMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.changePasswordAction,
                        onPressed: _isUpdatingPassword ? null : _changePassword,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Form(
                  key: _statusFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.accountRequestsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.accountRequestDescription),
                      const SizedBox(height: 12),
                      status.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => AuthInlineMessage(
                          message: _accountErrorMessage(error, l10n),
                          isError: true,
                        ),
                        data: (value) => Text(
                          l10n.accountStatusLabel(
                            _localizedStatus(value, l10n),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reason,
                        decoration: InputDecoration(
                          labelText: l10n.optionalRequestReasonLabel,
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) => (value?.length ?? 0) > 500
                            ? l10n.requestReasonTooLong
                            : null,
                      ),
                      if (_statusMessage != null)
                        AuthInlineMessage(
                          message: _statusMessage!,
                          isError: _statusMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed:
                            _isRequestingStatus ||
                                status.asData?.value != 'active'
                            ? null
                            : () => _requestAccountStatus(
                                'deactivation_requested',
                              ),
                        child: Text(l10n.requestDeactivationAction),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed:
                            _isRequestingStatus ||
                                status.asData?.value != 'active'
                            ? null
                            : () => _requestAccountStatus('deletion_requested'),
                        child: Text(l10n.requestDeletionAction),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _accountErrorMessage(Object error, AppLocalizations l10n) {
  if (error is AuthNotConfiguredException) return l10n.authNotConfiguredAction;
  if (error is NotSignedInException) return l10n.signInRequired;
  if (error is PostgrestException) return l10n.requestFailed;
  return l10n.requestFailed;
}

String? _validEmail(String? value, AppLocalizations l10n) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.requiredField;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : l10n.invalidEmail;
}

String? _validPassword(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.requiredField;
  return value.length >= 8 ? null : l10n.passwordMinimumLength;
}

String _localizedStatus(String value, AppLocalizations l10n) => switch (value) {
  'active' => l10n.accountStatusActive,
  'deactivation_requested' => l10n.accountStatusDeactivationRequested,
  'deletion_requested' => l10n.accountStatusDeletionRequested,
  'deactivated' => l10n.accountStatusDeactivated,
  'deleted' => l10n.accountStatusDeleted,
  _ => l10n.accountStatusUnknown,
};

String _learnerStatus(String value, AppLocalizations l10n) => switch (value) {
  'active' => l10n.learnerStatusActive,
  'inactive' => l10n.learnerStatusInactive,
  'deletion_requested' => l10n.learnerStatusDeletionRequested,
  _ => l10n.accountStatusUnknown,
};

class _IncomingInvitationsCard extends ConsumerWidget {
  const _IncomingInvitationsCard({required this.invitations});

  final List<IncomingGuardianInvitation> invitations;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String invitationId,
    bool accept,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(learnerRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.respondGuardianInvitation(
        invitationId: invitationId,
        accept: accept,
      );
      ref.invalidate(incomingGuardianInvitationsProvider);
      ref.invalidate(parentLearnersProvider);
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_add_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.incomingInvitationsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final inv in invitations) ...[
            Text(
              l10n.incomingInvitationPrompt(inv.inviterName, inv.learnerName),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _respond(context, ref, inv.id, true),
                  child: Text(l10n.acceptInvitationAction),
                ),
                OutlinedButton(
                  onPressed: () => _respond(context, ref, inv.id, false),
                  child: Text(l10n.declineInvitationAction),
                ),
              ],
            ),
            if (inv != invitations.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}
