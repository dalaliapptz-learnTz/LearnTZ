import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../lesson_authoring_models.dart';

/// Learner-facing preview pane with responsive Desktop / Mobile toggle.
class LessonPreviewPane extends StatefulWidget {
  const LessonPreviewPane({
    super.key,
    required this.title,
    required this.shortDescription,
    required this.breadcrumb,
    required this.estimatedMinutes,
    required this.languageCode,
    required this.difficultyLevel,
    required this.lessonType,
    required this.learningObjectives,
    required this.learningOutcomes,
    required this.contentBlocks,
    required this.activities,
    required this.questions,
    this.mainCompetenceLabel,
    this.specificCompetenceLabel,
  });

  final String title;
  final String shortDescription;
  final String breadcrumb;
  final int estimatedMinutes;
  final String languageCode;
  final String difficultyLevel;
  final String lessonType;
  final List<String> learningObjectives;
  final List<LessonLearningOutcome> learningOutcomes;
  final List<LessonContentBlock> contentBlocks;
  final List<LessonTeachingActivity> activities;
  final List<LessonAssessmentQuestion> questions;
  final String? mainCompetenceLabel;
  final String? specificCompetenceLabel;

  @override
  State<LessonPreviewPane> createState() => _LessonPreviewPaneState();
}

class _LessonPreviewPaneState extends State<LessonPreviewPane> {
  bool _isMobilePreview = false;

