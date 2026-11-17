import 'package:flutter/foundation.dart';

enum ContentWorkflowStatus {
  draft,
  inReview,
  approved,
  published,
  archived;

  String get dbValue => switch (this) {
        ContentWorkflowStatus.draft => 'draft',
        ContentWorkflowStatus.inReview => 'in_review',
        ContentWorkflowStatus.approved => 'approved',
        ContentWorkflowStatus.published => 'published',
        ContentWorkflowStatus.archived => 'archived',
      };

  String get displayName => switch (this) {
        ContentWorkflowStatus.draft => 'Draft',
        ContentWorkflowStatus.inReview => 'In Review',
        ContentWorkflowStatus.approved => 'Approved',
        ContentWorkflowStatus.published => 'Published',
        ContentWorkflowStatus.archived => 'Archived',
      };

  static ContentWorkflowStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'in_review':
        return ContentWorkflowStatus.inReview;
      case 'approved':
        return ContentWorkflowStatus.approved;
      case 'published':
        return ContentWorkflowStatus.published;
      case 'archived':
        return ContentWorkflowStatus.archived;
      case 'draft':
      default:
        return ContentWorkflowStatus.draft;
    }
  }
}

@immutable
class ContentStudioMetrics {
  const ContentStudioMetrics({
    required this.countryCode,
    required this.totalSubjects,
    required this.totalTopics,
    required this.totalLessons,
    required this.publishedLessons,
    required this.draftLessons,
    required this.inReviewLessons,
    required this.totalMediaAssets,
  });

  final String countryCode;
  final int totalSubjects;
  final int totalTopics;
  final int totalLessons;
  final int publishedLessons;
  final int draftLessons;
  final int inReviewLessons;
  final int totalMediaAssets;

