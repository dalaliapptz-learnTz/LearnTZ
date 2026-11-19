// LearnTZ — Independent Child Learner Dashboard Screen

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../providers/learner_auth_providers.dart';

class LearnerDashboardScreen extends ConsumerWidget {
  const LearnerDashboardScreen({super.key});

  static const Map<String, ({IconData icon, Color color, String name})> _avatarMeta = {
    'owl_scholar': (icon: Icons.psychology_outlined, color: Color(0xFF0F4C81), name: 'Wise Owl'),
    'lion_reader': (icon: Icons.menu_book_rounded, color: Color(0xFFD97706), name: 'Brave Lion'),
    'cheetah_runner': (icon: Icons.speed_rounded, color: Color(0xFFEA580C), name: 'Cheetah Runner'),
    'giraffe_thinker': (icon: Icons.lightbulb_outline, color: Color(0xFFCA8A04), name: 'Tall Thinker'),
    'elephant_math': (icon: Icons.calculate_outlined, color: Color(0xFF2563EB), name: 'Math Champion'),
    'zebra_writer': (icon: Icons.create_outlined, color: Color(0xFF059669), name: 'Creative Writer'),
    'falcon_scout': (icon: Icons.explore_outlined, color: Color(0xFF7C3AED), name: 'Explorer Falcon'),
    'rhino_builder': (icon: Icons.architecture_rounded, color: Color(0xFF4B5563), name: 'Strong Builder'),
  };

  void _handleExit(BuildContext context, WidgetRef ref, bool isParentManaged) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isParentManaged ? 'Exit Child Mode?' : 'Sign Out of LearnTZ?'),
        content: Text(
          isParentManaged
              ? 'Return to the Parent Dashboard. Learning progress has been safely saved.'
              : 'Sign out of your learner account on this device. Your learning progress is saved in the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(activeLearnerSessionProvider.notifier).signOut();
              if (context.mounted) {
                if (isParentManaged) {
                  context.go(AppRoutes.parentDashboard);
                } else {
                  context.go(AppRoutes.welcome);
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isParentManaged ? LearnTzColors.primary : LearnTzColors.error,
            ),
            child: Text(isParentManaged ? 'Return to Parent' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activeLearnerSessionProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading learner profile: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.learnerLogin),
                child: const Text('Return to Sign In'),
              ),
            ],
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(AppRoutes.learnerLogin);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final learner = session.learner;
        final avatarInfo = _avatarMeta[learner.avatarPreset] ??
            (icon: Icons.school_rounded, color: LearnTzColors.primary, name: 'Learner');

        return Scaffold(
          backgroundColor: LearnTzColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarInfo.color.withValues(alpha: 0.15),
                  child: Icon(avatarInfo.icon, color: avatarInfo.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        learner.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LearnTzColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${learner.learnerCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: LearnTzColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Streak badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.accent50,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: LearnTzColors.accent200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: LearnTzColors.accent, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '3 Days',
                      style: TextStyle(
                        color: LearnTzColors.accent900,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Exit child mode / sign out button
              IconButton(
                icon: Icon(
                  session.isParentManagedMode ? Icons.logout_rounded : Icons.power_settings_new,
                  color: LearnTzColors.neutral700,
                ),
                tooltip: session.isParentManagedMode ? 'Exit Child Mode' : 'Sign Out',
                onPressed: () => _handleExit(context, ref, session.isParentManagedMode),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [LearnTzColors.primary, LearnTzColors.primary800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: LearnTzColors.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    '${learner.countryCode} CURRICULUM',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Ready to learn, ${learner.firstName}?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Let's continue your streak with today's adventure!",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Icon(avatarInfo.icon, color: Colors.white, size: 40),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Learning Section
                    Text(
                      'CONTINUE LEARNING',
                      style: LearnTzTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: LearnTzColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LearnTzColors.neutral200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LearnTzColors.secondary50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.play_lesson_outlined,
                                color: LearnTzColors.secondary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mathematics — Fractions & Decimals',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lesson 4 • 65% Completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.learn),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('Resume'),
                            style: FilledButton.styleFrom(
                              backgroundColor: LearnTzColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Navigation Activity Grid
                    Text(
                      "TODAY'S LEARNING HUBS",
                      style: LearnTzTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: LearnTzColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildHubCard(
                          title: 'My Subjects',
                          description: 'Explore books, syllabus & lessons',
                          icon: Icons.menu_book_rounded,
                          color: LearnTzColors.primary,
                          onTap: () => context.go(AppRoutes.curriculumExplorer),
                        ),
                        _buildHubCard(
                          title: 'Practice Centre',
                          description: 'Interactive quizzes & smart exercises',
                          icon: Icons.draw_rounded,
                          color: LearnTzColors.secondary,
                          onTap: () => context.go(AppRoutes.learn),
                        ),
                        _buildHubCard(
                          title: 'Revision Centre',
                          description: 'Flashcards, formula sheets & summaries',
                          icon: Icons.assignment_turned_in_outlined,
                          color: const Color(0xFFEA580C),
                          onTap: () => context.go(AppRoutes.revisionCentre),
                        ),
                        _buildHubCard(
                          title: 'Mock Examinations',
                          description: 'Timed past papers & real exam runner',
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF7C3AED),
                          onTap: () => context.go(AppRoutes.examCentre),
                        ),
                        _buildHubCard(
                          title: 'Achievements',
                          description: 'Trophies, badges & community quests',
                          icon: Icons.emoji_events_outlined,
                          color: const Color(0xFFD97706),
                          onTap: () => context.go(AppRoutes.challenges),
                        ),
                        _buildHubCard(
                          title: 'Study Library',
                          description: 'Saved bookmarks & offline resources',
                          icon: Icons.bookmark_border_rounded,
                          color: const Color(0xFF059669),
                          onTap: () => context.go(AppRoutes.resourceLibrary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHubCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LearnTzColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: LearnTzColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LearnTzColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
