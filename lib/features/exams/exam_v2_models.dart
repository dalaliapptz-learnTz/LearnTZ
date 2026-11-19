import 'package:flutter/foundation.dart';

class ExamV2CountryOption {
  const ExamV2CountryOption({
    required this.countryCode,
    required this.displayName,
    required this.curriculumId,
    required this.curriculumCode,
    required this.curriculumName,
    this.authorityName,
    this.authorityCode,
    this.curriculumVersionId,
    this.curriculumVersionCode,
    this.curriculumVersionName,
  });

  final String countryCode;
  final String displayName;
  final String curriculumId;
  final String curriculumCode;
  final String curriculumName;
  final String? authorityName;
  final String? authorityCode;
  final String? curriculumVersionId;
  final String? curriculumVersionCode;
  final String? curriculumVersionName;

  factory ExamV2CountryOption.fromJson(Map<String, dynamic> json) {
    return ExamV2CountryOption(
      countryCode: json['country_code'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      curriculumCode: json['curriculum_code'] as String? ?? '',
      curriculumName: json['curriculum_name'] as String? ?? '',
      authorityName: json['authority_name'] as String?,
      authorityCode: json['authority_code'] as String?,
      curriculumVersionId: json['curriculum_version_id'] as String?,
      curriculumVersionCode: json['curriculum_version_code'] as String?,
      curriculumVersionName: json['curriculum_version_name'] as String?,
    );
  }
}

class ExamV2EducationLevelOption {
  const ExamV2EducationLevelOption({
    required this.id,
    required this.curriculumId,
    required this.countryCode,
    required this.code,
    required this.name,
    required this.sequence,
    required this.gradeCount,
  });

  final String id;
  final String curriculumId;
  final String countryCode;
  final String code;
  final String name;
  final int sequence;
  final int gradeCount;

