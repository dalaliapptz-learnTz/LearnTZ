import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../exam_v2_providers.dart';

class ExamV2OnlineRunnerScreen extends ConsumerStatefulWidget {
  const ExamV2OnlineRunnerScreen({
    super.key,
    required this.examinationId,
    required this.learnerId,
  });

  final String examinationId;
  final String learnerId;

  @override
  ConsumerState<ExamV2OnlineRunnerScreen> createState() =>
      _ExamV2OnlineRunnerScreenState();
}

class _ExamV2OnlineRunnerScreenState
    extends ConsumerState<ExamV2OnlineRunnerScreen> {
  bool _loading = true;
  String? _error;
  String? _attemptId;
  String _examTitle = '';
  DateTime? _serverDeadline;
  List<Map<String, dynamic>> _questions = const [];
  final Map<String, String> _answers = {};
  final Set<String> _savedIds = {};
  int _currentIndex = 0;
  bool _submitting = false;
  Map<String, dynamic>? _submissionResult;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  final _textResponseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAttempt();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _textResponseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initAttempt() async {
    try {
      final payload = await ref
          .read(examCentreV2RepositoryProvider)
          .startAttempt(
            examinationId: widget.examinationId,
            learnerId: widget.learnerId,
          );
      final rawQuestions = (payload['questions'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final deadlineStr = payload['server_deadline_at'] as String?;
      final deadline =
          deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;

      for (final q in rawQuestions) {
        final qid = q['id'] as String;
        final saved = q['saved_response'];
        if (saved is Map) {
          final val =
              (saved['answer'] ?? saved['text'] ?? '').toString().trim();
          if (val.isNotEmpty) {
            _answers[qid] = val;
            _savedIds.add(qid);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _attemptId = payload['attempt_id'] as String?;
        _examTitle = payload['examination_title'] as String? ?? 'Examination';
        _serverDeadline = deadline;
        _questions = rawQuestions;
        _loading = false;
        _syncTextController();
      });

      if (deadline != null) {
        _updateRemaining();
        _ticker = Timer.periodic(
          const Duration(seconds: 1),
          (_) => _updateRemaining(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _updateRemaining() {
    final deadline = _serverDeadline;
    if (deadline == null || !mounted) return;
    final diff = deadline.difference(DateTime.now().toUtc());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  void _syncTextController() {
    if (_questions.isEmpty) return;
    final qid = _questions[_currentIndex]['id'] as String;
    _textResponseCtrl.text = _answers[qid] ?? '';
  }

  Future<void> _saveCurrentAnswer(String questionId, String value) async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    setState(() {
      _answers[questionId] = value;
      _savedIds.remove(questionId);
    });
    final qType =
        _questions[_currentIndex]['question_type'] as String? ?? 'short_answer';
    final isObjective = const {
      'multiple_choice',
      'true_false',
      'fill_in_the_blank',
      'matching',
      'word_completion',
    }.contains(qType);
    await ref.read(examCentreV2RepositoryProvider).saveResponse(
          attemptId: attemptId,
          examinationQuestionId: questionId,
          responsePayload:
              isObjective ? {'answer': value} : {'text': value},
        );
    if (!mounted) return;
    setState(() => _savedIds.add(questionId));
  }

  Future<void> _submitExam() async {
    final attemptId = _attemptId;
    if (attemptId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final res = await ref
          .read(examCentreV2RepositoryProvider)
          .submitAttempt(attemptId);
      _ticker?.cancel();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submissionResult = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatClock(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: LearnTzTypography.bodyRegular.copyWith(
                color: const Color(0xFFDC2626),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_submissionResult != null) {
      final pct = _submissionResult!['percentage'] ?? 0;
      final unmarked = (_submissionResult!['unmarked_count'] as num?)?.toInt() ?? 0;
      return Scaffold(
        backgroundColor: LearnTzColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                key: const Key('exam-v2-submitted-card'),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF15803D), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF15803D),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Examination Submitted',
                      style: LearnTzTypography.h3.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unmarked > 0
                          ? 'Your responses have been saved. Objective questions were marked automatically; $unmarked written response(s) are queued for examiner marking.'
                          : 'Your examination has been automatically marked. Score: $pct%.',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Done',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final qid = q['id'] as String;
    final options = (q['options'] as List<dynamic>? ?? const []);
    final isSaved = _savedIds.contains(qid);
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with server-authoritative countdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _examTitle,
                              style: LearnTzTypography.bodyRegular.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                              style: LearnTzTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatClock(_remaining),
                                style: LearnTzTypography.bodyRegular.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question Card
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            AppBadge(
                              label: '${q['marks']} marks',
                              variant: AppBadgeVariant.primary,
                              size: AppBadgeSize.sm,
                            ),
                            if (isSaved)
                              const AppBadge(
                                key: Key('exam-v2-saved-indicator'),
                                label: 'Answer Saved',
                                variant: AppBadgeVariant.success,
                                size: AppBadgeSize.sm,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          q['question_text'] as String? ?? '',
                          style: LearnTzTypography.h3.copyWith(
                            color: LearnTzColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (options.isNotEmpty)
                          ...List.generate(options.length, (i) {
                            final optVal = options[i].toString();
                            final selected = _answers[qid] == optVal;
                            final letter =
                                i < letters.length ? letters[i] : '${i + 1}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                key: Key('exam-v2-opt-$i'),
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _saveCurrentAnswer(qid, optVal),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF0F4C81)
                                            .withValues(alpha: 0.08)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0F4C81)
                                          : LearnTzColors.border,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: selected
                                            ? const Color(0xFF0F4C81)
                                            : const Color(0xFFE2E8F0),
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : LearnTzColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          optVal,
                                          style: LearnTzTypography.bodyRegular
                                              .copyWith(
                                            color: LearnTzColors.textPrimary,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                        else
                          TextField(
                            controller: _textResponseCtrl,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Your Answer',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _saveCurrentAnswer(qid, v),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation & Submit Controls
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      AppButton(
                        label: 'Previous',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.sm,
                        icon: Icons.chevron_left,
                        onPressed: _currentIndex > 0
                            ? () {
                                setState(() {
                                  _currentIndex--;
                                  _syncTextController();
                                });
                              }
                            : null,
                      ),
                      if (_currentIndex < _questions.length - 1)
                        AppButton(
                          label: 'Next Question',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          icon: Icons.chevron_right,
                          onPressed: () {
                            setState(() {
                              _currentIndex++;
                              _syncTextController();
                            });
                          },
                        )
                      else
                        AppButton(
                          key: const Key('exam-v2-submit-attempt-btn'),
                          label: _submitting
                              ? 'Submitting...'
                              : 'Submit Examination',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          icon: Icons.check_circle_outline,
                          onPressed: _submitting ? null : _submitExam,
                        ),
                    ],
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
