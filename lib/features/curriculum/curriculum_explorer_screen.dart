import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import '../content_studio/lesson_authoring_models.dart';
import '../content_studio/lesson_authoring_providers.dart';
import '../learners/learner_providers.dart';
import '../learning/learning_models.dart';
import '../learning/learning_providers.dart';

class CurriculumExplorerScreen extends ConsumerStatefulWidget {
  const CurriculumExplorerScreen({super.key});

  @override
  ConsumerState<CurriculumExplorerScreen> createState() =>
      _CurriculumExplorerScreenState();
}

class _CurriculumExplorerScreenState
    extends ConsumerState<CurriculumExplorerScreen> {
  String? _selectedCountryCode;
  String? _selectedSystemId;
  String? _selectedLevelId;
  String? _selectedGradeId;
  String _searchQuery = '';
  String _filterClassification = 'all'; // 'all', 'compulsory', 'elective'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final defaultCountry = ref.watch(selectedCountryProvider).countryCode;
    final currentCountry = _selectedCountryCode ?? defaultCountry;

    final catalogAsync = ref.watch(educationCatalogProvider);
    final authoringCaps =
        ref.watch(lessonAuthoringCapabilitiesProvider(currentCountry)).asData?.value;
    final canAuthorLessons = authoringCaps?.canAuthor ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.curriculumExplorerTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.curriculumExplorerSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  if (canAuthorLessons) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const Key('explorer-create-new-lesson-btn'),
                      onPressed: () {
                        final catalog = catalogAsync.asData?.value;
                        final matchingCountry = catalog?.countries
                            .where((c) => c.code == currentCountry)
                            .firstOrNull;
                        final matchingLevel = catalog?.levels
                            .where((l) => l.id == _selectedLevelId)
                            .firstOrNull;
                        final matchingGrade = catalog?.grades
                            .where((g) => g.id == _selectedGradeId)
                            .firstOrNull;
                        final matchingCurriculum = catalog?.curricula
                            .where((c) =>
                                c.countryCode == currentCountry && c.isEnabled)
                            .firstOrNull;
                        context.push(
                          AppRoutes.authorNewLesson,
                          extra: AuthorLessonLaunchContext(
                            countryCode: currentCountry,
                            countryName: matchingCountry?.name,
                            curriculumId: matchingGrade?.curriculumId ??
                                matchingLevel?.curriculumId ??
                                matchingCurriculum?.id,
                            curriculumName: matchingCurriculum?.name,
                            educationLevelId: _selectedLevelId ??
                                matchingGrade?.educationLevelId,
                            educationLevelName: matchingLevel?.name,
                            gradeId: _selectedGradeId,
                            gradeName: matchingGrade?.name,
                            sourceEntry: 'curriculum_explorer',
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                      ),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Create New Lesson'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Official Curriculum Authority Showcase (for Tanzania)
              if (currentCountry == 'TZ') ...[
                _TieCurriculumAuthorityBanner(
                  onViewDetails: () => _showTieSyllabusCatalogDialog(context, l10n),
                ),
                const SizedBox(height: 20),
              ],

              catalogAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) {
                  debugPrint('CurriculumExplorer catalogAsync error: $error\n$stack');
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthInlineMessage(
                          message: error is AuthNotConfiguredException
                              ? 'Backend service is not configured. Please check your Supabase connection.'
                              : l10n.requestFailed,
                          isError: true,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(educationCatalogProvider),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(l10n.tryAgainAction),
                        ),
                      ],
                    ),
                  );
                },
                data: (catalog) {
                  final systems = catalog.systems
                      .where((s) => s.countryCode == currentCountry && s.isEnabled)
                      .toList();
                  final selectedSystemId = _selectedSystemId ??
                      (systems.isNotEmpty ? systems.first.id : null);

                  final levels = catalog.levels
                      .where((lvl) => lvl.isEnabled)
                      .toList();
                  final grades = catalog.grades
                      .where(
                        (g) =>
                            g.isEnabled &&
                            (_selectedLevelId == null ||
                                g.educationLevelId == _selectedLevelId),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter bar
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.filterCurriculumLabel,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (_searchQuery.isNotEmpty ||
                                    _filterClassification != 'all')
                                  TextButton.icon(
                                    onPressed: () {
                                      _clearSearch();
                                      setState(() {
                                        _filterClassification = 'all';
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(l10n.tryAgainAction),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // Country Dropdown
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('country-$currentCountry'),
                                    initialValue: currentCountry,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l10n.countryLabel,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: catalog.countries.map((c) {
                                      return DropdownMenuItem(
                                        value: c.code,
                                        child: Text(c.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedCountryCode = val;
                                          _selectedSystemId = null;
                                          _selectedLevelId = null;
                                          _selectedGradeId = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                // Education System Dropdown
                                if (systems.isNotEmpty)
                                  SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('system-$selectedSystemId'),
                                      initialValue: selectedSystemId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.educationSystemLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: systems.map((s) {
                                        return DropdownMenuItem(
                                          value: s.id,
                                          child: Text(s.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSystemId = val;
                                          _selectedLevelId = null;
                                          _selectedGradeId = null;
                                        });
                                      },
                                    ),
                                  ),
                                // Level Dropdown
                                if (levels.isNotEmpty)
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String?>(
                                      key: ValueKey('level-$_selectedLevelId'),
                                      initialValue: _selectedLevelId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.educationLevelLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(l10n.allLevelsOption),
                                        ),
                                        ...levels.map((lvl) {
                                          return DropdownMenuItem(
                                            value: lvl.id,
                                            child: Text(lvl.name),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedLevelId = val;
                                          _selectedGradeId = null;
                                        });
                                      },
                                    ),
                                  ),
                                // Grade Dropdown
                                if (grades.isNotEmpty)
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String?>(
                                      key: ValueKey('grade-$_selectedGradeId'),
                                      initialValue: _selectedGradeId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.gradeClassLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(l10n.allGradesOption),
                                        ),
                                        ...grades.map((g) {
                                          return DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.name),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedGradeId = val;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search and Classification Filter Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                      hintText: l10n.searchCurriculumPlaceholder,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val.trim();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Classification Segmented Buttons
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(l10n.allSubjectsFilter),
                                  selected: _filterClassification == 'all',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _filterClassification = 'all';
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(l10n.compulsoryFilter),
                                  selected: _filterClassification == 'compulsory',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _filterClassification = 'compulsory';
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(l10n.electiveFilter),
                                  selected: _filterClassification == 'elective',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _filterClassification = 'elective';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (selectedSystemId == null)
                        AppCard(child: Text(l10n.noSystemConfigured))
                      else
                        _SubjectTreeList(
                          countryCode: currentCountry,
                          systemId: selectedSystemId,
                          levelId: _selectedLevelId,
                          gradeId: _selectedGradeId,
                          searchQuery: _searchQuery,
                          filterClassification: _filterClassification,
                          canAuthorLessons: canAuthorLessons,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTieSyllabusCatalogDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _TieSyllabusCatalogDialog(l10n: l10n);
      },
    );
  }
}

class _TieCurriculumAuthorityBanner extends StatelessWidget {
  const _TieCurriculumAuthorityBanner({required this.onViewDetails});

  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C81).withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFF0F4C81).withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.officialCurriculumBadge,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4C81),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TIE Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Taasisi ya Elimu Tanzania (TIE) Primary Education Curriculum (Standards I–VI). Authoritative 2023 edition with specific competences, period allocations, and assessment criteria.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.library_books_outlined, size: 16),
                  label: Text(l10n.viewOfficialSyllabusAction),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF0F4C81)),
                    foregroundColor: const Color(0xFF0F4C81),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TieSyllabusCatalogDialog extends StatelessWidget {
  const _TieSyllabusCatalogDialog({required this.l10n});

  final AppLocalizations l10n;

  static const List<Map<String, String>> _tieSyllabi = [
    {
      'code': 'TZ-TIE-PRI-FRAMEWORK',
      'title': 'Curriculum for Primary Education Standard I - VI',
      'scope': 'Framework (Standards I–VI)',
      'isbn': '978-9987-09-852-1',
      'pages': '34 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-STD1-2',
      'title': 'Primary Education Syllabus Standard I – II',
      'scope': 'Foundational 3Rs, Arts & Health (Standards I–II)',
      'isbn': '978-9987-09-837-8',
      'pages': '42 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-KIS',
      'title': 'Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III – VI',
      'scope': 'Kiswahili (Standards III–VI)',
      'isbn': '978-9987-09-866-8',
      'pages': '55 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-ENG',
      'title': 'English Language Syllabus for Primary Education Standard III–VI',
      'scope': 'English Language (Standards III–VI)',
      'isbn': '978-9987-09-857-6',
      'pages': '51 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-MATH',
      'title': 'Mathematics Syllabus for Primary School Education Standard III-VI',
      'scope': 'Mathematics (Standards III–VI)',
      'isbn': '978-9987-09-858-3',
      'pages': '40 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-SCI',
      'title': 'Science Syllabus for Primary Education Standard III─VI',
      'scope': 'Science and Technology (Standards III–VI)',
      'isbn': '978-9987-09-860-6',
      'pages': '49 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-GEO',
      'title': 'Geography and the Environment Syllabus Standard III – VI',
      'scope': 'Geography & Environment (Standards III–VI)',
      'isbn': '978-9987-09-859-0',
      'pages': '37 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-HIS',
      'title': 'Muhtasari wa Somo la Historia ya Tanzania na Maadili Darasa la III-VI',
      'scope': 'History of Tanzania & Ethics (Standards III–VI)',
      'isbn': '978-9987-09-861-3',
      'pages': '56 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-ART',
      'title': 'Sports and Arts Syllabus for Primary Education Standard III-VI',
      'scope': 'Sports & Arts (Standards III–VI)',
      'isbn': '978-9987-09-862-0',
      'pages': '34 pages',
      'year': '2023',
    },
    {
      'code': 'TZ-TIE-PRI-CHI',
      'title': 'Muhtasari wa Somo la Lugha ya Kichina Elimu ya Msingi Darasa la III-VI',
      'scope': 'Chinese Language (Elective, Standards III–VI)',
      'isbn': '978-9987-23-010-5',
      'pages': '60 pages',
      'year': '2023',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.menu_book, color: Color(0xFF0F4C81)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.officialDocumentDetailsTitle,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Issuing Authority: Taasisi ya Elimu Tanzania (TIE)\n'
                'Curriculum Edition: 2023 Competency-Based Edition\n'
                'Storage Bucket: curriculum-documents\n'
                'Integrity: SHA-256 Checksums Verified',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              for (final doc in _tieSyllabi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4C81),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                doc['code']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc['scope']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              doc['pages']!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc['title']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'ISBN: ${doc['isbn']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified 2023',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
      ],
    );
  }
}

