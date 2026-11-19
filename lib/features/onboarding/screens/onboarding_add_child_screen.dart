import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../learners/learner_models.dart';
import '../../learners/learner_providers.dart';
import '../models/child_draft.dart';
import '../providers/onboarding_providers.dart';

class OnboardingAddChildScreen extends ConsumerStatefulWidget {
  const OnboardingAddChildScreen({super.key, this.editingChildId});

  final String? editingChildId;

  @override
  ConsumerState<OnboardingAddChildScreen> createState() =>
      _OnboardingAddChildScreenState();
}

class _OnboardingAddChildScreenState
    extends ConsumerState<OnboardingAddChildScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolLocationController = TextEditingController();
  final _pinController = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'prefer_not_to_say';
  String _selectedAvatar = 'owl_scholar';
  String _accessMode = 'parent_managed';
  bool _obscurePin = true;

  String? _selectedSystemId;
  String? _selectedCurriculumId;
  String? _selectedLevelId;
  String? _selectedGradeId;
  String? _selectedSchoolId;

  String? _dateError;
  String? _formError;

  static const List<({String key, String label, IconData icon, Color color})>
      _avatarPresets = [
    (
      key: 'owl_scholar',
      label: 'Wise Owl',
      icon: Icons.psychology_outlined,
      color: Color(0xFF0F4C81),
    ),
    (
      key: 'lion_reader',
      label: 'Brave Lion',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFD97706),
    ),
    (
      key: 'cheetah_runner',
      label: 'Cheetah Runner',
      icon: Icons.speed_rounded,
      color: Color(0xFFEA580C),
    ),
    (
      key: 'giraffe_thinker',
      label: 'Tall Thinker',
      icon: Icons.lightbulb_outline,
      color: Color(0xFFCA8A04),
    ),
    (
      key: 'elephant_math',
      label: 'Math Champion',
      icon: Icons.calculate_outlined,
      color: Color(0xFF2563EB),
    ),
    (
      key: 'zebra_writer',
      label: 'Creative Writer',
      icon: Icons.create_outlined,
      color: Color(0xFF059669),
    ),
    (
      key: 'falcon_scout',
      label: 'Explorer Falcon',
      icon: Icons.explore_outlined,
      color: Color(0xFF7C3AED),
    ),
    (
      key: 'rhino_builder',
      label: 'Strong Builder',
      icon: Icons.architecture_rounded,
      color: Color(0xFF4B5563),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final session = ref.read(onboardingSessionProvider);
    if (widget.editingChildId != null) {
      final child = session.children
          .where((c) => c.id == widget.editingChildId)
          .firstOrNull;
      if (child != null) {
        _firstNameController.text = child.firstName;
        _middleNameController.text = child.middleName ?? '';
        _lastNameController.text = child.lastName;
        _dateOfBirth = child.dateOfBirth;
        _gender = child.gender ?? 'prefer_not_to_say';
        _selectedAvatar = child.avatarPreset;
        _selectedSystemId = child.educationSystemId;
        _selectedCurriculumId = child.curriculumId;
        _selectedLevelId = child.educationLevelId;
        _selectedGradeId = child.gradeId;
        _selectedSchoolId = child.schoolId;
        _schoolNameController.text = child.schoolName ?? '';
        _schoolLocationController.text = child.schoolLocation ?? '';
        _accessMode = child.accessMode;
        _pinController.text = child.pin ?? '';
        return;
      }
    }

    // Pre-populate last name with parent's last name if available
    if (session.parentFullName != null &&
        session.parentFullName!.trim().isNotEmpty) {
      final parts = session.parentFullName!.trim().split(' ');
      if (parts.length > 1) {
        _lastNameController.text = parts.last;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _schoolNameController.dispose();
    _schoolLocationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dateOfBirth ?? DateTime(now.year - 9, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 23, 1, 1),
      lastDate: DateTime(now.year - 3, now.month, now.day),
      helpText: "Select Child's Date of Birth",
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateError = null;
      });
    }
  }

  bool _validateInput(EducationCatalog catalog) {
    bool valid = _formKey.currentState!.validate();
    if (_dateOfBirth == null) {
      setState(() => _dateError = 'Please select your child’s date of birth');
      valid = false;
    } else {
      final age = DateTime.now().year - _dateOfBirth!.year;
      if (age < 3 || age > 23) {
        setState(() => _dateError = 'Age must be between 3 and 22 years');
        valid = false;
      }
    }

    if (_selectedSystemId == null ||
        _selectedCurriculumId == null ||
        _selectedLevelId == null ||
        _selectedGradeId == null) {
      setState(() => _formError =
          'Please select education level and class / grade');
      valid = false;
    } else {
      setState(() => _formError = null);
    }

    return valid;
  }

  ChildDraft _createDraft(EducationCatalog catalog) {
    final session = ref.read(onboardingSessionProvider);
    final system = catalog.system(_selectedSystemId);
    final curriculum = catalog.curriculum(_selectedCurriculumId);
    final level = catalog.level(_selectedLevelId);
    final grade = catalog.grade(_selectedGradeId);

    return ChildDraft(
      id: widget.editingChildId ?? ChildDraft.generateId(),
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gender: _gender,
      countryCode: session.countryCode,
      educationSystemId: _selectedSystemId!,
      systemName: system?.name ?? 'National System',
      curriculumId: _selectedCurriculumId!,
      curriculumName: curriculum?.name ?? 'Standard Curriculum',
      educationLevelId: _selectedLevelId!,
      levelName: level?.name ?? '',
      gradeId: _selectedGradeId!,
      gradeName: grade?.name ?? '',
      schoolId: _selectedSchoolId,
      schoolName: _schoolNameController.text.trim().isNotEmpty
          ? _schoolNameController.text.trim()
          : null,
      schoolLocation: _schoolLocationController.text.trim().isNotEmpty
          ? _schoolLocationController.text.trim()
          : null,
      avatarPreset: _selectedAvatar,
      accessMode: _accessMode,
      pin: _accessMode == 'independent_device' && _pinController.text.trim().isNotEmpty
          ? _pinController.text.trim()
          : null,
    );
  }

  void _handleAddAnotherChild(EducationCatalog catalog) {
    if (!_validateInput(catalog)) return;
    final draft = _createDraft(catalog);
    ref.read(onboardingSessionProvider.notifier).addChildDraft(draft);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${draft.firstName} to profile! Add next child:'),
        backgroundColor: LearnTzColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    // Reset form for next child
    setState(() {
      _firstNameController.clear();
      _middleNameController.clear();
      _schoolNameController.clear();
      _schoolLocationController.clear();
      _pinController.clear();
      _dateOfBirth = null;
      _selectedLevelId = null;
      _selectedGradeId = null;
      _selectedAvatar = 'lion_reader';
      _accessMode = 'parent_managed';
    });
  }

  void _handleReviewAndConfirm(EducationCatalog catalog) {
    if (!_validateInput(catalog)) return;
    final draft = _createDraft(catalog);
    ref.read(onboardingSessionProvider.notifier).addChildDraft(draft);
    context.go(AppRoutes.onboardingConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(onboardingSessionProvider);
    final catalogAsync = ref.watch(educationCatalogProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              _buildProgressHeader(currentStep: 4, totalSteps: 5),
              const SizedBox(height: 24),

              // Headline
              Text(
                "LET'S ADD YOUR FIRST CHILD",
                style: LearnTzTypography.h1.copyWith(
                  color: LearnTzColors.textPrimary,
                  fontSize: isWide ? 30 : 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Register your learner to personalise lessons, quizzes, and revision aligned with ${session.countryName} standards.',
                style: LearnTzTypography.bodyLarge.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Existing Staged Children Indicator
              if (session.children.isNotEmpty) ...[
                _buildStagedChildrenBanner(session.children),
                const SizedBox(height: 24),
              ],

              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LearnTzColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: LearnTzColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: LearnTzColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: LearnTzColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Education Catalog Loading / Form
              catalogAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildFormWithFallback(context, session),
                data: (catalog) => _buildChildForm(context, session, catalog),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStagedChildrenBanner(List<ChildDraft> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LearnTzColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearnTzColors.primary200),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded,
              color: LearnTzColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${children.length} ${children.length == 1 ? "child" : "children"} staged: ${children.map((c) => c.firstName).join(", ")}',
              style: LearnTzTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: LearnTzColors.primary800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.onboardingConfirm),
            child: const Text('Review List'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildForm(
    BuildContext context,
    onboardingSession,
    EducationCatalog catalog,
  ) {
    // Systems for selected country
    final systems = catalog.systemsForCountry(onboardingSession.countryCode);
    if (_selectedSystemId == null && systems.isNotEmpty) {
      _selectedSystemId = systems.first.id;
    }

    // Curricula for system
    final curricula = catalog.curriculaForSystem(_selectedSystemId);
    if (_selectedCurriculumId == null && curricula.isNotEmpty) {
      _selectedCurriculumId = curricula.first.id;
    }

    // Levels for curriculum
    final levels = catalog.levelsForCurriculum(_selectedCurriculumId);
    if (_selectedLevelId == null && levels.isNotEmpty) {
      _selectedLevelId = levels.first.id;
    }

    // Grades for level
    final grades = catalog.gradesForLevel(_selectedLevelId);
    if (_selectedGradeId == null && grades.isNotEmpty) {
      _selectedGradeId = grades.first.id;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Identity & Name
          _buildSectionTitle('1. Child Identity & Basic Details'),
          const SizedBox(height: 14),

          // Name row (First + Middle + Last)
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    hintText: 'e.g. Juma',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'First name is required'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _middleNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Middle (Opt)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    hintText: 'e.g. Mwangi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Last name is required'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date of Birth & Gender Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth *',
                          prefixIcon:
                              const Icon(Icons.calendar_today_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _dateError,
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${DateFormat("dd MMM yyyy").format(_dateOfBirth!)} (${DateTime.now().year - _dateOfBirth!.year} yrs)'
                              : 'Select date of birth',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _dateOfBirth != null
                                ? LearnTzColors.textPrimary
                                : LearnTzColors.textSecondary,
                            fontWeight: _dateOfBirth != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'female',
                      child: Text('Female'),
                    ),
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Avatar Selection
          _buildSectionTitle('2. Choose Learning Avatar'),
          const SizedBox(height: 6),
          Text(
            'Child-friendly profile icon (protects personal photos):',
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildAvatarSelector(),
          const SizedBox(height: 28),

          // Section 3: Dynamic Education Structure
          _buildSectionTitle('3. Education System & Class Level'),
          const SizedBox(height: 6),
          Text(
            'Automatically tailored to ${onboardingSession.countryName} curricula:',
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Education Level Dropdown (Pre-Primary, Primary, Ordinary Secondary, Advanced)
          DropdownButtonFormField<String>(
            key: ValueKey('level-$_selectedLevelId'),
            isExpanded: true,
            initialValue: _selectedLevelId,
            decoration: InputDecoration(
              labelText: 'Education Level *',
              prefixIcon: const Icon(Icons.school_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final lvl in levels)
                DropdownMenuItem(
                  value: lvl.id,
                  child: Text(lvl.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedLevelId = val;
                final newGrades = catalog.gradesForLevel(val);
                _selectedGradeId =
                    newGrades.isNotEmpty ? newGrades.first.id : null;
              });
            },
            validator: (val) =>
                val == null ? 'Education level is required' : null,
          ),
          const SizedBox(height: 16),

          // Class / Grade / Form Dropdown
          DropdownButtonFormField<String>(
            key: ValueKey('grade-$_selectedGradeId'),
            isExpanded: true,
            initialValue: _selectedGradeId,
            decoration: InputDecoration(
              labelText: 'Current Grade / Class / Form *',
              prefixIcon: const Icon(Icons.class_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final grd in grades)
                DropdownMenuItem(
                  value: grd.id,
                  child: Text(grd.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (val) => setState(() => _selectedGradeId = val),
            validator: (val) =>
                val == null ? 'Class / grade selection is required' : null,
          ),
          const SizedBox(height: 16),

          // School Information
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _schoolNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'School Name (Optional)',
                    hintText: 'e.g. Olympic Primary School',
                    prefixIcon:
                        const Icon(Icons.account_balance_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _schoolLocationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'City / Region (Opt)',
                    hintText: 'e.g. Dar es Salaam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section 4: Device Access Arrangement
          _buildSectionTitle('4. How will your child access LearnTZ?'),
          const SizedBox(height: 6),
          Text(
            'Choose the device arrangement (you can change this at any time from your Parent Dashboard):',
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildAccessModeSelector(),
          const SizedBox(height: 32),

          // Action Buttons: + Add Another Child | Review & Confirm
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleAddAnotherChild(catalog),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('+ Add Another Child'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleReviewAndConfirm(catalog),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text('Review & Confirm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LearnTzColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: LearnTzTypography.h4.copyWith(
        color: LearnTzColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final preset in _avatarPresets) ...[
          InkWell(
            onTap: () => setState(() => _selectedAvatar = preset.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedAvatar == preset.key
                    ? LearnTzColors.primary50
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedAvatar == preset.key
                      ? LearnTzColors.primary
                      : LearnTzColors.border,
                  width: _selectedAvatar == preset.key ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    preset.icon,
                    size: 18,
                    color: _selectedAvatar == preset.key
                        ? LearnTzColors.primary
                        : preset.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    preset.label,
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: _selectedAvatar == preset.key
                          ? LearnTzColors.primary800
                          : LearnTzColors.textPrimary,
                      fontWeight: _selectedAvatar == preset.key
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccessModeSelector() {
    final modes = [
      (
        code: 'parent_managed',
        title: "Use parent's device",
        subtitle: 'Child uses your phone or tablet in supervised child mode.',
        icon: Icons.phone_android_rounded,
      ),
      (
        code: 'independent_device',
        title: "Set up child's own device",
        subtitle: 'Child signs in independently with their own Learner ID and PIN.',
        icon: Icons.tablet_mac_rounded,
      ),
      (
        code: 'setup_later',
        title: 'Set up later',
        subtitle: 'Configure device access anytime from your Parent Dashboard.',
        icon: Icons.schedule_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in modes) ...[
          InkWell(
            onTap: () => setState(() => _accessMode = m.code),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accessMode == m.code
                    ? LearnTzColors.primary50
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accessMode == m.code
                      ? LearnTzColors.primary
                      : LearnTzColors.neutral200,
                  width: _accessMode == m.code ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    m.icon,
                    color: _accessMode == m.code
                        ? LearnTzColors.primary
                        : LearnTzColors.neutral500,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: LearnTzTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _accessMode == m.code
                                ? LearnTzColors.primary900
                                : LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.subtitle,
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _accessMode == m.code
                            ? LearnTzColors.primary
                            : LearnTzColors.neutral400,
                        width: 2,
                      ),
                    ),
                    child: _accessMode == m.code
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: LearnTzColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_accessMode == 'independent_device') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LearnTzColors.secondary50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LearnTzColors.secondary200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pin_outlined,
                        color: LearnTzColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Create 4 to 6-Digit Learner PIN',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.secondary900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your child will use this PIN together with their unique Learner ID to sign in. (Never use birth date or birth year).',
                  style: LearnTzTypography.caption
                      .copyWith(color: LearnTzColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Child PIN (4-6 Digits)',
                    counterText: '',
                    prefixIcon:
                        const Icon(Icons.lock_clock_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePin = !_obscurePin),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormWithFallback(
    BuildContext context,
    onboardingSession,
  ) {
    // Generate fallback catalog with Tanzania curriculum structure
    final fallbackCatalog = EducationCatalog(
      countries: [
        const EducationCountry(code: 'TZ', name: 'Tanzania'),
      ],
      systems: [
        const EducationSystem(
          id: 'sys-tz-1',
          countryCode: 'TZ',
          name: 'Tanzania Institute of Education (TIE)',
        ),
      ],
      curricula: [
        const Curriculum(
          id: 'cur-tz-1',
          countryCode: 'TZ',
          educationSystemId: 'sys-tz-1',
          name: 'Tanzania National Curriculum',
          code: 'TZ-NAT-2026',
        ),
      ],
      levels: [
        const EducationLevel(
          id: 'lvl-tz-pre',
          curriculumId: 'cur-tz-1',
          name: 'Pre-Primary (Elimu ya Awali)',
          code: 'PRE',
          sequence: 1,
        ),
        const EducationLevel(
          id: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Primary Education (Elimu ya Msingi)',
          code: 'PRI',
          sequence: 2,
        ),
        const EducationLevel(
          id: 'lvl-tz-sec-o',
          curriculumId: 'cur-tz-1',
          name: 'Secondary Ordinary Level (O-Level)',
          code: 'SEC_O',
          sequence: 3,
        ),
        const EducationLevel(
          id: 'lvl-tz-sec-a',
          curriculumId: 'cur-tz-1',
          name: 'Secondary Advanced Level (A-Level)',
          code: 'SEC_A',
          sequence: 4,
        ),
      ],
      grades: [
        const EducationGrade(
          id: 'grd-tz-std-1',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 1 (Darasa la Kwanza)',
          code: 'STD_1',
          sequence: 1,
        ),
        const EducationGrade(
          id: 'grd-tz-std-2',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 2 (Darasa la Pili)',
          code: 'STD_2',
          sequence: 2,
        ),
        const EducationGrade(
          id: 'grd-tz-std-3',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 3 (Darasa la Tatu)',
          code: 'STD_3',
          sequence: 3,
        ),
        const EducationGrade(
          id: 'grd-tz-std-4',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 4 (Darasa la Nne)',
          code: 'STD_4',
          sequence: 4,
        ),
        const EducationGrade(
          id: 'grd-tz-std-5',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 5 (Darasa la Tano)',
          code: 'STD_5',
          sequence: 5,
        ),
        const EducationGrade(
          id: 'grd-tz-std-6',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 6 (Darasa la Sita)',
          code: 'STD_6',
          sequence: 6,
        ),
        const EducationGrade(
          id: 'grd-tz-std-7',
          educationLevelId: 'lvl-tz-pri',
          curriculumId: 'cur-tz-1',
          name: 'Standard 7 (Darasa la Saba)',
          code: 'STD_7',
          sequence: 7,
        ),
        const EducationGrade(
          id: 'grd-tz-form-1',
          educationLevelId: 'lvl-tz-sec-o',
          curriculumId: 'cur-tz-1',
          name: 'Form 1 (Kidato cha Kwanza)',
          code: 'FORM_1',
          sequence: 8,
        ),
        const EducationGrade(
          id: 'grd-tz-form-2',
          educationLevelId: 'lvl-tz-sec-o',
          curriculumId: 'cur-tz-1',
          name: 'Form 2 (Kidato cha Pili)',
          code: 'FORM_2',
          sequence: 9,
        ),
        const EducationGrade(
          id: 'grd-tz-form-3',
          educationLevelId: 'lvl-tz-sec-o',
          curriculumId: 'cur-tz-1',
          name: 'Form 3 (Kidato cha Tatu)',
          code: 'FORM_3',
          sequence: 10,
        ),
        const EducationGrade(
          id: 'grd-tz-form-4',
          educationLevelId: 'lvl-tz-sec-o',
          curriculumId: 'cur-tz-1',
          name: 'Form 4 (Kidato cha Nne)',
          code: 'FORM_4',
          sequence: 11,
        ),
      ],
      schools: const [],
    );

    return _buildChildForm(context, onboardingSession, fallbackCatalog);
  }

  Widget _buildProgressHeader({
    required int currentStep,
    required int totalSteps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $currentStep OF $totalSteps: REGISTER CHILD',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).toInt()}% Complete',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 6,
            backgroundColor: LearnTzColors.neutral200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(LearnTzColors.primary),
          ),
        ),
      ],
    );
  }
}