  factory ContentStudioMetrics.fromJson(Map<String, dynamic> json) {
    return ContentStudioMetrics(
      countryCode: json['country_code'] as String? ?? 'ALL',
      totalSubjects: (json['total_subjects'] as num?)?.toInt() ?? 0,
      totalTopics: (json['total_topics'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      publishedLessons: (json['published_lessons'] as num?)?.toInt() ?? 0,
      draftLessons: (json['draft_lessons'] as num?)?.toInt() ?? 0,
      inReviewLessons: (json['in_review_lessons'] as num?)?.toInt() ?? 0,
      totalMediaAssets: (json['total_media_assets'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class StudioLessonItem {
  const StudioLessonItem({
    required this.lessonId,
    required this.lessonTitle,
    this.lessonSummary,
    this.estimatedMinutes = 10,
    this.isFreePreview = false,
    this.lessonOrder = 1,
    this.status = ContentWorkflowStatus.draft,
    this.isPublished = false,
    this.versionNumber = 1,
    this.updatedAt,
  });

  final String lessonId;
  final String lessonTitle;
  final String? lessonSummary;
  final int estimatedMinutes;
  final bool isFreePreview;
  final int lessonOrder;
  final ContentWorkflowStatus status;
  final bool isPublished;
  final int versionNumber;
  final DateTime? updatedAt;

  factory StudioLessonItem.fromJson(Map<String, dynamic> json) {
    return StudioLessonItem(
      lessonId: json['lesson_id'] as String? ?? '',
      lessonTitle: json['lesson_title'] as String? ?? '',
      lessonSummary: json['lesson_summary'] as String?,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      lessonOrder: (json['lesson_order'] as num?)?.toInt() ?? 1,
      status: ContentWorkflowStatus.fromString(json['lesson_status'] as String?),
      isPublished: json['lesson_is_published'] as bool? ?? false,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

@immutable
class StudioTopicItem {
  const StudioTopicItem({
    required this.topicId,
    required this.topicTitle,
    this.topicSummary,
    this.topicOrder = 1,
    this.isPublished = false,
    this.competencyCode,
    this.periodAllocation = 30,
    this.assessmentCriteria,
    this.sourcePage,
    this.lessons = const [],
  });

  final String topicId;
  final String topicTitle;
  final String? topicSummary;
  final int topicOrder;
  final bool isPublished;
  final String? competencyCode;
  final int periodAllocation;
  final String? assessmentCriteria;
  final int? sourcePage;
  final List<StudioLessonItem> lessons;

  factory StudioTopicItem.fromJson(Map<String, dynamic> json) {
    return StudioTopicItem(
      topicId: json['topic_id'] as String? ?? '',
      topicTitle: json['topic_title'] as String? ?? '',
      topicSummary: json['topic_summary'] as String?,
      topicOrder: (json['topic_order'] as num?)?.toInt() ?? 1,
      isPublished: json['topic_is_published'] as bool? ?? false,
      competencyCode: json['competency_code'] as String?,
      periodAllocation: (json['period_allocation'] as num?)?.toInt() ?? 30,
      assessmentCriteria: json['assessment_criteria'] as String?,
      sourcePage: (json['source_page'] as num?)?.toInt(),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((item) =>
                  StudioLessonItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioSubjectItem {
  const StudioSubjectItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.countryCode,
    this.subjectOrder = 1,
    this.educationLevelId,
    this.educationLevelName,
    this.gradeId,
    this.gradeName,
    this.gradeSequence = 0,
    this.officialName,
    this.classification,
    this.language,
    this.isPublished = false,
    this.authorityName,
    this.authorityCode,
    this.topics = const [],
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String countryCode;
  final int subjectOrder;
  final String? educationLevelId;
  final String? educationLevelName;
  final String? gradeId;
  final String? gradeName;
  final int gradeSequence;
  final String? officialName;
  final String? classification;
  final String? language;
  final bool isPublished;
  final String? authorityName;
  final String? authorityCode;
  final List<StudioTopicItem> topics;

  int get totalLessons =>
      topics.fold(0, (acc, topic) => acc + topic.lessons.length);

  int get publishedLessons => topics.fold(
      0,
      (acc, topic) =>
          acc + topic.lessons.where((l) => l.isPublished).length);

  int get totalPeriods =>
      topics.fold(0, (acc, topic) => acc + topic.periodAllocation);

  factory StudioSubjectItem.fromJson(Map<String, dynamic> json) {
    return StudioSubjectItem(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      subjectOrder: (json['subject_order'] as num?)?.toInt() ?? 1,
      educationLevelId: json['education_level_id'] as String?,
      educationLevelName: json['education_level_name'] as String?,
      gradeId: json['grade_id'] as String?,
      gradeName: json['grade_name'] as String?,
      gradeSequence: (json['grade_sequence'] as num?)?.toInt() ?? 0,
      officialName: json['official_name'] as String?,
      classification: json['classification'] as String?,
      language: json['language'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      authorityName: json['authority_name'] as String?,
      authorityCode: json['authority_code'] as String?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((item) =>
                  StudioTopicItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioGradeItem {
  const StudioGradeItem({
    required this.gradeId,
    required this.gradeName,
    required this.gradeCode,
    this.gradeSequence = 1,
    this.subjects = const [],
  });

  final String gradeId;
  final String gradeName;
  final String gradeCode;
  final int gradeSequence;
  final List<StudioSubjectItem> subjects;

  factory StudioGradeItem.fromJson(Map<String, dynamic> json) {
    return StudioGradeItem(
      gradeId: json['grade_id'] as String? ?? '',
      gradeName: json['grade_name'] as String? ?? '',
      gradeCode: json['grade_code'] as String? ?? '',
      gradeSequence: (json['grade_sequence'] as num?)?.toInt() ?? 1,
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((item) =>
                  StudioSubjectItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioEducationLevelItem {
  const StudioEducationLevelItem({
    required this.levelId,
    required this.levelName,
    required this.levelCode,
    this.levelSequence = 1,
    this.grades = const [],
  });

  final String levelId;
  final String levelName;
  final String levelCode;
  final int levelSequence;
  final List<StudioGradeItem> grades;

  factory StudioEducationLevelItem.fromJson(Map<String, dynamic> json) {
    return StudioEducationLevelItem(
      levelId: json['level_id'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      levelCode: json['level_code'] as String? ?? '',
      levelSequence: (json['level_sequence'] as num?)?.toInt() ?? 1,
      grades: (json['grades'] as List<dynamic>?)
              ?.map((item) =>
                  StudioGradeItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioCountryItem {
  const StudioCountryItem({
    required this.countryCode,
    required this.countryName,
    required this.productName,
    required this.currencyCode,
    this.isEnabled = true,
    required this.authorityName,
    required this.authorityCode,
    this.activeVersion = '2023 Edition',
    this.totalLevels = 0,
    this.totalGrades = 0,
    this.totalSubjects = 0,
    this.totalLessons = 0,
    this.educationLevels = const [],
  });

  final String countryCode;
  final String countryName;
  final String productName;
  final String currencyCode;
  final bool isEnabled;
  final String authorityName;
  final String authorityCode;
  final String activeVersion;
  final int totalLevels;
  final int totalGrades;
  final int totalSubjects;
  final int totalLessons;
  final List<StudioEducationLevelItem> educationLevels;

  String get flagEmoji => switch (countryCode.toUpperCase()) {
        'TZ' => '🇹🇿',
        'KE' => '🇰🇪',
        'UG' => '🇺🇬',
        'RW' => '🇷🇼',
        'BI' => '🇧🇮',
        'SS' => '🇸🇸',
        _ => '🌍',
      };

  factory StudioCountryItem.fromJson(Map<String, dynamic> json) {
    return StudioCountryItem(
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
      authorityName: json['authority_name'] as String? ?? 'Curriculum Authority',
      authorityCode: json['authority_code'] as String? ?? '',
      activeVersion: json['active_version'] as String? ?? '2023 Edition',
      totalLevels: (json['total_levels'] as num?)?.toInt() ?? 0,
      totalGrades: (json['total_grades'] as num?)?.toInt() ?? 0,
      totalSubjects: (json['total_subjects'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      educationLevels: (json['education_levels'] as List<dynamic>?)
              ?.map((item) => StudioEducationLevelItem.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioCompetencyItem {
  const StudioCompetencyItem({
    required this.code,
    required this.title,
    this.description = '',
    this.periodAllocation = 30,
    this.assessmentCriteria = '',
    this.isVerified = true,
  });

  final String code;
  final String title;
  final String description;
  final int periodAllocation;
  final String assessmentCriteria;
  final bool isVerified;
}

@immutable
class StudioStrandItem {
  const StudioStrandItem({
    required this.title,
    required this.substrands,
  });

  final String title;
  final List<String> substrands;
}

@immutable
class StudioLearningOutcomeItem {
  const StudioLearningOutcomeItem({
    required this.code,
    required this.outcome,
    required this.cognitiveLevel,
    required this.competencyCode,
  });

  final String code;
  final String outcome;
  final String cognitiveLevel;
  final String competencyCode;
}

@immutable
class StudioActivityItem {
  const StudioActivityItem({
    required this.title,
    required this.modality,
    required this.materials,
    required this.instructions,
  });

  final String title;
  final String modality;
  final String materials;
  final String instructions;
}

@immutable
class StudioAssessmentItem {
  const StudioAssessmentItem({
    required this.title,
    required this.type,
    required this.criteria,
    required this.rubric,
  });

  final String title;
  final String type;
  final String criteria;
  final String rubric;
}

@immutable
class StudioReviewEvent {
  const StudioReviewEvent({
    required this.stage,
    required this.actor,
    required this.role,
    required this.timestamp,
    required this.notes,
    required this.status,
  });

  final String stage;
  final String actor;
  final String role;
  final String timestamp;
  final String notes;
  final String status;
}

@immutable
class StudioSubjectWorkspaceDetail {
  const StudioSubjectWorkspaceDetail({
    required this.subject,
    this.curriculumVersion = '2023 Official Syllabus Edition',
    this.sourceDocumentTitle =
        'TIE English Language Syllabus for Primary Education Standards III-VI (2023)',
    this.competencies = const [],
    this.strands = const [],
    this.outcomes = const [],
    this.activities = const [],
    this.assessments = const [],
    this.reviewHistory = const [],
  });

  final StudioSubjectItem subject;
  final String curriculumVersion;
  final String sourceDocumentTitle;
  final List<StudioCompetencyItem> competencies;
  final List<StudioStrandItem> strands;
  final List<StudioLearningOutcomeItem> outcomes;
  final List<StudioActivityItem> activities;
  final List<StudioAssessmentItem> assessments;
  final List<StudioReviewEvent> reviewHistory;
}

@immutable
class MediaAssetItem {
  const MediaAssetItem({
    required this.id,
    required this.title,
    required this.countryCode,
    required this.mediaType,
    required this.fileUrl,
    this.fileSizeBytes = 0,
    this.altText,
    this.createdAt,
  });

  final String id;
  final String title;
  final String countryCode;
  final String mediaType;
  final String fileUrl;
  final int fileSizeBytes;
  final String? altText;
  final DateTime? createdAt;

  factory MediaAssetItem.fromJson(Map<String, dynamic> json) {
    return MediaAssetItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      mediaType: json['media_type'] as String? ?? 'image',
      fileUrl: json['file_url'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      altText: json['alt_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
