import 'package:flutter/foundation.dart';

import 'lesson_authoring_models.dart';

class ReviewQueueCountryOption {
  const ReviewQueueCountryOption({
    required this.countryCode,
    required this.displayName,
  });

  final String countryCode;
  final String displayName;

  factory ReviewQueueCountryOption.fromJson(Map<String, dynamic> json) {
    return ReviewQueueCountryOption(
      countryCode: json['country_code'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class ReviewQueueLevelOption {
  const ReviewQueueLevelOption({
    required this.id,
    required this.name,
    required this.code,
    required this.countryCode,
  });

  final String id;
  final String name;
  final String code;
  final String countryCode;

  factory ReviewQueueLevelOption.fromJson(Map<String, dynamic> json) {
    return ReviewQueueLevelOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
    );
  }
}

class ReviewQueueGradeOption {
  const ReviewQueueGradeOption({
    required this.id,
    required this.name,
    required this.code,
    required this.educationLevelId,
    required this.countryCode,
  });

  final String id;
  final String name;
  final String code;
  final String educationLevelId;
  final String countryCode;

  factory ReviewQueueGradeOption.fromJson(Map<String, dynamic> json) {
    return ReviewQueueGradeOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
    );
  }
}

class ReviewQueueSubjectOption {
  const ReviewQueueSubjectOption({
    required this.id,
    required this.name,
    required this.code,
    this.gradeId,
    this.gradeName,
    this.educationLevelId,
    required this.countryCode,
  });

  final String id;
  final String name;
  final String code;
  final String? gradeId;
  final String? gradeName;
  final String? educationLevelId;
  final String countryCode;

  String get displayLabel =>
      (gradeName != null && gradeName!.isNotEmpty) ? '$name ($gradeName)' : name;

  factory ReviewQueueSubjectOption.fromJson(Map<String, dynamic> json) {
    return ReviewQueueSubjectOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      gradeId: json['grade_id'] as String?,
      gradeName: json['grade_name'] as String?,
      educationLevelId: json['education_level_id'] as String?,
      countryCode: json['country_code'] as String? ?? '',
    );
  }
}

class ReviewQueueFilterOptions {
  const ReviewQueueFilterOptions({
    this.countries = const [],
    this.educationLevels = const [],
    this.grades = const [],
    this.subjects = const [],
  });

  final List<ReviewQueueCountryOption> countries;
  final List<ReviewQueueLevelOption> educationLevels;
  final List<ReviewQueueGradeOption> grades;
  final List<ReviewQueueSubjectOption> subjects;

