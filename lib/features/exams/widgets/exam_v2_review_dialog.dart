import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../exam_v2_models.dart';
import '../exam_v2_providers.dart';

class ExamV2ReviewDialog extends ConsumerStatefulWidget {
  const ExamV2ReviewDialog({
    super.key,
    required this.item,
    required this.canPublish,
  });

  final ExamV2ReviewQueueItem item;
  final bool canPublish;

  @override
  ConsumerState<ExamV2ReviewDialog> createState() => _ExamV2ReviewDialogState();
}

class _ExamV2ReviewDialogState extends ConsumerState<ExamV2ReviewDialog> {
  final _commentsCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  final Map<String, bool> _checklist = {
    'country_and_curriculum': true,
    'level_grade_subject': true,
    'valid_curriculum_version': true,
    'competency_alignment': true,
    'question_answer_accuracy': true,
    'age_appropriateness': true,
    'clear_instructions': true,
    'marks_and_duration': true,
    'answer_key_and_rubric': true,
    'formatting_and_print_quality': true,
  };

  static const _checklistLabels = {
    'country_and_curriculum': 'Correct country and national curriculum',
    'level_grade_subject': 'Correct education level, grade, and subject',
    'valid_curriculum_version': 'Valid approved curriculum version retained',
    'competency_alignment': 'Questions align to official TIE competencies',
    'question_answer_accuracy': 'Accuracy of questions and answer keys',
    'age_appropriateness': 'Age and grade appropriateness verified',
    'clear_instructions': 'Clear candidate and section instructions',
    'marks_and_duration': 'Appropriate marks allocation and duration',
    'answer_key_and_rubric': 'Answer key and manual marking rubric complete',
    'formatting_and_print_quality': 'Paper formatting and print quality verified',
  };

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(String action) async {
    final comments = _commentsCtrl.text.trim();
    if (action == 'request_revision' && comments.isEmpty) {
      setState(
        () => _errorText = 'Please provide revision comments for the author.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(examCentreV2RepositoryProvider).recordReviewDecision(
            examinationId: widget.item.examinationId,
            action: action,
            comments: comments,
            checklist: _checklist,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canApprove = item.status == 'submitted_for_review' ||
        item.status == 'under_review';
    final canPublishNow = widget.canPublish && item.status == 'approved';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 780),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C81),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Review & Approval',
                          style: LearnTzTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${item.title} • v${item.versionNumber}',
                          style: LearnTzTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorText != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _errorText!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Official Academic Reviewer Checklist',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._checklistLabels.entries.map((entry) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _checklist[entry.key] ?? false,
                        title: Text(
                          entry.value,
                          style: LearnTzTypography.bodySmall,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _checklist[entry.key] = val ?? false;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('exam-v2-review-comments-field'),
                      controller: _commentsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reviewer Comments / Audit Note',
                        hintText:
                            'Required when requesting revisions; recommended for approval/publication.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: LearnTzColors.border)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  if (canApprove) ...[
                    AppButton(
                      key: const Key('exam-v2-request-revision-btn'),
                      label: 'Request Revision',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.sm,
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitDecision('request_revision'),
                    ),
                    AppButton(
                      key: const Key('exam-v2-approve-exam-btn'),
                      label: 'Approve',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      icon: Icons.verified_outlined,
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitDecision('approve'),
                    ),
                  ],
                  if (canPublishNow)
                    AppButton(
                      key: const Key('exam-v2-publish-exam-btn'),
                      label: 'Publish Examination',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      icon: Icons.public_outlined,
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitDecision('publish'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
