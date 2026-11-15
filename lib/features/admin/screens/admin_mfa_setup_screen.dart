import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/state/app_providers.dart';
import '../admin_models.dart';
import '../admin_providers.dart';

/// LearnTZ — Mandatory Administrator MFA Enrolment (`/admin/mfa-setup`)
class AdminMfaSetupScreen extends ConsumerStatefulWidget {
  const AdminMfaSetupScreen({super.key});

  @override
  ConsumerState<AdminMfaSetupScreen> createState() => _AdminMfaSetupScreenState();
}

class _AdminMfaSetupScreenState extends ConsumerState<AdminMfaSetupScreen> {
  final _verificationCodeController = TextEditingController();
  AdminMfaSetupData? _mfaData;
  bool _hasBackedUpCodes = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMfaData());
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _initMfaData() {
    final client = ref.read(supabaseClientProvider);
    final email = client?.auth.currentUser?.email ?? 'admin@learntz.com';
    final repo = ref.read(adminRepositoryProvider);
    if (repo != null) {
      setState(() {
        _mfaData = repo.generateMfaSetupData(email);
      });
    }
  }

  Future<void> _handleCompleteMfa() async {
    final code = _verificationCodeController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code.');
      return;
    }
    if (!_hasBackedUpCodes) {
      setState(() => _errorMessage = 'Please confirm that you have stored your emergency backup codes.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      if (repo == null) throw Exception('Administrative service unavailable');

      if (_mfaData != null) {
        await repo.setupMfa(
          totpSecret: _mfaData!.secretKey,
          recoveryCodes: _mfaData!.recoveryCodes,
        );
      }

      ref.read(adminSessionMfaVerifiedProvider.notifier).setVerified(true);
      ref.invalidate(adminCapabilitiesProvider);

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        title: const AppBrandLogo(height: 32),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: LearnTzColors.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LearnTzColors.warning.withAlpha(76)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: LearnTzColors.warning),
                SizedBox(width: 6),
                Text(
                  'MFA REQUIRED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: LearnTzColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LearnTzColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_outlined,
                          size: 28,
                          color: LearnTzColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Multi-Factor Authentication Enrolment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.neutral900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'LearnTZ Security Policy requires all administrators to configure TOTP 2FA.',
                              style: TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LearnTzColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LearnTzColors.error.withAlpha(51)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: LearnTzColors.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Step 1: Secret Key
                  const Text(
                    'Step 1: Add to Authenticator App',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan or manually enter the following Base32 secret key into Google Authenticator, 1Password, or Authy:',
                    style: TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: LearnTzColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LearnTzColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _mfaData?.secretKey ?? 'LOADING-SECRET-KEY',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.5,
                              color: LearnTzColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy Secret Key',
                          onPressed: _mfaData != null
                              ? () => _copyToClipboard(_mfaData!.secretKey, 'Secret Key')
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 2: Emergency Recovery Codes
                  const Text(
                    'Step 2: Save Emergency Recovery Codes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These single-use codes grant account recovery if you lose access to your primary authenticator device:',
                    style: TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
                  ),
                  const SizedBox(height: 12),
                  if (_mfaData != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LearnTzColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LearnTzColors.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              for (final code in _mfaData!.recoveryCodes)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: LearnTzColors.neutral300),
                                  ),
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: LearnTzColors.neutral800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              final allCodes = _mfaData!.recoveryCodes.join('\n');
                              _copyToClipboard(allCodes, 'Recovery codes');
                            },
                            icon: const Icon(Icons.copy_all, size: 16),
                            label: const Text('Copy All Recovery Codes'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    value: _hasBackedUpCodes,
                    onChanged: (val) => setState(() => _hasBackedUpCodes = val ?? false),
                    title: const Text(
                      'I confirm that I have securely stored these 8 recovery codes in an encrypted password manager or physical vault.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Step 3: Verify 6-digit Code
                  const Text(
                    'Step 3: Confirm 6-Digit Verification Code',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    key: const Key('admin-mfa-setup-code-field'),
                    label: 'Code from Authenticator App',
                    hint: '123456',
                    controller: _verificationCodeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.security,
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    key: const Key('admin-mfa-setup-submit-btn'),
                    label: 'Activate Administrator MFA',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleCompleteMfa,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
