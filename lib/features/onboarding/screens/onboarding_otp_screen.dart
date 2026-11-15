import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../providers/onboarding_providers.dart';

class OnboardingOtpScreen extends ConsumerStatefulWidget {
  const OnboardingOtpScreen({super.key});

  @override
  ConsumerState<OnboardingOtpScreen> createState() =>
      _OnboardingOtpScreenState();
}

class _OnboardingOtpScreenState extends ConsumerState<OnboardingOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 60;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    final code = _enteredCode;
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    final session = ref.read(onboardingSessionProvider);
    final phone = session.phoneNumber ?? '';

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final repository = ref.read(onboardingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Authentication backend is not available.';
      });
      return;
    }

    try {
      await repository.verifyOtp(phoneNumber: phone, token: code);
      ref.read(onboardingSessionProvider.notifier).markPhoneVerified();

      if (mounted) {
        context.go(AppRoutes.onboardingAddChild);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid verification code. Please check and try again.';
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isResending) return;

    final session = ref.read(onboardingSessionProvider);
    final phone = session.phoneNumber ?? '';

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final repository = ref.read(onboardingRepositoryProvider);
    if (repository == null) {
      setState(() => _isResending = false);
      return;
    }

    try {
      await repository.resendOtp(phoneNumber: phone);
      _startCooldownTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent successfully.'),
            backgroundColor: LearnTzColors.primary,
          ),
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Failed to resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_enteredCode.length == 6) {
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(onboardingSessionProvider);
    final phone = session.phoneNumber ?? '+255 ••• •••';
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress header
              _buildProgressHeader(currentStep: 3, totalSteps: 5),
              const SizedBox(height: 32),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: LearnTzColors.primary50,
                  shape: BoxShape.circle,
                  border: Border.all(color: LearnTzColors.primary200),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: LearnTzColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Verify Phone Number',
                style: LearnTzTypography.h1.copyWith(
                  fontSize: isWide ? 32 : 26,
                  color: LearnTzColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit confirmation code to\n$phone',
                style: LearnTzTypography.bodyLarge.copyWith(
                  color: LearnTzColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
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
                          color: LearnTzColors.error, size: 18),
                      const SizedBox(width: 10),
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
                const SizedBox(height: 24),
              ],

              // 6 PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: isWide ? 64 : 46,
                    height: isWide ? 68 : 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey ==
                                LogicalKeyboardKey.backspace &&
                            _controllers[index].text.isEmpty &&
                            index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        autofocus: index == 0,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: LearnTzTypography.h2.copyWith(
                          fontSize: isWide ? 26 : 22,
                          fontWeight: FontWeight.w800,
                          color: LearnTzColors.primary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: LearnTzColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: LearnTzColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: FilledButton.styleFrom(
                    backgroundColor: LearnTzColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm & Continue',
                          style: LearnTzTypography.button.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend timer row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the SMS code?",
                    style: LearnTzTypography.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  if (_resendCooldown > 0)
                    Text(
                      'Resend in ${_resendCooldown}s',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _handleResend,
                      child: const Text('Resend Code'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              TextButton.icon(
                onPressed: () => context.go(AppRoutes.onboardingRegister),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Phone Number'),
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
              'STEP $currentStep OF $totalSteps: PHONE VERIFICATION',
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