  @override
  Widget build(BuildContext context) {
    final previewBody = _buildLearnerContent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Header & Device Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LearnTzColors.neutral200),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: LearnTzColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Learner Lesson Preview',
                      style: LearnTzTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SegmentedButton<bool>(
                key: const Key('preview-device-toggle'),
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.desktop_windows_outlined, size: 16),
                    label: Text('Desktop'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.phone_android_outlined, size: 16),
                    label: Text('Mobile'),
                  ),
                ],
                selected: {_isMobilePreview},
                onSelectionChanged: (sel) {
                  setState(() => _isMobilePreview = sel.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isMobilePreview ? 390 : double.infinity,
            ),
            child: Container(
              width: double.infinity,
              decoration: _isMobilePreview
                  ? BoxDecoration(
                      color: LearnTzColors.background,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: LearnTzColors.neutral800,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LearnTzColors.neutral200),
                    ),
              padding: EdgeInsets.all(_isMobilePreview ? 16 : 24),
              child: previewBody,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearnerContent(BuildContext context) {
    final summaryBlocks = widget.contentBlocks
        .where((b) => b.type == LessonContentBlockType.summary)
        .toList();
    final mainBlocks = widget.contentBlocks
        .where((b) => b.type != LessonContentBlockType.summary)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb & Badges
        Text(
          widget.breadcrumb,
          style: LearnTzTypography.caption.copyWith(
            color: LearnTzColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.title.trim().isEmpty ? 'Untitled Lesson' : widget.title.trim(),
          style: LearnTzTypography.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: LearnTzColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            AppBadge(
              label: '${widget.estimatedMinutes} min',
              variant: AppBadgeVariant.primary,
              size: AppBadgeSize.sm,
            ),
            AppBadge(
              label: widget.difficultyLevel.toUpperCase(),
              variant: AppBadgeVariant.neutral,
              size: AppBadgeSize.sm,
            ),
            AppBadge(
              label: widget.languageCode.toUpperCase(),
              variant: AppBadgeVariant.success,
              size: AppBadgeSize.sm,
            ),
          ],
        ),
        if (widget.shortDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.shortDescription.trim(),
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
        if (widget.specificCompetenceLabel != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF0F4C81).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.mainCompetenceLabel != null)
                  Text(
                    'Main Competence: ${widget.mainCompetenceLabel}',
                    style: LearnTzTypography.caption.copyWith(
                      color: const Color(0xFF0F4C81),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  'Specific Competence: ${widget.specificCompetenceLabel}',
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: LearnTzColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Learning Objectives
        if (widget.learningObjectives.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(Icons.flag_outlined, 'What You Will Learn'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF15803D).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF15803D).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.learningObjectives
                  .map(
                    (obj) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(obj, style: LearnTzTypography.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],

        // Measurable Learning Outcomes
        if (widget.learningOutcomes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle(Icons.verified_outlined, 'Learning Outcomes'),
          const SizedBox(height: 8),
          ...widget.learningOutcomes.map(
            (lo) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      '${lo.outcome} (${lo.cognitiveLevel})',
                      style: LearnTzTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Content Sections
        const SizedBox(height: 20),
        _sectionTitle(Icons.auto_stories_outlined, 'Lesson Content'),
        const SizedBox(height: 10),
        if (mainBlocks.isEmpty)
          Text(
            'Add instructional blocks in the Content Builder to preview lesson content.',
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...mainBlocks.map(_buildContentBlockPreview),

        // Teaching & Learning Activities
        if (widget.activities.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(Icons.groups_outlined, 'Learning Activities'),
          const SizedBox(height: 10),
          ...widget.activities.map(
            (act) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        act.title,
                        style: LearnTzTypography.bodyRegular
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      AppBadge(
                        label: act.activityType.toUpperCase(),
                        variant: AppBadgeVariant.warning,
                        size: AppBadgeSize.sm,
                      ),
                      Text(
                        '${act.estimatedMinutes} min',
                        style: LearnTzTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(act.instructions, style: LearnTzTypography.bodySmall),
                  if (act.requiredMaterials.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Materials: ${act.requiredMaterials}',
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Assessment Questions Preview
        if (widget.questions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(Icons.quiz_outlined,
              'Check Your Understanding (${widget.questions.length})'),
          const SizedBox(height: 10),
          ...widget.questions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final q = entry.value;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LearnTzColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Q$idx. ${q.questionText}',
                          style: LearnTzTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AppBadge(
                        label: '${q.marks.toStringAsFixed(0)} mk',
                        variant: AppBadgeVariant.primary,
                        size: AppBadgeSize.sm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${q.questionType.label} • Difficulty: ${q.difficultyLevel}',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  if (q.options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...q.options.map(
                      (opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.radio_button_unchecked,
                                size: 15, color: LearnTzColors.neutral500),
                            const SizedBox(width: 8),
                            Expanded(
                              child:
                                  Text(opt, style: LearnTzTypography.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],

        // Summary
        if (summaryBlocks.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(Icons.summarize_outlined, 'Lesson Summary'),
          const SizedBox(height: 8),
          ...summaryBlocks.map(_buildContentBlockPreview),
        ],
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F4C81)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: LearnTzTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F4C81),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentBlockPreview(LessonContentBlock block) {
    switch (block.type) {
      case LessonContentBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            block.title.isNotEmpty ? block.title : block.content,
            style: LearnTzTypography.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: LearnTzColors.textPrimary,
            ),
          ),
        );
      case LessonContentBlockType.image:
      case LessonContentBlockType.diagram:
      case LessonContentBlockType.audio:
      case LessonContentBlockType.video:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LearnTzColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LearnTzColors.neutral200),
          ),
          child: Row(
            children: [
              Icon(
                block.type == LessonContentBlockType.audio
                    ? Icons.audiotrack_outlined
                    : block.type == LessonContentBlockType.video
                        ? Icons.play_circle_outline
                        : Icons.image_outlined,
                size: 32,
                color: const Color(0xFF0F4C81),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title.isNotEmpty ? block.title : block.type.label,
                      style: LearnTzTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (block.caption != null && block.caption!.isNotEmpty)
                      Text(block.caption!, style: LearnTzTypography.caption),
                    if (block.content.isNotEmpty)
                      Text(block.content, style: LearnTzTypography.bodySmall),
                    if (block.mediaUrl != null && block.mediaUrl!.isNotEmpty)
                      Text(
                        block.mediaUrl!,
                        style: LearnTzTypography.caption.copyWith(
                          color: LearnTzColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case LessonContentBlockType.example:
      case LessonContentBlockType.workedExample:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF0F4C81), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.title.isNotEmpty ? block.title : block.type.label,
                style: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F4C81),
                ),
              ),
              const SizedBox(height: 4),
              Text(block.content, style: LearnTzTypography.bodySmall),
            ],
          ),
        );
      case LessonContentBlockType.keyVocabulary:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.title.isNotEmpty ? block.title : 'Key Vocabulary',
                style: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 4),
              Text(block.content, style: LearnTzTypography.bodySmall),
            ],
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    block.title,
                    style: LearnTzTypography.bodyRegular
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              Text(
                block.content,
                style: LearnTzTypography.bodyRegular.copyWith(height: 1.55),
              ),
            ],
          ),
        );
    }
  }
}
