import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/tokens/design_tokens.dart';

@immutable
class CurriculumDropdownOption<T> {
  const CurriculumDropdownOption({
    required this.value,
    required this.label,
    this.code,
    this.subtitle,
    this.badgeText,
    this.searchTerms = '',
  });

  final T value;
  final String label;
  final String? code;
  final String? subtitle;
  final String? badgeText;
  final String searchTerms;
}

/// Accessible, responsive searchable dropdown for curriculum hierarchy selection.
/// Supports loading, empty, error (with retry), and disabled states.
class SearchableCurriculumDropdown<T> extends StatelessWidget {
  const SearchableCurriculumDropdown({
    super.key,
    required this.fieldKey,
    required this.stepNumber,
    required this.label,
    required this.hint,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.isLoading = false,
    this.isDisabled = false,
    this.disabledReason,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No official curriculum records found for this selection.',
  });

  final Key fieldKey;
  final int stepNumber;
  final String label;
  final String hint;
  final List<CurriculumDropdownOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final bool isLoading;
  final bool isDisabled;
  final String? disabledReason;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;

  CurriculumDropdownOption<T>? get _selectedOption {
    if (selectedValue == null) return null;
    for (final opt in options) {
      if (opt.value == selectedValue) return opt;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (isDisabled || isLoading) return;
    final result = await showDialog<T>(
      context: context,
      builder: (dialogContext) => _SearchablePickerDialog<T>(
        title: label,
        options: options,
        selectedValue: selectedValue,
        emptyMessage: emptyMessage,
      ),
    );
    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;
    final isEmpty = !isLoading && !isDisabled && !hasError && options.isEmpty;

    final borderColor = hasError
        ? LearnTzColors.error
        : selected != null
            ? LearnTzColors.primary
            : LearnTzColors.neutral300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected != null
                    ? LearnTzColors.secondary
                    : isDisabled
                        ? LearnTzColors.neutral200
                        : LearnTzColors.primary,
                shape: BoxShape.circle,
              ),
              child: selected != null
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '$stepNumber',
                      style: LearnTzTypography.caption.copyWith(
                        color: isDisabled
                            ? LearnTzColors.neutral500
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label *',
                style: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDisabled
                      ? LearnTzColors.neutral500
                      : LearnTzColors.textPrimary,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          enabled: !isDisabled && !isLoading,
          label: label,
          child: InkWell(
            key: fieldKey,
            borderRadius: BorderRadius.circular(10),
            onTap: (isDisabled || isLoading || hasError || isEmpty)
                ? null
                : () => _openPicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDisabled ? LearnTzColors.neutral100 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: selected != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isLoading
                        ? Text(
                            'Loading official curriculum records...',
                            style: LearnTzTypography.bodySmall.copyWith(
                              color: LearnTzColors.textSecondary,
                            ),
                          )
                        : selected != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (selected.code != null &&
                                          selected.code!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: LearnTzColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            selected.code!,
                                            style: LearnTzTypography.caption
                                                .copyWith(
                                              color: LearnTzColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        selected.label,
                                        style: LearnTzTypography.bodyRegular
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: LearnTzColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (selected.subtitle != null &&
                                      selected.subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      selected.subtitle!,
                                      style:
                                          LearnTzTypography.caption.copyWith(
                                        color: LearnTzColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              )
                            : Text(
                                isDisabled
                                    ? (disabledReason ??
                                        'Complete the previous selection first')
                                    : isEmpty
                                        ? emptyMessage
                                        : hint,
                                style: LearnTzTypography.bodySmall.copyWith(
                                  color: LearnTzColors.neutral500,
                                ),
                              ),
                  ),
                  const SizedBox(width: 8),
                  if (selected != null && !isDisabled)
                    IconButton(
                      tooltip: 'Clear $label',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => onSelected(null),
                    ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isDisabled
                        ? LearnTzColors.neutral400
                        : LearnTzColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 15, color: LearnTzColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: LearnTzTypography.caption
                      .copyWith(color: LearnTzColors.error),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SearchablePickerDialog<T> extends StatefulWidget {
  const _SearchablePickerDialog({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.emptyMessage,
  });

  final String title;
  final List<CurriculumDropdownOption<T>> options;
  final T? selectedValue;
  final String emptyMessage;

  @override
  State<_SearchablePickerDialog<T>> createState() =>
      _SearchablePickerDialogState<T>();
}

class _SearchablePickerDialogState<T>
    extends State<_SearchablePickerDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.where((opt) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return opt.label.toLowerCase().contains(q) ||
          (opt.code?.toLowerCase().contains(q) ?? false) ||
          (opt.subtitle?.toLowerCase().contains(q) ?? false) ||
          opt.searchTerms.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      title: Text(
        'Select ${widget.title}',
        style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const Key('curriculum-dropdown-search-input'),
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by official name or competence code...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isNotEmpty
                              ? 'No matching records for "$_query".'
                              : widget.emptyMessage,
                          textAlign: TextAlign.center,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final opt = filtered[index];
                        final isSelected = opt.value == widget.selectedValue;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              LearnTzColors.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: opt.code != null && opt.code!.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: LearnTzColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    opt.code!,
                                    style: LearnTzTypography.caption.copyWith(
                                      color: LearnTzColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : null,
                          title: Text(
                            opt.label,
                            style: LearnTzTypography.bodyRegular.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: opt.subtitle != null &&
                                  opt.subtitle!.isNotEmpty
                              ? Text(
                                  opt.subtitle!,
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: opt.badgeText != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: LearnTzColors.neutral100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    opt.badgeText!,
                                    style: LearnTzTypography.caption,
                                  ),
                                )
                              : isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: LearnTzColors.secondary, size: 18)
                                  : null,
                          onTap: () => Navigator.of(context).pop(opt.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
