import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/country_configuration.dart';
import '../../../core/config/country_providers.dart';
import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/state/app_providers.dart';
import '../providers/onboarding_providers.dart';

class OnboardingCountryScreen extends ConsumerStatefulWidget {
  const OnboardingCountryScreen({super.key});

  @override
  ConsumerState<OnboardingCountryScreen> createState() =>
      _OnboardingCountryScreenState();
}

class _OnboardingCountryScreenState
    extends ConsumerState<OnboardingCountryScreen> {
  static const Map<String, ({String flag, String dialCode, String systemName})>
      _countryMeta = {
    'TZ': (
      flag: '🇹🇿',
      dialCode: '+255',
      systemName: 'Tanzania Institute of Education (TIE)'
    ),
    'KE': (
      flag: '🇰🇪',
      dialCode: '+254',
      systemName: 'Kenya CBC (Competency-Based Curriculum)'
    ),
    'UG': (
      flag: '🇺🇬',
      dialCode: '+256',
      systemName: 'Uganda National Curriculum (NCDC)'
    ),
    'RW': (
      flag: '🇷🇼',
      dialCode: '+250',
      systemName: 'Rwanda Basic Education Board (REB)'
    ),
    'BI': (
      flag: '🇧🇮',
      dialCode: '+257',
      systemName: 'Burundi Basic Education System'
    ),
    'SS': (
      flag: '🇸🇸',
      dialCode: '+211',
      systemName: 'South Sudan National Curriculum'
    ),
  };

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedCountryProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Indicator
              _buildProgressHeader(currentStep: 1, totalSteps: 5),
              const SizedBox(height: 24),

              // Header
              Text(
                'Select Your Country',
                style: LearnTzTypography.h1.copyWith(
                  color: LearnTzColors.textPrimary,
                  fontSize: isWide ? 34 : 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose where your child attends school. LearnTZ automatically configures the appropriate national curriculum and grading scale.',
                style: LearnTzTypography.bodyLarge.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Country list
              countriesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildFallbackList(selectedCountry),
                data: (items) => _buildCountryList(items, selectedCountry),
              ),

              const SizedBox(height: 32),

              // Selected Country Summary & Action
              _buildBottomAction(context, selectedCountry),
            ],
          ),
        ),
      ),
    );
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
              'STEP $currentStep OF $totalSteps: COUNTRY SELECTION',
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
            valueColor: const AlwaysStoppedAnimation<Color>(LearnTzColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryList(
    List<CountryConfiguration> items,
    CountryConfiguration selected,
  ) {
    return Column(
      children: [
        for (final country in items) ...[
          _CountryTile(
            country: country,
            meta: _countryMeta[country.countryCode] ??
                (flag: '🌍', dialCode: '+000', systemName: country.educationSystem),
            isSelected: country.countryCode == selected.countryCode,
            onTap: () {
              ref.read(selectedCountryProvider.notifier).selectCountry(country);
              ref
                  .read(onboardingSessionProvider.notifier)
                  .selectCountry(country);
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFallbackList(CountryConfiguration selected) {
    // Standard 6 East African countries fallback
    final fallbackList = [
      tanzaniaConfiguration,
      const CountryConfiguration(
        countryCode: 'KE',
        displayName: 'Kenya',
        productName: 'LearnKE',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'KES',
        educationSystem: 'Kenya CBC (Competency-Based Curriculum)',
        supportedLanguageCodes: ['en', 'sw'],
        isDefault: false,
      ),
      const CountryConfiguration(
        countryCode: 'UG',
        displayName: 'Uganda',
        productName: 'LearnUG',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'UGX',
        educationSystem: 'Uganda National Curriculum (NCDC)',
        supportedLanguageCodes: ['en'],
        isDefault: false,
      ),
      const CountryConfiguration(
        countryCode: 'RW',
        displayName: 'Rwanda',
        productName: 'LearnRW',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'RWF',
        educationSystem: 'Rwanda Basic Education Board (REB)',
        supportedLanguageCodes: ['en', 'fr'],
        isDefault: false,
      ),
      const CountryConfiguration(
        countryCode: 'BI',
        displayName: 'Burundi',
        productName: 'LearnBI',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'BIF',
        educationSystem: 'Burundi Basic Education System',
        supportedLanguageCodes: ['fr', 'sw'],
        isDefault: false,
      ),
      const CountryConfiguration(
        countryCode: 'SS',
        displayName: 'South Sudan',
        productName: 'LearnSS',
        primaryBrandColor: 0xFF0F4C81,
        accentBrandColor: 0xFF15803D,
        currencyCode: 'SSP',
        educationSystem: 'South Sudan National Curriculum',
        supportedLanguageCodes: ['en'],
        isDefault: false,
      ),
    ];

    return _buildCountryList(fallbackList, selected);
  }

  Widget _buildBottomAction(
    BuildContext context,
    CountryConfiguration selectedCountry,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _countryMeta[selectedCountry.countryCode]?.flag ?? '🇹🇿',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configured for ${selectedCountry.displayName}',
                      style: LearnTzTypography.h4.copyWith(
                        color: LearnTzColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${selectedCountry.productName} • Currency: ${selectedCountry.currencyCode}',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.successBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: LearnTzColors.successBorder),
                ),
                child: Text(
                  'Active',
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Education System: ${selectedCountry.educationSystem.isNotEmpty ? selectedCountry.educationSystem : "National Curriculum Framework"}',
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ref
                    .read(onboardingSessionProvider.notifier)
                    .selectCountry(selectedCountry);
                context.go(AppRoutes.onboardingRegister);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text('Continue with ${selectedCountry.displayName}'),
              style: FilledButton.styleFrom(
                backgroundColor: LearnTzColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: LearnTzTypography.button.copyWith(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.meta,
    required this.isSelected,
    required this.onTap,
  });

  final CountryConfiguration country;
  final ({String flag, String dialCode, String systemName}) meta;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? LearnTzColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LearnTzColors.primary : LearnTzColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? LearnTzShadows.sm : LearnTzShadows.none,
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LearnTzColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                meta.flag,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 16),

            // Country & System Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        country.displayName,
                        style: LearnTzTypography.h4.copyWith(
                          color: isSelected
                              ? LearnTzColors.primary800
                              : LearnTzColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: LearnTzColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          meta.dialCode,
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.systemName,
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: isSelected
                          ? LearnTzColors.primary
                          : LearnTzColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Radio / Check Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? LearnTzColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? LearnTzColors.primary
                      : LearnTzColors.neutral400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
