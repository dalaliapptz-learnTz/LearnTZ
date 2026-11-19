import 'package:flutter/foundation.dart';

/// Launch context inherited from Curriculum Explorer or Content Management Studio.
@immutable
class AuthorLessonLaunchContext {
  const AuthorLessonLaunchContext({
    this.lessonId,
    this.countryCode,
    this.countryName,
    this.curriculumId,
    this.curriculumName,
    this.curriculumVersionId,
    this.curriculumVersionName,
    this.educationLevelId,
    this.educationLevelName,
    this.gradeId,
    this.gradeName,
    this.subjectId,
    this.subjectName,
    this.mainCompetenceId,
    this.specificCompetenceId,
    this.topicId,
    this.sourceEntry = 'curriculum_explorer',
  });

  final String? lessonId;
  final String? countryCode;
  final String? countryName;
  final String? curriculumId;
  final String? curriculumName;
  final String? curriculumVersionId;
  final String? curriculumVersionName;
  final String? educationLevelId;
  final String? educationLevelName;
  final String? gradeId;
  final String? gradeName;
  final String? subjectId;
  final String? subjectName;
  final String? mainCompetenceId;
  final String? specificCompetenceId;
  final String? topicId;
  final String sourceEntry;

  factory AuthorLessonLaunchContext.fromMap(Map<String, dynamic> map) {
    return AuthorLessonLaunchContext(
      lessonId: map['lessonId'] as String?,
      countryCode: map['countryCode'] as String?,
      countryName: map['countryName'] as String?,
      curriculumId: map['curriculumId'] as String?,
      curriculumName: map['curriculumName'] as String?,
      curriculumVersionId: map['curriculumVersionId'] as String?,
      curriculumVersionName: map['curriculumVersionName'] as String?,
      educationLevelId: map['educationLevelId'] as String?,
      educationLevelName: map['educationLevelName'] as String?,
      gradeId: map['gradeId'] as String?,
      gradeName: map['gradeName'] as String?,
      subjectId: map['subjectId'] as String?,
      subjectName: map['subjectName'] as String?,
      mainCompetenceId: map['mainCompetenceId'] as String?,
      specificCompetenceId: map['specificCompetenceId'] as String?,
      topicId: map['topicId'] as String?,
      sourceEntry: map['sourceEntry'] as String? ?? 'curriculum_explorer',
    );
  }
}

@immutable
class LessonAuthoringCapabilities {
  const LessonAuthoringCapabilities({
    this.authenticated = false,
    this.canAuthor = false,
    this.canReview = false,
    this.canApprove = false,
    this.canPublish = false,
    this.isSuperAdmin = false,
    this.roles = const [],
  });

  final bool authenticated;
  final bool canAuthor;
  final bool canReview;
  final bool canApprove;
  final bool canPublish;
  final bool isSuperAdmin;
  final List<String> roles;

  bool get hasAnyAccess => canAuthor || canReview || canApprove || canPublish;