  factory ExamV2EducationLevelOption.fromJson(Map<String, dynamic> json) {
    return ExamV2EducationLevelOption(
      id: json['id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      gradeCount: (json['grade_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamV2GradeOption {
  const ExamV2GradeOption({
    required this.id,
    required this.curriculumId,
    required this.educationLevelId,
    required this.code,
    required this.name,
    required this.sequence,
    required this.subjectCount,
  });

  final String id;
  final String curriculumId;
  final String educationLevelId;
  final String code;
  final String name;
  final int sequence;
  final int subjectCount;

  factory ExamV2GradeOption.fromJson(Map<String, dynamic> json) {
    return ExamV2GradeOption(
      id: json['id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      subjectCount: (json['subject_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamV2SubjectOption {
  const ExamV2SubjectOption({
    required this.id,
    required this.curriculumId,
    required this.educationLevelId,
    required this.gradeId,
    required this.countryCode,
    required this.code,
    required this.name,
    this.officialName,
    this.language = 'en',
    required this.mainCompetenceCount,
    required this.specificCompetenceCount,
  });

  final String id;
  final String curriculumId;
  final String educationLevelId;
  final String gradeId;
  final String countryCode;
  final String code;
  final String name;
  final String? officialName;
  final String language;
  final int mainCompetenceCount;
  final int specificCompetenceCount;

  factory ExamV2SubjectOption.fromJson(Map<String, dynamic> json) {
    return ExamV2SubjectOption(
      id: json['id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      officialName: json['official_name'] as String?,
      language: json['language'] as String? ?? 'en',
      mainCompetenceCount:
          (json['main_competence_count'] as num?)?.toInt() ?? 0,
      specificCompetenceCount:
          (json['specific_competence_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamV2ExaminationTypeOption {
  const ExamV2ExaminationTypeOption({
    required this.id,
    required this.countryCode,
    this.educationLevelCode,
    required this.code,
    required this.name,
    this.description = '',
    required this.defaultDurationMinutes,
    required this.defaultTotalMarks,
    required this.allowsOnlineDelivery,
    required this.allowsPrintedDelivery,
    required this.requiresAcademicReview,
  });

  final String id;
  final String countryCode;
  final String? educationLevelCode;
  final String code;
  final String name;
  final String description;
  final int defaultDurationMinutes;
  final double defaultTotalMarks;
  final bool allowsOnlineDelivery;
  final bool allowsPrintedDelivery;
  final bool requiresAcademicReview;

  factory ExamV2ExaminationTypeOption.fromJson(Map<String, dynamic> json) {
    return ExamV2ExaminationTypeOption(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      educationLevelCode: json['education_level_code'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      defaultDurationMinutes:
          (json['default_duration_minutes'] as num?)?.toInt() ?? 90,
      defaultTotalMarks:
          (json['default_total_marks'] as num?)?.toDouble() ?? 50,
      allowsOnlineDelivery: json['allows_online_delivery'] as bool? ?? true,
      allowsPrintedDelivery: json['allows_printed_delivery'] as bool? ?? true,
      requiresAcademicReview: json['requires_academic_review'] as bool? ?? true,
    );
  }
}

class ExamV2SpecificCompetence {
  const ExamV2SpecificCompetence({
    required this.id,
    required this.topicId,
    required this.code,
    required this.title,
    this.description,
    this.periodAllocation,
    this.assessmentCriteria,
    this.sourcePage,
    required this.questionCount,
    required this.subtopicCount,
  });

  final String id;
  final String topicId;
  final String code;
  final String title;
  final String? description;
  final int? periodAllocation;
  final String? assessmentCriteria;
  final int? sourcePage;
  final int questionCount;
  final int subtopicCount;

  factory ExamV2SpecificCompetence.fromJson(Map<String, dynamic> json) {
    return ExamV2SpecificCompetence(
      id: json['id'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      periodAllocation: (json['period_allocation'] as num?)?.toInt(),
      assessmentCriteria: json['assessment_criteria'] as String?,
      sourcePage: (json['source_page'] as num?)?.toInt(),
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      subtopicCount: (json['subtopic_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamV2MainCompetence {
  const ExamV2MainCompetence({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.displayOrder,
    required this.specificCompetences,
  });

  final String id;
  final String code;
  final String title;
  final String? description;
  final int displayOrder;
  final List<ExamV2SpecificCompetence> specificCompetences;

  factory ExamV2MainCompetence.fromJson(Map<String, dynamic> json) {
    return ExamV2MainCompetence(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      specificCompetences: (json['specific_competences'] as List<dynamic>? ??
              const [])
          .map((e) => ExamV2SpecificCompetence.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

class ExamV2AcademicContext {
  const ExamV2AcademicContext({
    required this.countryCode,
    required this.countryName,
    required this.curriculumId,
    required this.curriculumCode,
    required this.curriculumName,
    this.authorityName,
    this.authorityCode,
    this.curriculumVersionId,
    this.curriculumVersionCode,
    this.curriculumVersionName,
    required this.educationLevelId,
    required this.educationLevelCode,
    required this.educationLevelName,
    required this.gradeId,
    required this.gradeCode,
    required this.gradeName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    this.subjectOfficialName,
    required this.language,
    required this.examinationTypeId,
    required this.examinationTypeCode,
    required this.examinationTypeName,
    this.examinationTypeDescription = '',
    required this.defaultDurationMinutes,
    required this.defaultTotalMarks,
    required this.allowsOnlineDelivery,
    required this.allowsPrintedDelivery,
    required this.requiresAcademicReview,
    required this.suggestedExaminationTitle,
  });

  final String countryCode;
  final String countryName;
  final String curriculumId;
  final String curriculumCode;
  final String curriculumName;
  final String? authorityName;
  final String? authorityCode;
  final String? curriculumVersionId;
  final String? curriculumVersionCode;
  final String? curriculumVersionName;
  final String educationLevelId;
  final String educationLevelCode;
  final String educationLevelName;
  final String gradeId;
  final String gradeCode;
  final String gradeName;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String? subjectOfficialName;
  final String language;
  final String examinationTypeId;
  final String examinationTypeCode;
  final String examinationTypeName;
  final String examinationTypeDescription;
  final int defaultDurationMinutes;
  final double defaultTotalMarks;
  final bool allowsOnlineDelivery;
  final bool allowsPrintedDelivery;
  final bool requiresAcademicReview;
  final String suggestedExaminationTitle;

  factory ExamV2AcademicContext.fromJson(Map<String, dynamic> json) {
    return ExamV2AcademicContext(
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      curriculumCode: json['curriculum_code'] as String? ?? '',
      curriculumName: json['curriculum_name'] as String? ?? '',
      authorityName: json['authority_name'] as String?,
      authorityCode: json['authority_code'] as String?,
      curriculumVersionId: json['curriculum_version_id'] as String?,
      curriculumVersionCode: json['curriculum_version_code'] as String?,
      curriculumVersionName: json['curriculum_version_name'] as String?,
      educationLevelId: json['education_level_id'] as String? ?? '',
      educationLevelCode: json['education_level_code'] as String? ?? '',
      educationLevelName: json['education_level_name'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      gradeCode: json['grade_code'] as String? ?? '',
      gradeName: json['grade_name'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectOfficialName: json['subject_official_name'] as String?,
      language: json['language'] as String? ?? 'en',
      examinationTypeId: json['examination_type_id'] as String? ?? '',
      examinationTypeCode: json['examination_type_code'] as String? ?? '',
      examinationTypeName: json['examination_type_name'] as String? ?? '',
      examinationTypeDescription:
          json['examination_type_description'] as String? ?? '',
      defaultDurationMinutes:
          (json['default_duration_minutes'] as num?)?.toInt() ?? 90,
      defaultTotalMarks:
          (json['default_total_marks'] as num?)?.toDouble() ?? 50,
      allowsOnlineDelivery: json['allows_online_delivery'] as bool? ?? true,
      allowsPrintedDelivery: json['allows_printed_delivery'] as bool? ?? true,
      requiresAcademicReview: json['requires_academic_review'] as bool? ?? true,
      suggestedExaminationTitle:
          json['suggested_examination_title'] as String? ?? '',
    );
  }
}

class ExamV2ContextSummary {
  const ExamV2ContextSummary({
    required this.context,
    required this.questionBankCount,
    required this.examinationPapersCount,
    required this.alignedLessonsCount,
    required this.mainCompetences,
  });

  final ExamV2AcademicContext context;
  final int questionBankCount;
  final int examinationPapersCount;
  final int alignedLessonsCount;
  final List<ExamV2MainCompetence> mainCompetences;

  int get totalSpecificCompetences => mainCompetences.fold(
        0,
        (acc, mc) => acc + mc.specificCompetences.length,
      );

  factory ExamV2ContextSummary.fromJson(Map<String, dynamic> json) {
    final stats = Map<String, dynamic>.from(
      json['stats'] as Map? ?? const <String, dynamic>{},
    );
    return ExamV2ContextSummary(
      context: ExamV2AcademicContext.fromJson(
        Map<String, dynamic>.from(json['context'] as Map),
      ),
      questionBankCount: (stats['question_bank_count'] as num?)?.toInt() ?? 0,
      examinationPapersCount:
          (stats['examination_papers_count'] as num?)?.toInt() ?? 0,
      alignedLessonsCount:
          (stats['aligned_lessons_count'] as num?)?.toInt() ?? 0,
      mainCompetences: (json['main_competences'] as List<dynamic>? ?? const [])
          .map((e) => ExamV2MainCompetence.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

@immutable
class ExamV2SelectionKey {
  const ExamV2SelectionKey({
    required this.countryCode,
    required this.educationLevelId,
    required this.gradeId,
    required this.subjectId,
    required this.examinationTypeId,
  });

  final String countryCode;
  final String educationLevelId;
  final String gradeId;
  final String subjectId;
  final String examinationTypeId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamV2SelectionKey &&
        other.countryCode == countryCode &&
        other.educationLevelId == educationLevelId &&
        other.gradeId == gradeId &&
        other.subjectId == subjectId &&
        other.examinationTypeId == examinationTypeId;
  }

  @override
  int get hashCode => Object.hash(
        countryCode,
        educationLevelId,
        gradeId,
        subjectId,
        examinationTypeId,
      );
}

// ============================================================================
// Phase 2: Examination Master, Blueprint Sections & Curriculum Coverage Models
// ============================================================================

class ExamV2SectionDraft {
  const ExamV2SectionDraft({
    required this.sectionCode,
    required this.title,
    required this.questionFormat,
    this.instructions = '',
    this.questionCount = 5,
    this.marksAllocated = 10,
    this.displayOrder = 1,
  });

  final String sectionCode;
  final String title;
  final String questionFormat;
  final String instructions;
  final int questionCount;
  final double marksAllocated;
  final int displayOrder;

  ExamV2SectionDraft copyWith({
    String? sectionCode,
    String? title,
    String? questionFormat,
    String? instructions,
    int? questionCount,
    double? marksAllocated,
    int? displayOrder,
  }) {
    return ExamV2SectionDraft(
      sectionCode: sectionCode ?? this.sectionCode,
      title: title ?? this.title,
      questionFormat: questionFormat ?? this.questionFormat,
      instructions: instructions ?? this.instructions,
      questionCount: questionCount ?? this.questionCount,
      marksAllocated: marksAllocated ?? this.marksAllocated,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'section_code': sectionCode,
        'title': title,
        'question_format': questionFormat,
        'instructions': instructions,
        'question_count': questionCount,
        'marks_allocated': marksAllocated,
        'display_order': displayOrder,
      };

  factory ExamV2SectionDraft.fromJson(Map<String, dynamic> json) {
    return ExamV2SectionDraft(
      sectionCode: json['section_code'] as String? ?? 'A',
      title: json['title'] as String? ?? '',
      questionFormat: json['question_format'] as String? ?? 'multiple_choice',
      instructions: json['instructions'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 5,
      marksAllocated: (json['marks_allocated'] as num?)?.toDouble() ?? 10,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class ExamV2CompetencyAllocation {
  const ExamV2CompetencyAllocation({
    required this.specificCompetenceId,
    required this.allocatedMarks,
    this.targetQuestionCount = 5,
    this.notes = '',
  });

  final String specificCompetenceId;
  final double allocatedMarks;
  final int targetQuestionCount;
  final String notes;

  Map<String, dynamic> toJson() => {
        'specific_competence_id': specificCompetenceId,
        'allocated_marks': allocatedMarks,
        'target_question_count': targetQuestionCount,
        'notes': notes,
      };
}

class ExamV2ExaminationSummary {
  const ExamV2ExaminationSummary({
    required this.id,
    required this.title,
    required this.countryCode,
    required this.countryName,
    required this.curriculumName,
    this.curriculumVersionCode,
    required this.educationLevelName,
    required this.gradeName,
    required this.subjectName,
    required this.examinationTypeName,
    required this.academicYear,
    required this.academicTerm,
    this.examinationDate,
    required this.durationMinutes,
    required this.totalMarks,
    required this.languageCode,
    required this.deliveryMode,
    required this.status,
    required this.isPublished,
    required this.versionNumber,
    this.reviewNotes,
    required this.sectionCount,
    required this.competencyCount,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String countryCode;
  final String countryName;
  final String curriculumName;
  final String? curriculumVersionCode;
  final String educationLevelName;
  final String gradeName;
  final String subjectName;
  final String examinationTypeName;
  final int academicYear;
  final String academicTerm;
  final String? examinationDate;
  final int durationMinutes;
  final double totalMarks;
  final String languageCode;
  final String deliveryMode;
  final String status;
  final bool isPublished;
  final int versionNumber;
  final String? reviewNotes;
  final int sectionCount;
  final int competencyCount;
  final DateTime? updatedAt;

  factory ExamV2ExaminationSummary.fromJson(Map<String, dynamic> json) {
    return ExamV2ExaminationSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      curriculumName: json['curriculum_name'] as String? ?? '',
      curriculumVersionCode: json['curriculum_version_code'] as String?,
      educationLevelName: json['education_level_name'] as String? ?? '',
      gradeName: json['grade_name'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      examinationTypeName: json['examination_type_name'] as String? ?? '',
      academicYear: (json['academic_year'] as num?)?.toInt() ?? 2026,
      academicTerm: json['academic_term'] as String? ?? 'Term I',
      examinationDate: json['examination_date'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 90,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      languageCode: json['language_code'] as String? ?? 'en',
      deliveryMode: json['delivery_mode'] as String? ?? 'hybrid',
      status: json['status'] as String? ?? 'draft',
      isPublished: json['is_published'] as bool? ?? false,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      reviewNotes: json['review_notes'] as String?,
      sectionCount: (json['section_count'] as num?)?.toInt() ?? 0,
      competencyCount: (json['competency_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

class ExamV2ExaminationListResult {
  const ExamV2ExaminationListResult({
    required this.totalCount,
    required this.draftCount,
    required this.underReviewCount,
    required this.approvedCount,
    required this.publishedCount,
    required this.items,
  });

  final int totalCount;
  final int draftCount;
  final int underReviewCount;
  final int approvedCount;
  final int publishedCount;
  final List<ExamV2ExaminationSummary> items;

  factory ExamV2ExaminationListResult.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(
      json['summary'] as Map? ?? const <String, dynamic>{},
    );
    return ExamV2ExaminationListResult(
      totalCount: (summary['total_count'] as num?)?.toInt() ?? 0,
      draftCount: (summary['draft_count'] as num?)?.toInt() ?? 0,
      underReviewCount: (summary['under_review_count'] as num?)?.toInt() ?? 0,
      approvedCount: (summary['approved_count'] as num?)?.toInt() ?? 0,
      publishedCount: (summary['published_count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ExamV2ExaminationSummary.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

// ============================================================================
// Phase 3: Question Bank 2.0 Models
// ============================================================================

class ExamV2QuestionItem {
  const ExamV2QuestionItem({
    required this.id,
    required this.countryCode,
    required this.subjectId,
    required this.subjectName,
    this.mainCompetenceId,
    this.mainCompetenceCode,
    this.mainCompetenceTitle,
    this.specificCompetenceId,
    this.specificCompetenceCode,
    this.specificCompetenceTitle,
    required this.questionType,
    required this.difficultyLevel,
    this.cognitiveTier,
    required this.questionText,
    this.options = const [],
    this.correctAnswer,
    this.markingRubric,
    this.explanation,
    required this.marks,
    this.languageCode = 'en',
    this.sourceReference = '',
    this.copyrightNotice = '',
    required this.reviewStatus,
    required this.isPublished,
    required this.versionNumber,
    this.reviewNotes,
  });

  final String id;
  final String countryCode;
  final String subjectId;
  final String subjectName;
  final String? mainCompetenceId;
  final String? mainCompetenceCode;
  final String? mainCompetenceTitle;
  final String? specificCompetenceId;
  final String? specificCompetenceCode;
  final String? specificCompetenceTitle;
  final String questionType;
  final String difficultyLevel;
  final String? cognitiveTier;
  final String questionText;
  final List<dynamic> options;
  final Map<String, dynamic>? correctAnswer;
  final Map<String, dynamic>? markingRubric;
  final String? explanation;
  final double marks;
  final String languageCode;
  final String sourceReference;
  final String copyrightNotice;
  final String reviewStatus;
  final bool isPublished;
  final int versionNumber;
  final String? reviewNotes;

  factory ExamV2QuestionItem.fromJson(Map<String, dynamic> json) {
    return ExamV2QuestionItem(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      mainCompetenceId: json['main_competence_id'] as String?,
      mainCompetenceCode: json['main_competence_code'] as String?,
      mainCompetenceTitle: json['main_competence_title'] as String?,
      specificCompetenceId: json['specific_competence_id'] as String?,
      specificCompetenceCode: json['specific_competence_code'] as String?,
      specificCompetenceTitle: json['specific_competence_title'] as String?,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      cognitiveTier: json['cognitive_tier'] as String?,
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>?) ?? const [],
      correctAnswer: json['correct_answer'] is Map
          ? Map<String, dynamic>.from(json['correct_answer'] as Map)
          : null,
      markingRubric: json['marking_rubric'] is Map
          ? Map<String, dynamic>.from(json['marking_rubric'] as Map)
          : null,
      explanation: json['explanation'] as String?,
      marks: (json['marks'] as num?)?.toDouble() ?? 1,
      languageCode: json['language_code'] as String? ?? 'en',
      sourceReference: json['source_reference'] as String? ?? '',
      copyrightNotice: json['copyright_notice'] as String? ?? '',
      reviewStatus: json['review_status'] as String? ?? 'draft',
      isPublished: json['is_published'] as bool? ?? false,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      reviewNotes: json['review_notes'] as String?,
    );
  }
}

class ExamV2QuestionListResult {
  const ExamV2QuestionListResult({
    required this.totalCount,
    required this.draftCount,
    required this.inReviewCount,
    required this.approvedCount,
    required this.items,
  });

  final int totalCount;
  final int draftCount;
  final int inReviewCount;
  final int approvedCount;
  final List<ExamV2QuestionItem> items;

  factory ExamV2QuestionListResult.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(
      json['summary'] as Map? ?? const <String, dynamic>{},
    );
    return ExamV2QuestionListResult(
      totalCount: (summary['total_count'] as num?)?.toInt() ?? 0,
      draftCount: (summary['draft_count'] as num?)?.toInt() ?? 0,
      inReviewCount: (summary['in_review_count'] as num?)?.toInt() ?? 0,
      approvedCount: (summary['approved_count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ExamV2QuestionItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

// ============================================================================
// Phase 4: Examination Paper Builder Models
// ============================================================================

class ExamV2PaperQuestion {
  const ExamV2PaperQuestion({
    required this.id,
    required this.sectionId,
    this.sourceQuestionId,
    required this.sourceQuestionVersion,
    this.specificCompetenceId,
    this.specificCompetenceCode,
    required this.questionNumber,
    required this.displayOrder,
    required this.marks,
    required this.questionType,
    required this.questionText,
    this.options = const [],
    this.correctAnswer,
    this.markingRubric,
    this.explanation,
  });

  final String id;
  final String sectionId;
  final String? sourceQuestionId;
  final int sourceQuestionVersion;
  final String? specificCompetenceId;
  final String? specificCompetenceCode;
  final int questionNumber;
  final int displayOrder;
  final double marks;
  final String questionType;
  final String questionText;
  final List<dynamic> options;
  final Map<String, dynamic>? correctAnswer;
  final Map<String, dynamic>? markingRubric;
  final String? explanation;

  factory ExamV2PaperQuestion.fromJson(Map<String, dynamic> json) {
    return ExamV2PaperQuestion(
      id: json['id'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      sourceQuestionId: json['source_question_id'] as String?,
      sourceQuestionVersion:
          (json['source_question_version'] as num?)?.toInt() ?? 1,
      specificCompetenceId: json['specific_competence_id'] as String?,
      specificCompetenceCode: json['specific_competence_code'] as String?,
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      marks: (json['marks'] as num?)?.toDouble() ?? 1,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>?) ?? const [],
      correctAnswer: json['correct_answer'] is Map
          ? Map<String, dynamic>.from(json['correct_answer'] as Map)
          : null,
      markingRubric: json['marking_rubric'] is Map
          ? Map<String, dynamic>.from(json['marking_rubric'] as Map)
          : null,
      explanation: json['explanation'] as String?,
    );
  }
}

class ExamV2PaperSection {
  const ExamV2PaperSection({
    required this.id,
    required this.sectionCode,
    required this.title,
    required this.questionFormat,
    this.instructions = '',
    required this.questionCount,
    required this.marksAllocated,
    required this.displayOrder,
    this.questions = const [],
  });

  final String id;
  final String sectionCode;
  final String title;
  final String questionFormat;
  final String instructions;
  final int questionCount;
  final double marksAllocated;
  final int displayOrder;
  final List<ExamV2PaperQuestion> questions;

  factory ExamV2PaperSection.fromJson(Map<String, dynamic> json) {
    return ExamV2PaperSection(
      id: json['id'] as String? ?? '',
      sectionCode: json['section_code'] as String? ?? 'A',
      title: json['title'] as String? ?? '',
      questionFormat: json['question_format'] as String? ?? 'multiple_choice',
      instructions: json['instructions'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      marksAllocated: (json['marks_allocated'] as num?)?.toDouble() ?? 0,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((e) => ExamV2PaperQuestion.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

class ExamV2PaperBuilderBundle {
  const ExamV2PaperBuilderBundle({
    required this.examination,
    required this.isValid,
    required this.validationIssues,
    required this.questionCount,
    required this.sections,
  });

  final Map<String, dynamic> examination;
  final bool isValid;
  final List<String> validationIssues;
  final int questionCount;
  final List<ExamV2PaperSection> sections;

  String get id => examination['id'] as String? ?? '';
  String get title => examination['title'] as String? ?? '';
  String get countryCode => examination['country_code'] as String? ?? '';
  String get countryName => examination['country_name'] as String? ?? '';
  String get gradeName => examination['grade_name'] as String? ?? '';
  String get subjectId => examination['subject_id'] as String? ?? '';
  String get subjectName => examination['subject_name'] as String? ?? '';
  String get examTypeName =>
      examination['examination_type_name'] as String? ?? '';
  String get instructions => examination['instructions'] as String? ?? '';
  String get status => examination['status'] as String? ?? 'draft';
  int get durationMinutes =>
      (examination['duration_minutes'] as num?)?.toInt() ?? 90;
  double get totalMarks =>
      (examination['total_marks'] as num?)?.toDouble() ?? 0;

  factory ExamV2PaperBuilderBundle.fromJson(Map<String, dynamic> json) {
    final val = Map<String, dynamic>.from(
      json['validation'] as Map? ?? const <String, dynamic>{},
    );
    return ExamV2PaperBuilderBundle(
      examination: Map<String, dynamic>.from(
        json['examination'] as Map? ?? const <String, dynamic>{},
      ),
      isValid: val['is_valid'] as bool? ?? false,
      validationIssues: (val['issues'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      questionCount: (val['question_count'] as num?)?.toInt() ?? 0,
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((e) => ExamV2PaperSection.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}
