import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../admin_models.dart';
import '../admin_providers.dart';

/// LearnTZ — Administrator Invitations Management Screen (`/admin/invitations`)
class AdminInvitationsScreen extends ConsumerStatefulWidget {
  const AdminInvitationsScreen({super.key});

  @override
  ConsumerState<AdminInvitationsScreen> createState() => _AdminInvitationsScreenState();
}

class _AdminInvitationsScreenState extends ConsumerState<AdminInvitationsScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'CONTENT_ADMIN';
  String? _selectedCountry;
  bool _isCreating = false;

  final List<String> _canonicalRoles = const [
    'SUPER_ADMIN',
    'COUNTRY_ADMIN',
    'CONTENT_ADMIN',
    'FINANCE_ADMIN',
    'SUPPORT_ADMIN',
    'ANALYTICS_ADMIN',
    'SECURITY_ADMIN',
  ];

  final Map<String, String> _countryOptions = const {
    'TZ': 'Tanzania (TZ)',
    'KE': 'Kenya (KE)',
    'UG': 'Uganda (UG)',
    'RW': 'Rwanda (RW)',
    'BI': 'Burundi (BI)',
    'SS': 'South Sudan (SS)',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showNewInvitationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Issue Administrator Invitation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invitations generate a single-use cryptographically signed token valid for 72 hours.',
                  style: TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Dr. Jane Mwangi',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email Address',
                  hint: 'jane.mwangi@learntz.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Canonical Role',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _canonicalRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country Scope',
                    helperText: _selectedRole == 'COUNTRY_ADMIN' ? 'Required for COUNTRY_ADMIN' : 'Optional scope',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Global / Platform Wide')),
                    ..._countryOptions.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (val) => setDialogState(() => _selectedCountry = val),
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
              label: 'Generate Invitation',
              size: AppButtonSize.sm,
              isLoading: _isCreating,
              onPressed: () async {
                final email = _emailController.text.trim();
                final name = _nameController.text.trim();
                if (email.isEmpty || name.isEmpty) return;

                setDialogState(() => _isCreating = true);
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  if (repo == null) throw Exception('Backend unavailable');

                  final inv = await repo.createInvitation(
                    email: email,
                    fullName: name,
                    roleName: _selectedRole,
                    countryScope: _selectedCountry,
                  );

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ref.invalidate(adminInvitationsProvider);
                    _showGeneratedTokenDialog(inv);
                  }
                } catch (e) {
                  setDialogState(() => _isCreating = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: LearnTzColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneratedTokenDialog(AdminInvitation inv) {
    final token = inv.token ?? 'SECURE-TOKEN-GENERATED';
    final inviteLink = 'https://learntz.com/admin/invitations/accept?token=$token';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: LearnTzColors.secondary),
            SizedBox(width: 8),
            Text('Invitation Issued'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invitation created for ${inv.email} (${inv.roleName}).'),
            const SizedBox(height: 12),
            const Text(
              'Share this activation link with the invited administrator. It expires in 72 hours and can only be used once:',
              style: TextStyle(fontSize: 12, color: LearnTzColors.neutral600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LearnTzColors.neutral300),
              ),
              child: SelectableText(
                inviteLink,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRevoke(String invitationId) async {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.revokeInvitation(invitationId);
      ref.invalidate(adminInvitationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation revoked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: $e'), backgroundColor: LearnTzColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(adminInvitationsProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        title: const Text('Administrator Invitations'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton(
              key: const Key('admin-issue-invitation-btn'),
              label: 'Issue Invitation',
              icon: Icons.person_add_outlined,
              size: AppButtonSize.sm,
              onPressed: _showNewInvitationDialog,
            ),
          ),
        ],
      ),
      body: invitationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading invitations: $err', style: const TextStyle(color: LearnTzColors.error)),
          ),
        ),
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: AppEmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: 'No Active Invitations',
                message: 'Issue an invitation to onboard new administrators with role-based and country-scoped permissions.',
                actionLabel: 'Issue First Invitation',
                onAction: _showNewInvitationDialog,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invitations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final inv = invitations[index];
                  final statusColor = inv.isAccepted
                      ? LearnTzColors.secondary
                      : inv.isRevoked
                          ? LearnTzColors.error
                          : inv.isExpired
                              ? LearnTzColors.neutral500
                              : LearnTzColors.primary;
                  final statusLabel = inv.isAccepted
                      ? 'ACCEPTED'
                      : inv.isRevoked
                          ? 'REVOKED'
                          : inv.isExpired
                              ? 'EXPIRED'
                              : 'ACTIVE';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: LearnTzColors.primary50,
                      child: Text(
                        inv.roleName.isNotEmpty ? inv.roleName[0] : 'A',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: LearnTzColors.primary),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(inv.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        AppBadge(
                          label: inv.roleName,
                          variant: AppBadgeVariant.primary,
                          size: AppBadgeSize.sm,
                        ),
                        if (inv.countryScope != null) ...[
                          const SizedBox(width: 6),
                          AppBadge(
                            label: inv.countryScope!,
                            variant: AppBadgeVariant.neutral,
                            size: AppBadgeSize.sm,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${inv.email} • Expires: ${inv.expiresAt.toLocal().toString().split('.')[0]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        if (inv.isPending) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: LearnTzColors.error, size: 20),
                            tooltip: 'Revoke Invitation',
                            onPressed: () => _handleRevoke(inv.id),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// LearnTZ — Accept Administrator Invitation (`/admin/invitations/accept`)
class AdminAcceptInvitationScreen extends ConsumerStatefulWidget {
  const AdminAcceptInvitationScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<AdminAcceptInvitationScreen> createState() => _AdminAcceptInvitationScreenState();
}

class _AdminAcceptInvitationScreenState extends ConsumerState<AdminAcceptInvitationScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      setState(() => _errorMessage = 'Missing administrator invitation token.');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      if (repo == null) throw Exception('Administrative service unavailable');

      await repo.acceptInvitation(
        token: token,
        fullName: _nameController.text.trim(),
      );

      if (!mounted) return;
      // Immediately transition to mandatory MFA setup
      context.go('/admin/mfa-setup');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.token;

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppBrandLogo(height: 44)),
                  const SizedBox(height: 16),
                  const Text(
                    'Accept Administrator Invitation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set your password and identity verification to activate your administrative privileges.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: LearnTzColors.neutral600),
                  ),
                  const SizedBox(height: 24),

                  if (token == null || token.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LearnTzColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Invalid invitation link: Token is missing. Please contact your system administrator.',
                        style: TextStyle(color: LearnTzColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Go to Admin Login',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.go('/admin/login'),
                    ),
                  ] else ...[
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LearnTzColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: LearnTzColors.error, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Confirm your legal full name',
                      controller: _nameController,
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'New Master Password',
                      hint: 'Minimum 8 characters with numbers & symbols',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirm Master Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_clock_outlined,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Accept & Configure MFA',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleAccept,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
