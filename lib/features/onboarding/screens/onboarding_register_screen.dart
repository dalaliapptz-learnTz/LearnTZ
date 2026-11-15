import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../providers/onboarding_providers.dart';

class OnboardingRegisterScreen extends ConsumerStatefulWidget {
  const OnboardingRegisterScreen({super.key});

  @override
  ConsumerState<OnboardingRegisterScreen> createState() =>
      _OnboardingRegisterScreenState();
}

class _OnboardingRegisterScreenState
    extends ConsumerState<OnboardingRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = true;
  bool _acceptedPrivacy = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Map<String, ({String flag, String dialCode})> _countryDial = {
    'TZ': (flag: '🇹🇿', dialCode: '+255'),
    'KE': (flag: '🇰🇪', dialCode: '+254'),
    'UG': (flag: '🇺🇬', dialCode: '+256'),
    'RW': (flag: '🇷🇼', dialCode: '+250'),
    'BI': (flag: '🇧🇮', dialCode: '+257'),
    'SS': (flag: '🇸🇸', dialCode: '+211'),
  };

  @override
  void initState() {
    super.initState();
    final session = ref.read(onboardingSessionProvider);
    if (session.parentFullName != null) {
      _nameController.text = session.parentFullName!;
    }
    if (session.phoneNumber != null) {
      _phoneController.text = session.phoneNumber!;
    }
    if (session.email != null) {
      _emailController.text = session.email!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getCountryDialCode(String countryCode) {
    return _countryDial[countryCode]?.dialCode ?? '+255';
  }

  String _formatFullPhoneNumber(String input, String countryCode) {
    final dial = _getCountryDialCode(countryCode);
    final clean = input.trim().replaceAll(RegExp(r'\D'), '');
    if (input.trim().startsWith('+')) {
      return input.trim();
    }
    if (clean.startsWith('0')) {
      return '$dial${clean.substring(1)}';
    }
    return '$dial$clean';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      setState(() {
        _errorMessage =
            'Please accept the Terms of Service and Privacy Policy to protect your child.';
      });
      return;
    }

    final session = ref.read(onboardingSessionProvider);
    final countryCode = session.countryCode;
    final formattedPhone =
        _formatFullPhoneNumber(_phoneController.text, countryCode);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(onboardingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Authentication backend is not connected.';
      });
      return;
    }

    try {
      // 1. Check duplicate phone number
      final isTaken = await repository.checkPhoneRegistered(formattedPhone);
      if (isTaken) {
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'This phone number is already registered. Please sign in or use a different number.';
        });
        return;
      }

      // 2. Register parent via Supabase
      await repository.registerParent(
        fullName: _nameController.text.trim(),
        phoneNumber: formattedPhone,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        password: _passwordController.text,
        countryCode: countryCode,
      );

      // 3. Update local onboarding state
      ref.read(onboardingSessionProvider.notifier).setParentRegistration(
            fullName: _nameController.text.trim(),
            phoneNumber: formattedPhone,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
          );
      ref.read(onboardingSessionProvider.notifier).setConsent(
            terms: _acceptedTerms,
            privacy: _acceptedPrivacy,
          );

      if (mounted) {
        context.go(AppRoutes.onboardingVerifyOtp);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Registration could not be completed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(onboardingSessionProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final countryDial = _countryDial[session.countryCode] ??
        (flag: '🇹🇿', dialCode: '+255');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressHeader(currentStep: 2, totalSteps: 5),
              const SizedBox(height: 24),

              // Title
              Text(
                'Create Parent Account',
                style: LearnTzTypography.h1.copyWith(
                  color: LearnTzColors.textPrimary,
                  fontSize: isWide ? 34 : 28,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    countryDial.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Registering in ${session.countryName}',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      color: LearnTzColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.onboardingCountry),
                    child: const Text('Change Country'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Child-Data Privacy Banner
              _buildChildPrivacyBanner(),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LearnTzColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LearnTzColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: LearnTzColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
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

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    Text(
                      'Parent / Guardian Full Name',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'e.g. Grace Mwangi',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Please enter a valid full name (minimum 3 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Phone Number with Country Dial Code
                    Text(
                      'Mobile Phone Number',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: '712 345 678',
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 80, minHeight: 48),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(countryDial.flag),
                              const SizedBox(width: 6),
                              Text(
                                countryDial.dialCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText:
                            'Used for SMS verification and parental account security.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mobile phone number is required';
                        }
                        final clean = value.replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 8) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Optional Email
                    Text(
                      'Email Address (Optional)',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'e.g. grace@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'For weekly progress reports and receipts.',
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password
                    Text(
                      'Security Password',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'Password must contain at least one number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Confirm Password
                    Text(
                      'Confirm Password',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Repeat password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Terms & Privacy Checkboxes
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (val) =>
                          setState(() => _acceptedTerms = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I agree to the LearnTZ Terms of Service',
                        style: LearnTzTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _acceptedPrivacy,
                      onChanged: (val) =>
                          setState(() => _acceptedPrivacy = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I accept the Privacy Policy & Child Data Protection Code',
                        style: LearnTzTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _handleRegister,
                        style: FilledButton.styleFrom(
                          backgroundColor: LearnTzColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Create Account & Verify Phone',
                                    style: LearnTzTypography.button.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Already have an account?
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already registered?',
                            style: LearnTzTypography.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.signIn),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
              'STEP $currentStep OF $totalSteps: PARENT REGISTRATION',
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

  Widget _buildChildPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearnTzColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LearnTzColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: LearnTzColors.secondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Child Privacy & Data Protection Guarantee',
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LearnTzColors.secondary800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'LearnTZ adheres to strict children privacy regulations. Learner profiles are protected by parent authorization and never shared with commercial third parties.',
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.textSecondary,
                    height: 1.4,
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