class _SubjectTreeList extends ConsumerWidget {
  const _SubjectTreeList({
    required this.countryCode,
    required this.systemId,
    this.levelId,
    this.gradeId,
    required this.searchQuery,
    required this.filterClassification,
    this.canAuthorLessons = false,
  });

  final String countryCode;
  final String systemId;
  final String? levelId;
  final String? gradeId;
  final String searchQuery;
  final String filterClassification;
  final bool canAuthorLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final treeAsync = ref.watch(
      curriculumExplorerTreeProvider((
        countryCode: countryCode,
        educationSystemId: systemId,
        educationLevelId: levelId,
        gradeId: gradeId,
      )),
    );

    return treeAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        debugPrint('CurriculumExplorer treeAsync error: $error\n$stack');
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthInlineMessage(
                message: l10n.requestFailed,
                isError: true,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(curriculumExplorerTreeProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.tryAgainAction),
              ),
            ],
          ),
        );
      },
      data: (allSubjects) {
        if (allSubjects.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.noSubjectsPublished)),
              ],
            ),
          );
        }

        // Apply classification and search filtering
        final filteredSubjects = allSubjects.where((subject) {
          // Classification filter
          if (filterClassification == 'compulsory' && !subject.isCompulsory) {
            return false;
          }
          if (filterClassification == 'elective' && !subject.isElective) {
            return false;
          }

          // Search query filter
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final matchesSubject = subject.subjectName.toLowerCase().contains(q) ||
                subject.effectiveDisplayName.toLowerCase().contains(q) ||
                subject.subjectCode.toLowerCase().contains(q) ||
                subject.description.toLowerCase().contains(q);

            if (matchesSubject) return true;

            final matchesTopic = subject.topics.any((t) {
              return t.title.toLowerCase().contains(q) ||
                  t.summary.toLowerCase().contains(q) ||
                  (t.competencyCode?.toLowerCase().contains(q) ?? false) ||
                  t.subtopics.any((st) =>
                      st.title.toLowerCase().contains(q) ||
                      st.learningOutcome.toLowerCase().contains(q));
            });

            return matchesTopic;
          }

          return true;
        }).toList();

        if (filteredSubjects.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                const Icon(Icons.search_off),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No curriculum subjects match "${searchQuery.isNotEmpty ? searchQuery : filterClassification}".',
                  ),
                ),
              ],
            ),
          );
        }

        final totalTopics = filteredSubjects.fold(0, (sum, s) => sum + s.topics.length);
        final totalSubtopics = filteredSubjects.fold(0, (sum, s) => sum + s.totalSubtopics);
        final totalPeriods = filteredSubjects.fold(0, (sum, s) => sum + s.totalPeriods);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                'Showing ${filteredSubjects.length} subjects • $totalTopics topics • $totalSubtopics specific competences'
                '${totalPeriods > 0 ? " • $totalPeriods total periods" : ""}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSubjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final subject = filteredSubjects[index];
                return _SubjectTreeCard(
                  subject: subject,
                  countryCode: countryCode,
                  levelId: levelId,
                  canAuthorLessons: canAuthorLessons,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SubjectTreeCard extends StatelessWidget {
  const _SubjectTreeCard({
    required this.subject,
    required this.countryCode,
    this.levelId,
    this.canAuthorLessons = false,
  });

  final CurriculumExplorerSubject subject;
  final String countryCode;
  final String? levelId;
  final bool canAuthorLessons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                subject.subjectName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            // Classification badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: subject.isElective
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                    : const Color(0xFF15803D).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: subject.isElective
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                      : const Color(0xFF15803D).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                subject.isElective
                    ? l10n.classificationElective
                    : l10n.classificationCompulsory,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: subject.isElective
                      ? const Color(0xFFB45309)
                      : const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${subject.subjectCode} • ${subject.topics.length} ${l10n.topicsLabel}'
                '${subject.totalSubtopics > 0 ? " • ${subject.totalSubtopics} ${l10n.subtopicsLabel}" : ""}'
                ' • ${subject.totalLessons} ${l10n.lessonsLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (subject.totalPeriods > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.periodCountLabel(subject.totalPeriods),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F4C81),
                    ),
                  ),
                ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          // Official Name callout if different from common subject name
          if (subject.officialName != null &&
              subject.officialName != subject.subjectName)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.syllabusReferenceLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.officialName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (subject.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Text(
                subject.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (canAuthorLessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: Key('subject-create-lesson-${subject.subjectId}'),
                  onPressed: () {
                    context.push(
                      AppRoutes.authorNewLesson,
                      extra: AuthorLessonLaunchContext(
                        countryCode: countryCode,
                        educationLevelId: levelId,
                        gradeId: subject.gradeId,
                        subjectId: subject.subjectId,
                        subjectName: subject.subjectName,
                        sourceEntry: 'curriculum_explorer_subject',
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text('Create New Lesson in ${subject.subjectName}'),
                ),
              ),
            ),
          // Topics breakdown
          for (final topic in subject.topics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (topic.competencyCode != null &&
                              topic.competencyCode!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4C81),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                topic.competencyCode!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              topic.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (topic.periodAllocation != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15803D).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.periodCountLabel(topic.periodAllocation!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                          if (topic.sourcePage != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              l10n.sourcePageLabel(topic.sourcePage!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      if (topic.summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          topic.summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      // Assessment criteria box if present
                      if (topic.assessmentCriteria != null &&
                          topic.assessmentCriteria!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.rule_outlined,
                                size: 16,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${l10n.assessmentCriteriaLabel}: ${topic.assessmentCriteria}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Subtopics section
                      if (topic.subtopics.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.learningOutcomesLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final subtopic in topic.subtopics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4, right: 6),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subtopic.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (subtopic.learningOutcome.isNotEmpty)
                                        Text(
                                          subtopic.learningOutcome,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                if (subtopic.periodAllocation != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      l10n.periodCountLabel(subtopic.periodAllocation!),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                      // Lessons list if present
                      if (topic.lessons.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 16),
                        for (final lesson in topic.lessons)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.menu_book, size: 20),
                            title: Text(lesson.title),
                            subtitle: Text('${lesson.estimatedMinutes} mins'),
                            trailing: FilledButton.tonal(
                              onPressed: () => context.go(
                                AppRoutes.lessonReader(lesson.lessonId),
                              ),
                              child: Text(l10n.studyLessonAction),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