  factory LessonAuthoringCapabilities.fromJson(Map<String, dynamic> json) {
    return LessonAuthoringCapabilities(
      authenticated: json['authenticated'] as bool? ?? false,
      canAuthor: json['can_author'] as bool? ?? false,
      canReview: json['can_review'] as bool? ?? false,
      canApprove: json['can_approve'] as bool? ?? false,
      canPublish: json['can_publish'] as bool? ?? false,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

@immutable
class AuthoringCurriculumOption {
  const AuthoringCurriculumOption({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.name,
    required this.code,
    this.authorityCode,
  });

  final String id;
  final String countryCode;
  final String countryName;
  final String name;
  final String code;
  final String? authorityCode;

  factory AuthoringCurriculumOption.fromJson(Map<String, dynamic> json) {
    return AuthoringCurriculumOption(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      authorityCode: json['authority_code'] as String?,
    );
  }
}

@immutable
class AuthoringLevelOption {
  const AuthoringLevelOption({
    required this.id,
    required this.curriculumId,
    required this.name,
    required this.code,
    this.sequence = 1,
  });

  final String id;
  final String curriculumId;
  final String name;
  final String code;
  final int sequence;

  factory AuthoringLevelOption.fromJson(Map<String, dynamic> json) {
    return AuthoringLevelOption(
      id: json['id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 1,
    );
  }
}

@immutable
class LessonAuthoringContext {
  const LessonAuthoringContext({
    required this.countryCode,
    required this.countryName,
    this.curriculumId,
    this.curriculumName,
    this.curriculumCode,
    this.authorityName,
    this.authorityCode,
    this.curriculumVersionId,
    this.curriculumVersionCode,
    this.curriculumVersionName,
    this.educationLevelId,
    this.educationLevelName,
    this.gradeId,
    this.gradeName,
    this.subjectId,
    this.subjectName,
    this.capabilities = const LessonAuthoringCapabilities(),
    this.availableCurricula = const [],
    this.availableLevels = const [],
  });

  final String countryCode;
  final String countryName;
  final String? curriculumId;
  final String? curriculumName;
  final String? curriculumCode;
  final String? authorityName;
  final String? authorityCode;
  final String? curriculumVersionId;
  final String? curriculumVersionCode;
  final String? curriculumVersionName;
  final String? educationLevelId;
  final String? educationLevelName;
  final String? gradeId;
  final String? gradeName;
  final String? subjectId;
  final String? subjectName;
  final LessonAuthoringCapabilities capabilities;
  final List<AuthoringCurriculumOption> availableCurricula;
  final List<AuthoringLevelOption> availableLevels;

  factory LessonAuthoringContext.fromJson(Map<String, dynamic> json) {
    return LessonAuthoringContext(
      countryCode: json['country_code'] as String? ?? 'TZ',
      countryName: json['country_name'] as String? ?? 'Tanzania',
      curriculumId: json['curriculum_id'] as String?,
      curriculumName: json['curriculum_name'] as String?,
      curriculumCode: json['curriculum_code'] as String?,
      authorityName: json['authority_name'] as String?,
      authorityCode: json['authority_code'] as String?,
      curriculumVersionId: json['curriculum_version_id'] as String?,
      curriculumVersionCode: json['curriculum_version_code'] as String?,
      curriculumVersionName: json['curriculum_version_name'] as String?,
      educationLevelId: json['education_level_id'] as String?,
      educationLevelName: json['education_level_name'] as String?,
      gradeId: json['grade_id'] as String?,
      gradeName: json['grade_name'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      capabilities: json['capabilities'] is Map
          ? LessonAuthoringCapabilities.fromJson(
              Map<String, dynamic>.from(json['capabilities'] as Map),
            )
          : const LessonAuthoringCapabilities(),
      availableCurricula: (json['available_curricula'] as List<dynamic>? ?? const [])
          .map((e) => AuthoringCurriculumOption.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      availableLevels: (json['available_levels'] as List<dynamic>? ?? const [])
          .map((e) => AuthoringLevelOption.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

@immutable
class AuthoringGradeOption {
  const AuthoringGradeOption({
    required this.id,
    required this.curriculumId,
    required this.educationLevelId,
    required this.educationLevelName,
    required this.name,
    required this.code,
    this.sequence = 1,
    this.subjectCount = 0,
  });

  final String id;
  final String curriculumId;
  final String educationLevelId;
  final String educationLevelName;
  final String name;
  final String code;
  final int sequence;
  final int subjectCount;

  factory AuthoringGradeOption.fromJson(Map<String, dynamic> json) {
    return AuthoringGradeOption(
      id: json['id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      educationLevelName: json['education_level_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 1,
      subjectCount: (json['subject_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AuthoringSubjectOption {
  const AuthoringSubjectOption({
    required this.id,
    required this.countryCode,
    required this.curriculumId,
    required this.educationLevelId,
    this.gradeId,
    required this.code,
    required this.name,
    required this.officialName,
    this.classification = 'compulsory',
    this.language = 'en',
    this.mainCompetenceCount = 0,
  });

  final String id;
  final String countryCode;
  final String curriculumId;
  final String educationLevelId;
  final String? gradeId;
  final String code;
  final String name;
  final String officialName;
  final String classification;
  final String language;
  final int mainCompetenceCount;

  factory AuthoringSubjectOption.fromJson(Map<String, dynamic> json) {
    return AuthoringSubjectOption(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      gradeId: json['grade_id'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      officialName: json['official_name'] as String? ?? json['name'] as String? ?? '',
      classification: json['classification'] as String? ?? 'compulsory',
      language: json['language'] as String? ?? 'en',
      mainCompetenceCount: (json['main_competence_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AuthoringMainCompetenceOption {
  const AuthoringMainCompetenceOption({
    required this.id,
    required this.subjectId,
    this.curriculumVersionId,
    required this.code,
    required this.title,
    this.description = '',
    this.displayOrder = 1,
    this.specificCompetenceCount = 0,
  });

  final String id;
  final String subjectId;
  final String? curriculumVersionId;
  final String code;
  final String title;
  final String description;
  final int displayOrder;
  final int specificCompetenceCount;

  factory AuthoringMainCompetenceOption.fromJson(Map<String, dynamic> json) {
    return AuthoringMainCompetenceOption(
      id: json['id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      curriculumVersionId: json['curriculum_version_id'] as String?,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      specificCompetenceCount:
          (json['specific_competence_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AuthoringSubtopicOption {
  const AuthoringSubtopicOption({
    required this.id,
    required this.topicId,
    required this.title,
    this.description = '',
    this.learningOutcome = '',
    this.assessmentCriteria,
    this.periodAllocation,
    this.sourcePage,
    this.displayOrder = 1,
  });

  final String id;
  final String topicId;
  final String title;
  final String description;
  final String learningOutcome;
  final String? assessmentCriteria;
  final int? periodAllocation;
  final int? sourcePage;
  final int displayOrder;

  factory AuthoringSubtopicOption.fromJson(Map<String, dynamic> json) {
    return AuthoringSubtopicOption(
      id: json['id'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      learningOutcome: json['learning_outcome'] as String? ?? '',
      assessmentCriteria: json['assessment_criteria'] as String?,
      periodAllocation: (json['period_allocation'] as num?)?.toInt(),
      sourcePage: (json['source_page'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

@immutable
class AuthoringSpecificCompetenceOption {
  const AuthoringSpecificCompetenceOption({
    required this.id,
    required this.mainCompetenceId,
    required this.subjectId,
    this.topicId,
    this.topicTitle,
    required this.code,
    required this.title,
    this.description = '',
    this.periodAllocation,
    this.assessmentCriteria,
    this.sourcePage,
    this.displayOrder = 1,
    this.subtopics = const [],
  });

  final String id;
  final String mainCompetenceId;
  final String subjectId;
  final String? topicId;
  final String? topicTitle;
  final String code;
  final String title;
  final String description;
  final int? periodAllocation;
  final String? assessmentCriteria;
  final int? sourcePage;
  final int displayOrder;
  final List<AuthoringSubtopicOption> subtopics;

  factory AuthoringSpecificCompetenceOption.fromJson(Map<String, dynamic> json) {
    return AuthoringSpecificCompetenceOption(
      id: json['id'] as String? ?? '',
      mainCompetenceId: json['main_competence_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      topicId: json['topic_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      periodAllocation: (json['period_allocation'] as num?)?.toInt(),
      assessmentCriteria: json['assessment_criteria'] as String?,
      sourcePage: (json['source_page'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      subtopics: (json['subtopics'] as List<dynamic>? ?? const [])
          .map((e) => AuthoringSubtopicOption.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

enum LessonContentBlockType {
  textExplanation('text_explanation', 'Text Explanation'),
  heading('heading', 'Heading'),
  image('image', 'Image'),
  audio('audio', 'Audio'),
  video('video', 'Video'),
  diagram('diagram', 'Diagram / Illustration'),
  example('example', 'Example'),
  workedExample('worked_example', 'Worked Example'),
  instruction('instruction', 'Teacher / Learner Instruction'),
  interactiveActivity('interactive_activity', 'Interactive Activity'),
  summary('summary', 'Summary'),
  keyVocabulary('key_vocabulary', 'Key Vocabulary');

  const LessonContentBlockType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static LessonContentBlockType fromString(String? value) {
    return LessonContentBlockType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => LessonContentBlockType.textExplanation,
    );
  }
}

@immutable
class LessonContentBlock {
  const LessonContentBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.mediaAssetId,
    this.mediaUrl,
    this.caption,
    this.altText,
  });

  final String id;
  final LessonContentBlockType type;
  final String title;
  final String content;
  final String? mediaAssetId;
  final String? mediaUrl;
  final String? caption;
  final String? altText;

  LessonContentBlock copyWith({
    LessonContentBlockType? type,
    String? title,
    String? content,
    String? mediaAssetId,
    String? mediaUrl,
    String? caption,
    String? altText,
  }) {
    return LessonContentBlock(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      altText: altText ?? this.altText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.dbValue,
        'title': title,
        'content': content,
        if (mediaAssetId != null) 'media_asset_id': mediaAssetId,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (caption != null) 'caption': caption,
        if (altText != null) 'alt_text': altText,
      };

  factory LessonContentBlock.fromJson(Map<String, dynamic> json) {
    return LessonContentBlock(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: LessonContentBlockType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mediaAssetId: json['media_asset_id'] as String?,
      mediaUrl: json['media_url'] as String?,
      caption: json['caption'] as String?,
      altText: json['alt_text'] as String?,
    );
  }
}

@immutable
class LessonLearningOutcome {
  const LessonLearningOutcome({
    required this.id,
    required this.outcome,
    this.cognitiveLevel = 'application',
    this.assessable = true,
    this.assessmentEvidence = '',
  });

  final String id;
  final String outcome;
  final String cognitiveLevel;
  final bool assessable;
  final String assessmentEvidence;

  Map<String, dynamic> toJson() => {
        'id': id,
        'outcome': outcome,
        'cognitive_level': cognitiveLevel,
        'assessable': assessable,
        'assessment_evidence': assessmentEvidence,
      };

  factory LessonLearningOutcome.fromJson(Map<String, dynamic> json) {
    return LessonLearningOutcome(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      outcome: json['outcome'] as String? ?? '',
      cognitiveLevel: json['cognitive_level'] as String? ?? 'application',
      assessable: json['assessable'] as bool? ?? true,
      assessmentEvidence: json['assessment_evidence'] as String? ?? '',
    );
  }
}

@immutable
class LessonTeachingActivity {
  const LessonTeachingActivity({
    required this.id,
    required this.title,
    required this.instructions,
    required this.learningObjective,
    required this.requiredMaterials,
    required this.estimatedMinutes,
    required this.activityType,
    required this.expectedResponse,
    required this.assessmentCriteria,
  });

  final String id;
  final String title;
  final String instructions;
  final String learningObjective;
  final String requiredMaterials;
  final int estimatedMinutes;
  final String activityType; // individual, pair, group, practical, interactive
  final String expectedResponse;
  final String assessmentCriteria;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instructions': instructions,
        'learning_objective': learningObjective,
        'required_materials': requiredMaterials,
        'estimated_minutes': estimatedMinutes,
        'activity_type': activityType,
        'expected_response': expectedResponse,
        'assessment_criteria': assessmentCriteria,
      };

  factory LessonTeachingActivity.fromJson(Map<String, dynamic> json) {
    return LessonTeachingActivity(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      learningObjective: json['learning_objective'] as String? ?? '',
      requiredMaterials:
          json['required_materials'] as String? ?? json['materials'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      activityType: json['activity_type'] as String? ?? 'individual',
      expectedResponse: json['expected_response'] as String? ?? '',
      assessmentCriteria: json['assessment_criteria'] as String? ?? '',
    );
  }
}

enum LessonQuestionType {
  multipleChoice('multiple_choice', 'Multiple Choice'),
  trueFalse('true_false', 'True / False'),
  shortAnswer('short_answer', 'Short Answer'),
  matching('matching', 'Matching'),
  fillInTheBlank('fill_in_the_blank', 'Fill in the Blank'),
  listening('listening', 'Listening Activity'),
  oralResponse('oral_response', 'Oral Response'),
  practicalTask('practical_task', 'Practical Task');

  const LessonQuestionType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static LessonQuestionType fromString(String? value) {
    return LessonQuestionType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => LessonQuestionType.multipleChoice,
    );
  }
}

@immutable
class LessonAssessmentQuestion {
  const LessonAssessmentQuestion({
    this.id,
    required this.questionType,
    required this.questionText,
    required this.correctAnswer,
    this.options = const [],
    this.explanation = '',
    this.marks = 1.0,
    this.difficultyLevel = 'medium',
    this.learningOutcomeRef,
    this.assessmentCriteria = '',
    this.cognitiveTier = 'knowledge',
  });

  final String? id;
  final LessonQuestionType questionType;
  final String questionText;
  final dynamic correctAnswer;
  final List<String> options;
  final String explanation;
  final double marks;
  final String difficultyLevel;
  final String? learningOutcomeRef;
  final String assessmentCriteria;
  final String cognitiveTier;

  factory LessonAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'];
    final opts = <String>[];
    if (rawOpts is List) {
      for (final item in rawOpts) {
        opts.add(item.toString());
      }
    }
    return LessonAssessmentQuestion(
      id: json['id'] as String?,
      questionType:
          LessonQuestionType.fromString(json['question_type'] as String?),
      questionText: json['question_text'] as String? ?? '',
      correctAnswer: json['correct_answer'],
      options: opts,
      explanation: json['explanation'] as String? ?? '',
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      learningOutcomeRef: json['learning_outcome_ref'] as String?,
      assessmentCriteria: json['assessment_criteria'] as String? ?? '',
      cognitiveTier: json['cognitive_tier'] as String? ?? 'knowledge',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'question_type': questionType.dbValue,
        'question_text': questionText,
        'correct_answer': correctAnswer,
        'options': options,
        'explanation': explanation,
        'marks': marks,
        'difficulty_level': difficultyLevel,
        'learning_outcome_ref': learningOutcomeRef,
        'assessment_criteria': assessmentCriteria,
        'cognitive_tier': cognitiveTier,
      };
}

@immutable
class LessonRevisionRecord {
  const LessonRevisionRecord({
    required this.id,
    required this.versionNumber,
    required this.title,
    this.summary,
    required this.status,
    this.changeSummary,
    this.createdAt,
  });

  final String id;
  final int versionNumber;
  final String title;
  final String? summary;
  final String status;
  final String? changeSummary;
  final DateTime? createdAt;

  factory LessonRevisionRecord.fromJson(Map<String, dynamic> json) {
    return LessonRevisionRecord(
      id: json['id'] as String? ?? '',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
      status: json['status'] as String? ?? 'draft',
      changeSummary: json['change_summary'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

@immutable
class LessonReviewAuditEvent {
  const LessonReviewAuditEvent({
    required this.id,
    required this.action,
    this.fromStatus,
    required this.toStatus,
    required this.versionNumber,
    this.comments,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? fromStatus;
  final String toStatus;
  final int versionNumber;
  final String? comments;
  final DateTime? createdAt;

  factory LessonReviewAuditEvent.fromJson(Map<String, dynamic> json) {
    return LessonReviewAuditEvent(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? '',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      comments: json['comments'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
