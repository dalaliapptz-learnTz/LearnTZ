import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';

class CurriculumExplorerTree extends ConsumerStatefulWidget {
  const CurriculumExplorerTree({
    super.key,
    required this.countries,
    required this.catalogSubjects,
    this.onSelectSubject,
    this.onSelectOverview,
  });

  final List<StudioCountryItem> countries;
  final List<StudioSubjectItem> catalogSubjects;
  final void Function(String subjectId, [int? tabIndex])? onSelectSubject;
  final VoidCallback? onSelectOverview;

  @override
  ConsumerState<CurriculumExplorerTree> createState() =>
      _CurriculumExplorerTreeState();
}

class _CurriculumExplorerTreeState extends ConsumerState<CurriculumExplorerTree> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';
  final Set<String> _expandedKeys = {'TZ', 'TZ_PRIMARY', 'TZ_STANDARD_3'};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  static const List<String> _structureTabs = [
    'Overview & Details',
    'Syllabus & Periods',
    'Competencies (TIE)',
    'Strands & Sub-strands',
    'Learning Outcomes',
    'Topics & Content',
    'Lessons & Markdown',
    'Learning Activities',
    'Assessments & Rubrics',
    'Learning Resources',
    'Curriculum Mapping Matrix',
    'Review & Approval',
    'Version History',
  ];

  static const List<IconData> _structureIcons = [
    Icons.dashboard_outlined,
    Icons.menu_book_outlined,
    Icons.verified_outlined,
    Icons.account_tree_outlined,
    Icons.flag_outlined,
    Icons.topic_outlined,
    Icons.auto_stories_outlined,
    Icons.psychology_outlined,
    Icons.quiz_outlined,
    Icons.folder_open_outlined,
    Icons.grid_view_outlined,
    Icons.rule_folder_outlined,
    Icons.history_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final selectedSubjectId = ref.watch(selectedSubjectIdProvider);
    final pinnedIds = ref.watch(pinnedSubjectIdsProvider);
    final recentIds = ref.watch(recentSubjectIdsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearnTzColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explorer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LearnTzColors.neutral200),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree,
                  color: LearnTzColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Curriculum Explorer',
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LearnTzColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Overview Dashboard',
                  icon: const Icon(Icons.home_outlined, size: 20),
                  onPressed: () {
                    ref.read(selectedSubjectIdProvider.notifier).select(null);
                    widget.onSelectOverview?.call();
                  },
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: LearnTzTypography.bodySmall,
              decoration: InputDecoration(
                hintText: 'Search hierarchy & codes...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: LearnTzColors.neutral50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: LearnTzColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: LearnTzColors.neutral200),
                ),
              ),
              onChanged: (val) {
                setState(() => _filter = val.trim().toLowerCase());
              },
            ),
          ),

          // Pinned & Recent Strip
          if (pinnedIds.isNotEmpty || recentIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...pinnedIds.take(2).map((id) {
                    final sub = widget.catalogSubjects
                        .where((s) => s.subjectId == id || s.subjectCode == id)
                        .firstOrNull;
                    return InkWell(
                      onTap: () {
                        ref.read(selectedSubjectIdProvider.notifier).select(id);
                        widget.onSelectSubject?.call(id, 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        constraints: const BoxConstraints(maxWidth: 130),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                sub?.subjectName ?? id,
                                style: LearnTzTypography.caption.copyWith(
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          const Divider(height: 12),

          // Tree List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                // "All Markets" Overview Item
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    ref.read(selectedSubjectIdProvider.notifier).select(null);
                    widget.onSelectOverview?.call();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedSubjectId == null
                          ? LearnTzColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 18,
                          color: selectedSubjectId == null
                              ? LearnTzColors.primary
                              : LearnTzColors.neutral600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'All Markets Overview',
                          style: LearnTzTypography.bodySmall.copyWith(
                            fontWeight: selectedSubjectId == null
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedSubjectId == null
                                ? LearnTzColors.primary
                                : LearnTzColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Country Nodes
                ..._buildCountryNodes(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCountryNodes(BuildContext context) {
    // If hierarchy RPC has data, use it; otherwise fallback to grouping catalog subjects
    final countries = widget.countries.isNotEmpty
        ? widget.countries
        : _synthesizeCountriesFromCatalog(widget.catalogSubjects);

    return countries.map((country) {
      final countryKey = country.countryCode;
      final isExpanded = _expandedKeys.contains(countryKey);
      final hasMatch = _filter.isEmpty ||
          country.countryName.toLowerCase().contains(_filter) ||
          country.countryCode.toLowerCase().contains(_filter);

      if (!hasMatch) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country Header Row
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              ref
                  .read(contentStudioCountryFilterProvider.notifier)
                  .setCountry(country.countryCode);
              _toggleExpand(countryKey);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isExpanded
                    ? LearnTzColors.neutral100.withValues(alpha: 0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: LearnTzColors.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${country.countryName} (${country.countryCode})',
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: LearnTzColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      country.authorityCode,
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Education Levels
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: country.educationLevels.map((level) {
                  return _buildLevelNode(country, level);
                }).toList(),
              ),
            ),
        ],
      );
    }).toList();
  }

  Widget _buildLevelNode(
      StudioCountryItem country, StudioEducationLevelItem level) {
    final levelKey = '${country.countryCode}_${level.levelCode}';
    final isExpanded = _expandedKeys.contains(levelKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _toggleExpand(levelKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: LearnTzColors.neutral500,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.layers_outlined,
                    size: 15, color: LearnTzColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    level.levelName,
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LearnTzColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grades
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: level.grades.map((grade) {
                return _buildGradeNode(country, level, grade);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildGradeNode(StudioCountryItem country,
      StudioEducationLevelItem level, StudioGradeItem grade) {
    final gradeKey =
        '${country.countryCode}_${level.levelCode}_${grade.gradeCode}';
    final isExpanded = _expandedKeys.contains(gradeKey);

    // Filter subjects for this grade
    final subjects = grade.subjects.isNotEmpty
        ? grade.subjects
        : widget.catalogSubjects.where((s) {
            if (s.countryCode != country.countryCode) return false;
            if (s.gradeId != null && s.gradeId == grade.gradeId) return true;
            if (s.gradeName != null &&
                s.gradeName!.toLowerCase() == grade.gradeName.toLowerCase()) {
              return true;
            }
            return false;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _toggleExpand(gradeKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 15,
                  color: LearnTzColors.neutral400,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.school_outlined,
                    size: 14, color: LearnTzColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    grade.gradeName,
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LearnTzColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${subjects.length}',
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.neutral500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Subjects
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subjects.map((subject) {
                return _buildSubjectNode(subject);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectNode(StudioSubjectItem subject) {
    final selectedSubjectId = ref.watch(selectedSubjectIdProvider);
    final activeTab = ref.watch(selectedSubjectTabProvider);
    final isSubjectSelected = selectedSubjectId == subject.subjectId ||
        selectedSubjectId == subject.subjectCode;
    final subjectKey = 'SUB_${subject.subjectId}';
    final isExpanded = _expandedKeys.contains(subjectKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            ref
                .read(selectedSubjectIdProvider.notifier)
                .select(subject.subjectId);
            ref.read(recentSubjectIdsProvider.notifier).add(subject.subjectId);
            _toggleExpand(subjectKey);
            widget.onSelectSubject?.call(subject.subjectId, 0);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: isSubjectSelected
                  ? LearnTzColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSubjectSelected
                  ? Border.all(
                      color: LearnTzColors.primary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 14,
                  color: LearnTzColors.neutral500,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: isSubjectSelected
                      ? LearnTzColors.primary
                      : LearnTzColors.neutral600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subject.subjectName,
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: isSubjectSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSubjectSelected
                          ? LearnTzColors.primary
                          : LearnTzColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sub-nodes: 13 Structure Tabs
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_structureTabs.length, (tabIdx) {
                final isTabActive = isSubjectSelected && activeTab == tabIdx;
                return InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    ref
                        .read(selectedSubjectIdProvider.notifier)
                        .select(subject.subjectId);
                    ref
                        .read(selectedSubjectTabProvider.notifier)
                        .selectTab(tabIdx);
                    widget.onSelectSubject?.call(subject.subjectId, tabIdx);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: isTabActive
                          ? const Color(0xFFEFF6FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _structureIcons[tabIdx],
                          size: 12,
                          color: isTabActive
                              ? LearnTzColors.primary
                              : LearnTzColors.neutral400,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _structureTabs[tabIdx],
                            style: LearnTzTypography.caption.copyWith(
                              fontWeight: isTabActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isTabActive
                                  ? LearnTzColors.primary
                                  : LearnTzColors.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  List<StudioCountryItem> _synthesizeCountriesFromCatalog(
      List<StudioSubjectItem> catalog) {
    // Group subjects by country
    final map = <String, List<StudioSubjectItem>>{};
    for (final s in catalog) {
      map.putIfAbsent(s.countryCode, () => []).add(s);
    }

    final countries = <StudioCountryItem>[];
    const countryNames = {
      'TZ': 'Tanzania',
      'KE': 'Kenya',
      'UG': 'Uganda',
      'RW': 'Rwanda',
      'BI': 'Burundi',
      'SS': 'South Sudan',
    };
    const authorities = {
      'TZ': 'TIE',
      'KE': 'KICD',
      'UG': 'NCDC',
      'RW': 'REB',
      'BI': 'BEPES',
      'SS': 'MOGEI',
    };

    for (final code in ['TZ', 'KE', 'UG', 'RW', 'BI', 'SS']) {
      final subs = map[code] ?? [];
      // Group by grades
      final gradesMap = <String, List<StudioSubjectItem>>{};
      for (final s in subs) {
        final gName = s.gradeName ?? 'Primary Standards';
        gradesMap.putIfAbsent(gName, () => []).add(s);
      }

      final gradeItems = gradesMap.entries.map((e) {
        return StudioGradeItem(
          gradeId: e.key,
          gradeName: e.key,
          gradeCode: e.key,
          subjects: e.value,
        );
      }).toList();

      countries.add(StudioCountryItem(
        countryCode: code,
        countryName: countryNames[code] ?? code,
        productName: 'Learn$code',
        currencyCode: code == 'TZ' ? 'TZS' : 'USD',
        authorityName: '${authorities[code]} National Authority',
        authorityCode: authorities[code] ?? code,
        educationLevels: [
          StudioEducationLevelItem(
            levelId: 'LEVEL_PRI',
            levelName: 'Primary Education',
            levelCode: 'PRIMARY',
            grades: gradeItems,
          ),
        ],
      ));
    }
    return countries;
  }
}
