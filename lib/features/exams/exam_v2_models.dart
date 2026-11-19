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
