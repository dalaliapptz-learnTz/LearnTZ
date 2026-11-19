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
    final adminAccess = ref.watch(adminCapabilitiesProvider);
    final curriculumAccess = ref.watch(curriculumStaffCapabilitiesProvider);
    final incomingInvitations = ref.watch(incomingGuardianInvitationsProvider);

    final canAccessAdmin = adminAccess.asData?.value.canAccessAdmin ?? false;
    final canAccessCurriculum =
        curriculumAccess.asData?.value.canAccess ?? false;
    final hasStaffWorkspaces = canAccessAdmin || canAccessCurriculum;
    final learnerCount = learners.asData?.value.length ?? 0;

    return Container(
      color: LearnTzColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full-Width Identity & Status Header Card
                _buildIdentityHeader(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  profile: profile,
                  email: user?.email ?? '',
                  canAccessAdmin: canAccessAdmin,
                  canAccessCurriculum: canAccessCurriculum,
                ),
                const SizedBox(height: 20),

                // 2. Responsive Two-Column Desktop Grid / Single-Column Mobile
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 880;
                    final mainColumn = _buildMainFamilyColumn(
                      context: context,
                      ref: ref,
                      l10n: l10n,
                      learners: learners,
                      learnerCount: learnerCount,
                      incomingInvitations: incomingInvitations,
                    );
                    final sideColumn = _buildSideWorkspacesColumn(
                      context: context,
                      l10n: l10n,
                      canAccessAdmin: canAccessAdmin,
                      canAccessCurriculum: canAccessCurriculum,
                      hasStaffWorkspaces: hasStaffWorkspaces,
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: mainColumn),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: sideColumn),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mainColumn,
                        const SizedBox(height: 20),
                        sideColumn,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required AsyncValue<ParentProfile> profile,
    required String email,
    required bool canAccessAdmin,
    required bool canAccessCurriculum,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: profile.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => AuthInlineMessage(
          message: _accountErrorMessage(error, l10n),
          isError: true,
        ),
        data: (value) {
          final initials = _initials(value.fullName, email);
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final identityRow = Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF0F4C81),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
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
                              value.fullName.isNotEmpty
                                  ? value.fullName
                                  : l10n.parentDashboardTitle,
                              style: LearnTzTypography.h3.copyWith(
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
                              ),
                            if (canAccessCurriculum && !canAccessAdmin)
                              const ds.AppBadge(
                                label: 'Curriculum Staff',
                                variant: ds.AppBadgeVariant.success,
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

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ds.AppButton(
                    label: l10n.editProfileAction,
                    icon: Icons.edit_outlined,
                    variant: ds.AppButtonVariant.outlined,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => context.go(AppRoutes.editParentProfile),
                  ),
                  ds.AppButton(
                    label: l10n.accountSettingsAction,
                    icon: Icons.settings_outlined,
                    variant: ds.AppButtonVariant.outlined,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => context.go(AppRoutes.accountSettings),
                  ),
                  ds.AppButton(
                    label: l10n.signOutAction,
                    icon: Icons.logout,
                    variant: ds.AppButtonVariant.outlined,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => _signOut(context, ref),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identityRow,
                    const SizedBox(height: 14),
                    actions,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: identityRow),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainFamilyColumn({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required AsyncValue<List<Learner>> learners,
    required int learnerCount,
    required AsyncValue<List<IncomingGuardianInvitation>> incomingInvitations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Family Quick Actions Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LearnTzColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Learning Hub',
                style: LearnTzTypography.bodyRegular.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F4C81),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.parentDashboardDescription,
                style: LearnTzTypography.bodySmall.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ds.AppButton(
                    label: l10n.learningHubTitle,
                    icon: Icons.school_outlined,
                    variant: ds.AppButtonVariant.primary,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => context.go(AppRoutes.learn),
                  ),
                  ds.AppButton(
                    label: 'Progress & Analytics',
                    icon: Icons.analytics_outlined,
                    variant: ds.AppButtonVariant.outlined,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => context.go(AppRoutes.parentDashboard),
                  ),
                  ds.AppButton(
                    label: l10n.viewSubscriptionsAction,
                    icon: Icons.payments_outlined,
                    variant: ds.AppButtonVariant.outlined,
                    size: ds.AppButtonSize.sm,
                    onPressed: () => context.go(AppRoutes.subscriptions),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (incomingInvitations.asData?.value.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _IncomingInvitationsCard(
            invitations: incomingInvitations.requireValue,
          ),
        ],

        const SizedBox(height: 16),

        // Learners Management Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LearnTzColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.learnersSectionTitle,
                          style: LearnTzTypography.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.learnerCount(learnerCount),
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (learnerCount > 0)
                    ds.AppButton(
                      label: l10n.addLearnerAction,
                      icon: Icons.add,
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
                data: (items) => items.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LearnTzColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F4C81)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    color: Color(0xFF0F4C81),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.noLearnersTitle,
                                        style: LearnTzTypography.bodyRegular
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: LearnTzColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        l10n.noLearnersDescription,
                                        style: LearnTzTypography.bodySmall
                                            .copyWith(
                                          color: LearnTzColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const _BenefitBullet(
                              text:
                                  'Curriculum-aligned lessons matched to your child’s exact grade & country.',
                            ),
                            const _BenefitBullet(
                              text:
                                  'Practice quizzes, timed examinations, and competency mastery tracking.',
                            ),
                            const _BenefitBullet(
                              text:
                                  'Independent learner login on shared or dedicated devices.',
                            ),
                            const SizedBox(height: 16),
                            ds.AppButton(
                              label: l10n.addLearnerAction,
                              icon: Icons.add,
                              variant: ds.AppButtonVariant.primary,
                              size: ds.AppButtonSize.md,
                              onPressed: () => context.go(AppRoutes.addLearner),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 560 ? 2 : 1;
                          final cardWidth =
                              (constraints.maxWidth - (columns - 1) * 12) /
                                  columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final learner in items)
                                SizedBox(
                                  width: cardWidth,
                                  child: _LearnerCard(
                                    learner: learner,
                                    onSelected: () async {
                                      try {
                                        await ref
                                            .read(
                                              activeLearnerProvider.notifier,
                                            )
                                            .select(learner.id);
                                        if (context.mounted) {
                                          context.go(
                                            AppRoutes.learnerProfile(
                                              learner.id,
                                            ),
                                          );
                                        }
                                      } on PostgrestException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(l10n.requestFailed),
                                            ),
                                          );
                                        }
                                      } on NotSignedInException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.signInRequired,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    onEdit: () => context.go(
                                      AppRoutes.editLearner(learner.id),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideWorkspacesColumn({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool canAccessAdmin,
    required bool canAccessCurriculum,
    required bool hasStaffWorkspaces,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasStaffWorkspaces) ...[
          Container(
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
          ),
          const SizedBox(height: 16),
        ],

        // Subscription & Account Overview Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LearnTzColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.credit_card_outlined,
                    color: Color(0xFF15803D),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.viewSubscriptionsAction,
                    style: LearnTzTypography.bodyRegular.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LearnTzColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your family subscription plan, billing history, and multi-learner access.',
                style: LearnTzTypography.bodySmall.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ds.AppButton(
                label: l10n.viewSubscriptionsAction,
                icon: Icons.arrow_forward,
                variant: ds.AppButtonVariant.outlined,
                size: ds.AppButtonSize.sm,
                onPressed: () => context.go(AppRoutes.subscriptions),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitBullet extends StatelessWidget {
  const _BenefitBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Color(0xFF15803D),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: LearnTzTypography.bodySmall.copyWith(
                color: LearnTzColors.textSecondary,
              ),
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

class _LearnerCard extends ConsumerWidget {
  const _LearnerCard({
    required this.learner,
    required this.onSelected,
    required this.onEdit,
  });

  final Learner learner;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(educationCatalogProvider).asData?.value;
    final activeLearner = ref.watch(activeLearnerProvider);
    final isSelected = activeLearner?.id == learner.id;
    final countryName =
        catalog?.country(learner.countryCode)?.name ?? learner.countryCode;
    final grade = catalog?.grade(learner.gradeId)?.name ?? '';
    final level = catalog?.level(learner.educationLevelId)?.name ?? '';
    final system = catalog?.system(learner.educationSystemId)?.name ?? '';

    return AppCard(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    learner.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.editLearnerAction,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Text([level, grade].where((part) => part.isNotEmpty).join(' • ')),
            const SizedBox(height: 4),
            Text('$countryName${system.isEmpty ? '' : ' • $system'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(_learnerStatus(learner.status, l10n)),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (isSelected)
                  Text(
                    l10n.activeLearnerLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
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
  return value.length >= 10 ? null : l10n.passwordMinimumLength;
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
