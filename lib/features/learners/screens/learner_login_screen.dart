// LearnTZ — Child-Friendly Learner Login & Device Linking Screen

import 'package:material_ui/material_ui.dart';
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

  int _activeTab = 0;

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Clean Top Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A),
                      ),
                      onPressed: () => context.go(AppRoutes.welcome),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.signIn),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F4C81),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 17),
                      label: const Text('Parent Sign In'),
                    ),
                  ],
                ),
              ),

              // Main Centered Card
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 8 : 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        children: [
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Brand Accent Strip
                                Container(
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF15803D),
                                        Color(0xFF0F4C81),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isMobile ? 20 : 30,
                                    isMobile ? 24 : 30,
                                    isMobile ? 20 : 30,
                                    isMobile ? 24 : 28,
                                  ),
                                  child: Column(
                                    children: [
                                      // Friendly Emblem
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0F4C81),
                                              Color(0xFF1D63A1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0F4C81)
                                                  .withValues(alpha: 0.22),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.school_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'STUDENT PORTAL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 1.4,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Welcome to LearnTZ!',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                              letterSpacing: -0.3,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Learn Anywhere, Anytime.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 22),

                                      // Clean Segmented Switcher
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: TabBar(
                                          controller: _tabController,
                                          onTap: (index) =>
                                              setState(() => _activeTab = index),
                                          dividerColor: Colors.transparent,
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.06),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          labelColor: const Color(0xFF0F4C81),
                                          unselectedLabelColor:
                                              const Color(0xFF64748B),
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                          tabs: const [
                                            Tab(
                                              height: 42,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.key_rounded, size: 16),
                                                  SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Learner ID & PIN',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Tab(
                                              height: 42,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.qr_code_rounded,
                                                      size: 16),
                                                  SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Link Device',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 22),

                                      // Active Form (clean natural height, zero clipping)
                                      if (_activeTab == 0)
                                        _buildCredentialLoginForm()
                                      else
                                        _buildDeviceLinkingForm(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                size: 15,
                                color: Color(0xFF15803D),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Safe student access · No email or phone required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB91C1C),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Learner ID / Username input
        TextFormField(
          controller: _idController,
          textCapitalization: TextCapitalization.characters,
          decoration: _fieldDecoration(
            label: 'Learner ID or Username',
            hint: 'e.g. LTZ-26-881920 or baraka-4921',
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // PIN / Password input
        TextFormField(
          controller: _secretController,
          obscureText: _obscureSecret,
          keyboardType: TextInputType.visiblePassword,
          decoration: _fieldDecoration(
            label: 'PIN or Password',
            hint: 'Enter your 4-6 digit PIN',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSecret
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
            ),
          ),
          onFieldSubmitted: (_) => _handleCredentialSignIn(),
        ),
        const SizedBox(height: 6),

        // Need Help / Forgot PIN
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showNeedHelpDialog,
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('Forgot PIN / Need Help?'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F4C81),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Sign In Action Button
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _handleCredentialSignIn,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SIGN IN TO LEARNTZ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      fontSize: 15,
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB91C1C),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _linkErrorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.devices_rounded, color: Color(0xFF0F4C81), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enter the 6-character activation code shown on your parent\'s phone.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6-Character Activation Code
        TextFormField(
          controller: _tokenCodeController,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F4C81),
          ),
          decoration: _fieldDecoration(
            label: 'Activation Code (6 Characters)',
            hint: 'e.g. A8X9K2',
          ),
        ),
        const SizedBox(height: 14),

        // Device Name
        TextFormField(
          controller: _deviceNameController,
          decoration: _fieldDecoration(
            label: 'Device Name (Optional)',
            hint: 'e.g. My Tablet or Bedroom iPad',
            icon: Icons.phone_android_outlined,
          ),
        ),
        const SizedBox(height: 18),

        // Link My Account Action Button
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _isLinking ? null : _handleLinkDevice,
            icon: _isLinking
                ? const SizedBox.shrink()
                : const Icon(Icons.link_rounded, size: 19),
            label: _isLinking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'LINK MY ACCOUNT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      fontSize: 15,
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
