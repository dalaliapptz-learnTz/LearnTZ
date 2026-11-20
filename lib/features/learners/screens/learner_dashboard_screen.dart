// LearnTZ — Independent Child Learner Dashboard Screen

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../gamification/gamification_providers.dart';
import '../../gamification/widgets/gamification_widgets.dart';
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
        final gamifOverview =
            ref.watch(learnerGamificationOverviewProvider(learner.id)).asData?.value;
        final liveStreak = gamifOverview?.currentStreak ?? 0;

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
              // Live Streak badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.accent50,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: LearnTzColors.accent200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: LearnTzColors.accent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$liveStreak ${liveStreak == 1 ? 'Day' : 'Days'}',
                      style: const TextStyle(
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
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vibrant Illustrated Welcome Banner
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4C81), Color(0xFF0D9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4C81).withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Soft decorative graphics
                          Positioned(
                            right: -24,
                            top: -24,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 52,
                            bottom: -36,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
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
                                        "Let's continue your streak with today's learning adventure!",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      FilledButton.icon(
                                        onPressed: () => context.go(AppRoutes.learn),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF0F4C81),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                        label: const Text('Start Today\'s Lesson'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    avatarInfo.icon,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Live Gamification Strip (Streaks, Verified XP & Badges, Leaderboard)
                    GamificationDashboardSection(
                      learnerId: learner.id,
                      subjects: const [],
                    ),
                    const SizedBox(height: 22),

                    // Colourful Photo-Backed Learning Hubs Grid
                    Text(
                      "TODAY'S LEARNING HUBS",
                      style: LearnTzTypography.caption.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: LearnTzColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth >= 720 ? 3 : 2;
                        final isCompact = cols == 2;

                        final hubs = <Widget>[
                          _buildPhotoHubCard(
                            title: 'My Subjects',
                            description: 'Explore books, syllabus & lessons',
                            tag: 'Curriculum',
                            imageAsset: 'assets/images/welcome/feature_syllabi.jpg',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF0F4C81),
                            tint: const Color(0xFFEFF6FF),
                            border: const Color(0xFFBFDBFE),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.learn),
                          ),
                          _buildPhotoHubCard(
                            title: 'Practice Centre',
                            description: 'Interactive quizzes & smart exercises',
                            tag: 'Quizzes',
                            imageAsset: 'assets/images/welcome/feature_practice.jpg',
                            icon: Icons.draw_rounded,
                            color: const Color(0xFF15803D),
                            tint: const Color(0xFFF0FDF4),
                            border: const Color(0xFFBBF7D0),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.learn),
                          ),
                          _buildPhotoHubCard(
                            title: 'Revision Centre',
                            description: 'Flashcards, formula sheets & summaries',
                            tag: 'Flashcards',
                            imageAsset: 'assets/images/welcome/feature_analytics.jpg',
                            icon: Icons.assignment_turned_in_rounded,
                            color: const Color(0xFFEA580C),
                            tint: const Color(0xFFFFF7ED),
                            border: const Color(0xFFFED7AA),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.revisionCentre),
                          ),
                          _buildPhotoHubCard(
                            title: 'Mock Examinations',
                            description: 'Timed past papers & real exam runner',
                            tag: 'Exams',
                            imageAsset: 'assets/images/welcome/feature_exams.jpg',
                            icon: Icons.timer_rounded,
                            color: const Color(0xFF7C3AED),
                            tint: const Color(0xFFF5F3FF),
                            border: const Color(0xFFDDD6FE),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.examCentre),
                          ),
                          _buildPhotoHubCard(
                            title: 'Achievements',
                            description: 'Trophies, badges & academic challenges',
                            tag: 'Rewards',
                            imageAsset: 'assets/images/welcome/hub_achievements.jpg',
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFFD97706),
                            tint: const Color(0xFFFFFBEB),
                            border: const Color(0xFFFDE68A),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.challenges),
                          ),
                          _buildPhotoHubCard(
                            title: 'Study Library',
                            description: 'Saved bookmarks & offline resources',
                            tag: 'Library',
                            imageAsset: 'assets/images/welcome/hub_library.jpg',
                            icon: Icons.bookmark_rounded,
                            color: const Color(0xFF0D9488),
                            tint: const Color(0xFFF0FDFA),
                            border: const Color(0xFF99F6E4),
                            isCompact: isCompact,
                            onTap: () => context.go(AppRoutes.resourceLibrary),
                          ),
                        ];

                        return GridView.builder(
                          itemCount: hubs.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: isCompact ? 236 : 292,
                          ),
                          itemBuilder: (_, index) => hubs[index],
                        );
                      },
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

  Widget _buildPhotoHubCard({
    required String title,
    required String description,
    required String tag,
    required String imageAsset,
    required IconData icon,
    required Color color,
    required Color tint,
    required Color border,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, tint],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.09),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed-height Real Photo Banner so every card aligns identically
              SizedBox(
                height: isCompact ? 104 : 148,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 36),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            color.withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Row(
                        children: [
                          Container(
                            width: isCompact ? 30 : 34,
                            height: isCompact ? 30 : 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: isCompact ? 17 : 19,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Text & Colourful Action Pill pinned cleanly to bottom
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 13.5 : 15.5,
                          color: LearnTzColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          color: const Color(0xFF475569),
                          height: 1.32,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Explore →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
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
