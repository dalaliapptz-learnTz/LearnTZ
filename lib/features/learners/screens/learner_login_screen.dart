// LearnTZ — Child-Friendly Learner Login & Device Linking Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../providers/learner_auth_providers.dart';

class LearnerLoginScreen extends ConsumerStatefulWidget {
  const LearnerLoginScreen({super.key});

  @override
  ConsumerState<LearnerLoginScreen> createState() => _LearnerLoginScreenState();
}

class _LearnerLoginScreenState extends ConsumerState<LearnerLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Credential Login
  final _idController = TextEditingController();
  final _secretController = TextEditingController();
  bool _obscureSecret = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Device Linking
  final _tokenCodeController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _isLinking = false;
  String? _linkErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idController.dispose();
    _secretController.dispose();
    _tokenCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCredentialSignIn() async {
    final identifier = _idController.text.trim();
    final secret = _secretController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Learner ID or Username');
      return;
    }
    if (secret.isEmpty) {
      setState(() => _errorMessage = 'Please enter your PIN or Password');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(activeLearnerSessionProvider.notifier).signInWithCredential(
            identifier: identifier,
            secret: secret,
            deviceName: 'Child Device',
            deviceType: 'phone',
          );
      if (mounted) {
        context.go(AppRoutes.learnerDashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleLinkDevice() async {
    final code = _tokenCodeController.text.trim().toUpperCase();
    final devName = _deviceNameController.text.trim().isNotEmpty
        ? _deviceNameController.text.trim()
        : 'Student Device';

    if (code.isEmpty) {
      setState(() => _linkErrorMessage = 'Please enter the 6-character code from your parent');
      return;
    }

    setState(() {
      _isLinking = true;
      _linkErrorMessage = null;
    });

    try {
      await ref.read(activeLearnerSessionProvider.notifier).linkDevice(
            tokenCode: code,
            deviceName: devName,
            deviceType: 'tablet',
          );
      if (mounted) {
        context.go(AppRoutes.learnerDashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _linkErrorMessage = e.toString().replaceAll('Exception: ', '');
          _isLinking = false;
        });
      }
    }
  }

  void _showNeedHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LearnTzColors.primary50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: LearnTzColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Need Help Signing In?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask your parent or guardian to help you:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildHelpStep(
              '1',
              'Parent opens LearnTZ on their phone and signs in to the Parent Dashboard.',
            ),
            const SizedBox(height: 8),
            _buildHelpStep(
              '2',
              'Tap your profile and select "Device Management".',
            ),
            const SizedBox(height: 8),
            _buildHelpStep(
              '3',
              'They can see your unique Learner ID, reset your PIN, or generate a 6-digit Device Code for you.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LearnTzColors.neutral200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: LearnTzColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For child safety, learners never require an email address or mobile phone number.',
                      style: TextStyle(fontSize: 12, color: LearnTzColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: LearnTzColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: LearnTzColors.primary,
          child: Text(
            num,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LearnTzColors.textPrimary),
          onPressed: () => context.go(AppRoutes.welcome),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.signIn),
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Parent Sign In'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 20,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Brand Header with friendly icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [LearnTzColors.primary, LearnTzColors.primary400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LearnTzColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'STUDENT PORTAL',
                    style: LearnTzTypography.caption.copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: LearnTzColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to LearnTZ!',
                    style: LearnTzTypography.h2.copyWith(
                      fontWeight: FontWeight.w900,
                      color: LearnTzColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learn Anywhere, Anytime.',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Child-friendly Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: LearnTzColors.neutral100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: LearnTzColors.primary,
                      unselectedLabelColor: LearnTzColors.neutral600,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.key_rounded, size: 18),
                          text: 'Learner ID & PIN',
                        ),
                        Tab(
                          icon: Icon(Icons.qr_code_rounded, size: 18),
                          text: 'Link Device',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Views
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCredentialLoginForm(),
                        _buildDeviceLinkingForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LearnTzColors.errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LearnTzColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: LearnTzColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: LearnTzColors.errorText, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Learner ID / Username input
        TextFormField(
          controller: _idController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Learner ID or Username',
            hintText: 'e.g. LTZ-26-881920 or baraka-4921',
            prefixIcon: const Icon(Icons.badge_outlined, color: LearnTzColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        // PIN / Password input
        TextFormField(
          controller: _secretController,
          obscureText: _obscureSecret,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: 'PIN or Password',
            hintText: 'Enter your 4-6 digit PIN',
            prefixIcon: const Icon(Icons.lock_outline, color: LearnTzColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSecret ? Icons.visibility_off : Icons.visibility,
                color: LearnTzColors.neutral500,
              ),
              onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onFieldSubmitted: (_) => _handleCredentialSignIn(),
        ),
        const SizedBox(height: 12),

        // Need Help / Forgot PIN
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showNeedHelpDialog,
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('Forgot PIN / Need Help?'),
            style: TextButton.styleFrom(
              foregroundColor: LearnTzColors.secondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sign In Action Button
        FilledButton(
          onPressed: _isSubmitting ? null : _handleCredentialSignIn,
          style: FilledButton.styleFrom(
            backgroundColor: LearnTzColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'SIGN IN TO LEARNTZ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceLinkingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_linkErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LearnTzColors.errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LearnTzColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: LearnTzColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _linkErrorMessage!,
                    style: const TextStyle(
                        color: LearnTzColors.errorText, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Instructions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LearnTzColors.primary50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LearnTzColors.primary100),
          ),
          child: Row(
            children: [
              const Icon(Icons.devices_rounded,
                  color: LearnTzColors.primary, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enter the 6-character activation code shown on your parent\'s phone.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: LearnTzColors.primary900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6-Character Activation Code
        TextFormField(
          controller: _tokenCodeController,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w900,
            color: LearnTzColors.primary,
          ),
          decoration: InputDecoration(
            labelText: 'Activation Code (6 Characters)',
            hintText: 'e.g. A8X9K2',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),

        // Device Name
        TextFormField(
          controller: _deviceNameController,
          decoration: InputDecoration(
            labelText: 'Device Name (Optional)',
            hintText: 'e.g. My Tablet or Bedroom iPad',
            prefixIcon: const Icon(Icons.phone_android_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),

        // Link My Account Action Button
        FilledButton.icon(
          onPressed: _isLinking ? null : _handleLinkDevice,
          icon: _isLinking
              ? const SizedBox.shrink()
              : const Icon(Icons.link_rounded, size: 20),
          label: _isLinking
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'LINK MY ACCOUNT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
          style: FilledButton.styleFrom(
            backgroundColor: LearnTzColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