  factory ReviewQueueFilterOptions.fromJson(Map<String, dynamic> json) {
    return ReviewQueueFilterOptions(
      countries: (json['countries'] as List<dynamic>? ?? const [])
          .map((e) => ReviewQueueCountryOption.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      educationLevels: (json['education_levels'] as List<dynamic>? ?? const [])
          .map((e) => ReviewQueueLevelOption.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      grades: (json['grades'] as List<dynamic>? ?? const [])
          .map((e) => ReviewQueueGradeOption.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      subjects: (json['subjects'] as List<dynamic>? ?? const [])
          .map((e) => ReviewQueueSubjectOption.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

class ReviewQueueSummary {
  const ReviewQueueSummary({
    required this.countryCode,
    required this.awaitingReviewCount,
    required this.revisionRequestedCount,
    required this.approvedCount,
    required this.publishedCount,
    required this.assignedToMeCount,
    required this.capabilities,
    required this.filterOptions,
  });

  final String countryCode;
  final int awaitingReviewCount;
  final int revisionRequestedCount;
  final int approvedCount;
  final int publishedCount;
  final int assignedToMeCount;
  final LessonAuthoringCapabilities capabilities;
  final ReviewQueueFilterOptions filterOptions;

  factory ReviewQueueSummary.fromJson(Map<String, dynamic> json) {
    return ReviewQueueSummary(
      countryCode: json['country_code'] as String? ?? 'ALL',
      awaitingReviewCount: (json['awaiting_review_count'] as num?)?.toInt() ?? 0,
      revisionRequestedCount:
          (json['revision_requested_count'] as num?)?.toInt() ?? 0,
      approvedCount: (json['approved_count'] as num?)?.toInt() ?? 0,
      publishedCount: (json['published_count'] as num?)?.toInt() ?? 0,
      assignedToMeCount: (json['assigned_to_me_count'] as num?)?.toInt() ?? 0,
      capabilities: LessonAuthoringCapabilities.fromJson(
        Map<String, dynamic>.from(
          json['capabilities'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      filterOptions: ReviewQueueFilterOptions.fromJson(
        Map<String, dynamic>.from(
          json['filter_options'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class ReviewQueueItem {
  const ReviewQueueItem({
    required this.lessonId,
    required this.title,
    required this.countryCode,
    required this.countryName,
    this.curriculumId,
    required this.curriculumName,
    this.curriculumVersionName,
    this.educationLevelId,
    required this.educationLevelName,
    this.gradeId,
    required this.gradeName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.mainCompetenceCode,
    this.mainCompetenceTitle,
    this.specificCompetenceCode,
    this.specificCompetenceTitle,
    this.authorId,
    required this.authorName,
    this.reviewerId,
    this.reviewerName,
    this.submittedAt,
    this.approvedAt,
    this.publishedAt,
    this.updatedAt,
    required this.status,
    required this.isPublished,
    required this.versionNumber,
    this.reviewNotes,
    required this.questionCount,
  });

  final String lessonId;
  final String title;
  final String countryCode;
  final String countryName;
  final String? curriculumId;
  final String curriculumName;
  final String? curriculumVersionName;
  final String? educationLevelId;
  final String educationLevelName;
  final String? gradeId;
  final String gradeName;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String? mainCompetenceCode;
  final String? mainCompetenceTitle;
  final String? specificCompetenceCode;
  final String? specificCompetenceTitle;
  final String? authorId;
  final String authorName;
  final String? reviewerId;
  final String? reviewerName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final String status;
  final bool isPublished;
  final int versionNumber;
  final String? reviewNotes;
  final int questionCount;

  String get formattedMainCompetence {
    if (mainCompetenceTitle == null || mainCompetenceTitle!.isEmpty) {
      return 'Unlinked';
    }
    if (mainCompetenceCode != null && mainCompetenceCode!.isNotEmpty) {
      return '$mainCompetenceCode $mainCompetenceTitle';
    }
    return mainCompetenceTitle!;
  }

  String get formattedSpecificCompetence {
    if (specificCompetenceTitle == null || specificCompetenceTitle!.isEmpty) {
      return 'Unlinked';
    }
    if (specificCompetenceCode != null && specificCompetenceCode!.isNotEmpty) {
      return '$specificCompetenceCode $specificCompetenceTitle';
    }
    return specificCompetenceTitle!;
  }

  AuthorLessonLaunchContext toLaunchContext() {
    return AuthorLessonLaunchContext(
      lessonId: lessonId,
      countryCode: countryCode,
      curriculumId: curriculumId,
      educationLevelId: educationLevelId,
      gradeId: gradeId,
      subjectId: subjectId,
      sourceEntry: 'academic_review_queue',
    );
  }

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return ReviewQueueItem(
      lessonId: json['lesson_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Lesson',
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String?,
      curriculumName: json['curriculum_name'] as String? ?? '',
      curriculumVersionName: json['curriculum_version_name'] as String?,
      educationLevelId: json['education_level_id'] as String?,
      educationLevelName: json['education_level_name'] as String? ?? '',
      gradeId: json['grade_id'] as String?,
      gradeName: json['grade_name'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      mainCompetenceCode: json['main_competence_code'] as String?,
      mainCompetenceTitle: json['main_competence_title'] as String?,
      specificCompetenceCode: json['specific_competence_code'] as String?,
      specificCompetenceTitle: json['specific_competence_title'] as String?,
      authorId: json['author_id'] as String?,
      authorName: json['author_name'] as String? ?? 'Unknown Author',
      reviewerId: json['reviewer_id'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      submittedAt: parseDt(json['submitted_at']),
      approvedAt: parseDt(json['approved_at']),
      publishedAt: parseDt(json['published_at']),
      updatedAt: parseDt(json['updated_at']),
      status: json['status'] as String? ?? 'in_review',
      isPublished: json['is_published'] as bool? ?? false,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      reviewNotes: json['review_notes'] as String?,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReviewQueuePage {
  const ReviewQueuePage({
    required this.totalCount,
    required this.limit,
    required this.offset,
    required this.hasMore,
    required this.items,
  });

  final int totalCount;
  final int limit;
  final int offset;
  final bool hasMore;
  final List<ReviewQueueItem> items;

  int get currentPage => (offset ~/ (limit > 0 ? limit : 1)) + 1;
  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ (limit > 0 ? limit : 1)) + 1;

  factory ReviewQueuePage.fromJson(Map<String, dynamic> json) {
    return ReviewQueuePage(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ReviewQueueItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

@immutable
class ReviewQueueQuery {
  const ReviewQueueQuery({
    this.countryCode,
    this.educationLevelId,
    this.gradeId,
    this.subjectId,
    this.status = 'all_reviewable',
    this.search,
    this.assignedReviewerId,
    this.onlyUnassigned = false,
    this.limit = 15,
    this.offset = 0,
  });

  final String? countryCode;
  final String? educationLevelId;
  final String? gradeId;
  final String? subjectId;
  final String status;
  final String? search;
  final String? assignedReviewerId;
  final bool onlyUnassigned;
  final int limit;
  final int offset;

  ReviewQueueQuery copyWith({
    String? countryCode,
    bool clearCountry = false,
    String? educationLevelId,
    bool clearEducationLevel = false,
    String? gradeId,
    bool clearGrade = false,
    String? subjectId,
    bool clearSubject = false,
    String? status,
    String? search,
    bool clearSearch = false,
    String? assignedReviewerId,
    bool clearAssignedReviewer = false,
    bool? onlyUnassigned,
    int? limit,
    int? offset,
  }) {
    return ReviewQueueQuery(
      countryCode: clearCountry ? null : (countryCode ?? this.countryCode),
      educationLevelId: clearEducationLevel
          ? null
          : (educationLevelId ?? this.educationLevelId),
      gradeId: clearGrade ? null : (gradeId ?? this.gradeId),
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      status: status ?? this.status,
      search: clearSearch ? null : (search ?? this.search),
      assignedReviewerId: clearAssignedReviewer
          ? null
          : (assignedReviewerId ?? this.assignedReviewerId),
      onlyUnassigned: onlyUnassigned ?? this.onlyUnassigned,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewQueueQuery &&
        other.countryCode == countryCode &&
        other.educationLevelId == educationLevelId &&
        other.gradeId == gradeId &&
        other.subjectId == subjectId &&
        other.status == status &&
        other.search == search &&
        other.assignedReviewerId == assignedReviewerId &&
        other.onlyUnassigned == onlyUnassigned &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
        countryCode,
        educationLevelId,
        gradeId,
        subjectId,
        status,
        search,
        assignedReviewerId,
        onlyUnassigned,
        limit,
        offset,
      );
}
