import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../admin_providers.dart';

/// LearnTZ — Enterprise Admin Login Screen (`/admin/login`)
/// Isolated from learner/parent authentication with mandatory MFA challenge.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isMfaStep = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimarySignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo == null) throw Exception('Authentication service unavailable');
      await authRepo.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check administrative capabilities
      final adminRepo = ref.read(adminRepositoryProvider);
      if (adminRepo == null) throw Exception('Administrative service unavailable');

      final capabilities = await adminRepo.getCapabilities();
      if (!capabilities.canAccessAdmin) {
        // Not an authorized admin user
        await authRepo.signOut();
        throw Exception(
          'Unauthorized: Your account does not possess administrative privileges.',
        );
      }

      // Check MFA requirement
      if (!capabilities.isMfaEnrolled) {
        // Must complete initial MFA setup
        if (!mounted) return;
        context.go('/admin/mfa-setup');
        return;
      }

      // Move to Step 2: Mandatory MFA verification
      setState(() {
        _isMfaStep = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMfaVerification() async {
    final code = _mfaCodeController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      if (adminRepo == null) throw Exception('Administrative service unavailable');

      // Verify MFA code with backend
      await adminRepo.verifyMfaCode(code);
      ref.read(adminSessionMfaVerifiedProvider.notifier).setVerified(true);

      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showBootstrapDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    bool isBootstrapping = false;
    String? dialogError;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LearnTzColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined, color: LearnTzColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Initial Super Admin Bootstrap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controlled deployment procedure to provision the initial Super Admin. This action permanently locks the bootstrap endpoint after execution.',
                  style: TextStyle(fontSize: 13, color: LearnTzColors.neutral600),
                ),
                const SizedBox(height: 16),
                if (dialogError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: LearnTzColors.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(fontSize: 12, color: LearnTzColors.error),
                    ),
                  ),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Lead Platform Architect',
                  controller: nameCtrl,
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Super Admin Email',
                  hint: 'superadmin@learntz.com',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Deployment Secret Token',
                  hint: 'Enter bootstrap security token',
                  controller: secretCtrl,
                  isPassword: true,
                  prefixIcon: Icons.key_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Execute Bootstrap',
              isLoading: isBootstrapping,
              size: AppButtonSize.sm,
              onPressed: isBootstrapping
                  ? null
                  : () async {
                      setDialogState(() {
                        isBootstrapping = true;
                        dialogError = null;
                      });
                      try {
                        final adminRepo = ref.read(adminRepositoryProvider);
                        if (adminRepo == null) throw Exception('Backend unavailable');
                        await adminRepo.bootstrapSuperAdmin(
                          email: emailCtrl.text,
                          fullName: nameCtrl.text,
                          secretToken: secretCtrl.text,
                        );
                        if (ctx.mounted && mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Initial Super Admin successfully provisioned! Please sign in.'),
                              backgroundColor: LearnTzColors.secondary,
                            ),
                          );
                        }
                      } catch (err) {
                        setDialogState(() {
                          dialogError = err.toString().replaceAll('Exception: ', '');
                          isBootstrapping = false;
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Admin Badge
                    Center(
                      child: Column(
                        children: [
                          const AppBrandLogo(height: 48),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: LearnTzColors.primary50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: LearnTzColors.primary.withAlpha(51)),
                            ),
                            child: const Text(
                              'ADMINISTRATION PORTAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: LearnTzColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security Notice Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LearnTzColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LearnTzColors.warning.withAlpha(76)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined, color: LearnTzColors.warning, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'RESTRICTED ACCESS. Authorized administrative personnel only. All access attempts and telemetry are immutably audited.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: LearnTzColors.neutral800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LearnTzColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: LearnTzColors.error.withAlpha(51)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: LearnTzColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: LearnTzColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isMfaStep) ...[
                      // Step 1: Email & Password
                      AppTextField(
                        key: const Key('admin-login-email-field'),
                        label: 'Administrator Email',
                        hint: 'admin@learntz.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.alternate_email,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid administrator email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        key: const Key('admin-login-password-field'),
                        label: 'Master Password',
                        hint: '••••••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        key: const Key('admin-login-submit-btn'),
                        label: 'Authenticate Identity',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handlePrimarySignIn,
                      ),
                    ] else ...[
                      // Step 2: MFA TOTP Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LearnTzColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_clock_outlined, size: 36, color: LearnTzColors.primary),
                            const SizedBox(height: 8),
                            const Text(
                              'Two-Factor Authentication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter the 6-digit code from your authenticator app for ${_emailController.text}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        key: const Key('admin-mfa-code-field'),
                        label: '6-Digit TOTP Code',
                        hint: '123456',
                        controller: _mfaCodeController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.security,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        key: const Key('admin-mfa-submit-btn'),
                        label: 'Verify MFA Challenge',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleMfaVerification,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isMfaStep = false;
                              _mfaCodeController.clear();
                              _errorMessage = null;
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back to Password Sign-In'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Bootstrap Provisioning Link
                    Center(
                      child: TextButton.icon(
                        key: const Key('admin-bootstrap-modal-btn'),
                        onPressed: _showBootstrapDialog,
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: LearnTzColors.neutral500),
                        label: const Text(
                          'Initial System Bootstrap',
                          style: TextStyle(fontSize: 12, color: LearnTzColors.neutral500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
