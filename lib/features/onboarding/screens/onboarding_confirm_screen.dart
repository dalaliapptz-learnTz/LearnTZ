import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../learners/learner_providers.dart';
import '../models/child_draft.dart';
import '../models/onboarding_session.dart';
import '../providers/onboarding_providers.dart';

class OnboardingConfirmScreen extends ConsumerStatefulWidget {
  const OnboardingConfirmScreen({super.key});

  @override
  ConsumerState<OnboardingConfirmScreen> createState() =>
      _OnboardingConfirmScreenState();
}

class _OnboardingConfirmScreenState
    extends ConsumerState<OnboardingConfirmScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Map<String, IconData> _avatarIcons = {
    'owl_scholar': Icons.psychology_outlined,
    'lion_reader': Icons.menu_book_rounded,
    'cheetah_runner': Icons.speed_rounded,
    'giraffe_thinker': Icons.lightbulb_outline,
    'elephant_math': Icons.calculate_outlined,
    'zebra_writer': Icons.create_outlined,
    'falcon_scout': Icons.explore_outlined,
    'rhino_builder': Icons.architecture_rounded,
  };

  Future<void> _handleConfirmAndContinue() async {
    final session = ref.read(onboardingSessionProvider);
    if (session.children.isEmpty) {
      setState(() {
        _errorMessage =
            'Please add at least one child profile before confirming.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(onboardingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Authentication backend is not connected.';
      });
      return;
    }

    try {
      // 1. Transactionally complete onboarding on backend
      await repository.completeOnboarding(children: session.children);

      // 2. Mark completed in state & clear draft storage
      await ref.read(onboardingSessionProvider.notifier).markCompleted();

      // 3. Refresh learners list and dashboard
      ref.invalidate(parentLearnersProvider);

      // 4. Navigate directly to Parent Dashboard (Session is preserved!)
      if (mounted) {
        context.go(AppRoutes.parentDashboard);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to save child profiles: ${e.toString().replaceAll("Exception: ", "")}';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(onboardingSessionProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              _buildProgressHeader(currentStep: 5, totalSteps: 5),
              const SizedBox(height: 24),

              // Title
              Text(
                'Confirm Family Learning Profile',
                style: LearnTzTypography.h1.copyWith(
                  color: LearnTzColors.textPrimary,
                  fontSize: isWide ? 30 : 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please verify the details below. Once confirmed, your family profile will be activated with tailored curriculum lessons.',
                style: LearnTzTypography.bodyLarge.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LearnTzColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: LearnTzColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: LearnTzColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: LearnTzColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Parent & Account Summary Card
              _buildParentSummaryCard(session),
              const SizedBox(height: 24),

              // Registered Children Header + Add another action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Registered Children (${session.children.length})',
                      style: LearnTzTypography.h3.copyWith(
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.onboardingAddChild),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Add Another'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Children cards
              if (session.children.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.child_care,
                            size: 48, color: LearnTzColors.neutral400),
                        const SizedBox(height: 12),
                        const Text('No child registered yet.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              context.go(AppRoutes.onboardingAddChild),
                          child: const Text('Add Your Child'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < session.children.length; i++) ...[
                      _buildChildCard(session.children[i], i),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),

              const SizedBox(height: 32),

              // Primary Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleConfirmAndContinue,
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_outline, size: 22),
                  label: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'CONFIRM AND CONTINUE',
                          style: LearnTzTypography.button.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: LearnTzColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Center(
                child: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.onboardingAddChild),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Child Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentSummaryCard(OnboardingSession session) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LearnTzColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom,
                    color: LearnTzColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.parentFullName ?? 'Parent / Guardian',
                      style: LearnTzTypography.h4.copyWith(
                        color: LearnTzColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${session.phoneNumber ?? "No phone"} • ${session.countryName}',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.successBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: LearnTzColors.successBorder),
                ),
                child: Text(
                  'Phone Verified',
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildDraft child, int index) {
    final avatarIcon =
        _avatarIcons[child.avatarPreset] ?? Icons.psychology_outlined;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 24,
                backgroundColor: LearnTzColors.primary50,
                child: Icon(avatarIcon, color: LearnTzColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: LearnTzTypography.h4.copyWith(
                        color: LearnTzColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${child.gradeName} • ${child.levelName}',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Remove / Edit Buttons
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: LearnTzColors.error, size: 20),
                tooltip: 'Remove child',
                onPressed: () {
                  ref
                      .read(onboardingSessionProvider.notifier)
                      .removeChildDraft(child.id);
                },
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildDetailPill(
                Icons.cake_outlined,
                '${DateFormat("dd MMM yyyy").format(child.dateOfBirth)} (${child.ageYears} yrs)',
              ),
              const SizedBox(width: 8),
              _buildDetailPill(
                child.accessMode == 'independent_device'
                    ? Icons.tablet_mac_rounded
                    : Icons.phone_android_rounded,
                child.accessMode == 'independent_device'
                    ? 'Own Device'
                    : "Parent's Device",
              ),
              const SizedBox(width: 8),
              if (child.schoolName != null &&
                  child.schoolName!.trim().isNotEmpty)
                Expanded(
                  child: _buildDetailPill(
                    Icons.school_outlined,
                    child.schoolName!,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LearnTzColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LearnTzColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader({
    required int currentStep,
    required int totalSteps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $currentStep OF $totalSteps: PROFILE CONFIRMATION',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).toInt()}% Complete',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 6,
            backgroundColor: LearnTzColors.neutral200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(LearnTzColors.primary),
          ),
        ),
      ],
    );
  }
}
