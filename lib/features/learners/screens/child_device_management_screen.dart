// LearnTZ — Parent Control Centre: Child Device Management Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../models/learner_access_models.dart';
import '../providers/learner_auth_providers.dart';

class ChildDeviceManagementScreen extends ConsumerStatefulWidget {
  const ChildDeviceManagementScreen({required this.learnerId, super.key});

  final String learnerId;

  @override
  ConsumerState<ChildDeviceManagementScreen> createState() =>
      _ChildDeviceManagementScreenState();
}

class _ChildDeviceManagementScreenState
    extends ConsumerState<ChildDeviceManagementScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  LearnerActivationToken? _generatedToken;
  bool _isGenerating = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _generatedToken = null;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _handleGenerateCode() async {
    setState(() => _isGenerating = true);
    final service = ref.read(learnerAuthServiceProvider);
    try {
      final token = await service.generateActivationToken(widget.learnerId);
      if (mounted) {
        setState(() {
          _generatedToken = token;
          _isGenerating = false;
        });
        _startCountdown(token.expiresInSeconds);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating code: $e'),
            backgroundColor: LearnTzColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRevokeDevice(String deviceId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Device Access?'),
        content: Text(
          'Are you sure you want to revoke "$deviceName"? The child will be immediately signed out on that device. Learning history is safely preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LearnTzColors.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = ref.read(learnerAuthServiceProvider);
    try {
      await service.revokeDevice(learnerId: widget.learnerId, deviceId: deviceId);
      ref.invalidate(learnerDeviceManagementProvider(widget.learnerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device access revoked successfully.'),
            backgroundColor: LearnTzColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: LearnTzColors.error),
        );
      }
    }
  }

  Future<void> _handleResetPin() async {
    final pinController = TextEditingController();
    bool obscure = true;

    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Learner PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a new 4 to 6-digit PIN for your child. Do not use their date of birth.',
                style: TextStyle(fontSize: 13, color: LearnTzColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                obscureText: obscure,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'New 4-6 Digit PIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final p = pinController.text.trim();
                if (p.length < 4 || p.length > 6) {
                  return;
                }
                Navigator.of(ctx).pop(p);
              },
              child: const Text('Update PIN'),
            ),
          ],
        ),
      ),
    );

    if (newPin == null) return;

    final service = ref.read(learnerAuthServiceProvider);
    try {
      await service.resetPin(learnerId: widget.learnerId, newPin: newPin);
      ref.invalidate(learnerDeviceManagementProvider(widget.learnerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN updated successfully!'),
            backgroundColor: LearnTzColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: LearnTzColors.error),
        );
      }
    }
  }

  Future<void> _handleToggleSuspension(bool currentSuspended) async {
    final service = ref.read(learnerAuthServiceProvider);
    final targetSuspend = !currentSuspended;
    try {
      await service.toggleAccessStatus(
        learnerId: widget.learnerId,
        suspend: targetSuspend,
      );
      ref.invalidate(learnerDeviceManagementProvider(widget.learnerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetSuspend
                ? 'Learner account suspended.'
                : 'Learner account reactivated.'),
            backgroundColor: targetSuspend ? LearnTzColors.warning : LearnTzColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: LearnTzColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(learnerDeviceManagementProvider(widget.learnerId));
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        title: const Text('Child Device Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.parentDashboard),
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading device management: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.refresh(learnerDeviceManagementProvider(widget.learnerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (mgmt) {
          final token = _generatedToken ?? mgmt.activeActivationToken;
          if (token != null && _secondsRemaining == 0 && !token.isExpired) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCountdown(token.expiresInSeconds);
            });
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LearnTzColors.neutral200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: LearnTzColors.primary50,
                            child: const Icon(Icons.school_rounded,
                                color: LearnTzColors.primary, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mgmt.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: LearnTzColors.neutral100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ID: ${mgmt.learnerCode}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: LearnTzColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: mgmt.isSuspended
                                            ? LearnTzColors.errorBg
                                            : LearnTzColors.successBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: mgmt.isSuspended
                                              ? LearnTzColors.errorBorder
                                              : LearnTzColors.successBorder,
                                        ),
                                      ),
                                      child: Text(
                                        mgmt.isSuspended ? 'Suspended' : 'Active',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: mgmt.isSuspended
                                              ? LearnTzColors.error
                                              : LearnTzColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Activation Code Generator
                    _buildSectionHeader(
                      'DEVICE LINKING & ACTIVATION CODE',
                      'Generate a single-use code for your child to link their phone, tablet or laptop.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LearnTzColors.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (token != null && _secondsRemaining > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: LearnTzColors.primary50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: LearnTzColors.primary200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.timer_outlined,
                                              color: LearnTzColors.primary,
                                              size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'Active Single-Use Code',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: LearnTzColors.primary900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Expires in ${_secondsRemaining ~/ 60}m ${_secondsRemaining % 60}s',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: LearnTzColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: LearnTzColors.primary300,
                                          width: 1.5),
                                    ),
                                    child: Text(
                                      token.tokenCode,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6.0,
                                        color: LearnTzColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    '1. Open LearnTZ on child device\n2. Select "Link My Account"\n3. Enter this 6-character code',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _isGenerating ? null : _handleGenerateCode,
                            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                            label: Text(_secondsRemaining > 0
                                ? 'Generate New Code'
                                : 'Generate Device Activation Code'),
                            style: FilledButton.styleFrom(
                              backgroundColor: LearnTzColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Security & Credentials Control
                    _buildSectionHeader(
                      'CREDENTIALS & ACCESS CONTROL',
                      'Reset learner PIN or temporarily freeze independent child logins.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LearnTzColors.neutral200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Learner PIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    mgmt.hasCredentials
                                        ? '4-6 digit PIN configured'
                                        : 'No PIN set yet',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: _handleResetPin,
                                icon: const Icon(Icons.pin_outlined, size: 18),
                                label: Text(
                                    mgmt.hasCredentials ? 'Reset PIN' : 'Set PIN'),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Suspend Child Access',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Text(
                                    'Freeze child logins without deleting data',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: mgmt.isSuspended,
                                activeThumbColor: LearnTzColors.error,
                                onChanged: (_) =>
                                    _handleToggleSuspension(mgmt.isSuspended),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 3: Registered Devices
                    _buildSectionHeader(
                      'REGISTERED LEARNER DEVICES (${mgmt.devices.length})',
                      'Active devices linked to this learner identity. You can revoke any device at any time.',
                    ),
                    const SizedBox(height: 12),
                    if (mgmt.devices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LearnTzColors.neutral200),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.devices_other,
                                  size: 40, color: LearnTzColors.neutral400),
                              SizedBox(height: 10),
                              Text(
                                'No independent devices registered yet.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: LearnTzColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Generate an activation code above to connect your child\'s device.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final dev in mgmt.devices) ...[
                            _buildDeviceCard(dev),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: LearnTzTypography.caption.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: LearnTzColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: LearnTzTypography.bodySmall.copyWith(
            color: LearnTzColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(LearnerDevice dev) {
    final icon = switch (dev.deviceType) {
      'tablet' => Icons.tablet_mac_rounded,
      'desktop' => Icons.computer_rounded,
      'web' => Icons.language_rounded,
      _ => Icons.phone_android_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dev.isActive
              ? LearnTzColors.neutral200
              : LearnTzColors.neutral300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: dev.isActive
                  ? LearnTzColors.primary50
                  : LearnTzColors.neutral100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: dev.isActive
                  ? LearnTzColors.primary
                  : LearnTzColors.neutral500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dev.deviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: dev.isActive
                            ? LearnTzColors.textPrimary
                            : LearnTzColors.neutral500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dev.isActive
                            ? LearnTzColors.successBg
                            : LearnTzColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dev.isActive ? 'Active' : 'Revoked',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: dev.isActive
                              ? LearnTzColors.success
                              : LearnTzColors.neutral500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last active: ${DateFormat('dd MMM yyyy, HH:mm').format(dev.lastActiveAt)} • Sync: ${DateFormat('dd MMM, HH:mm').format(dev.lastSyncAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (dev.isActive)
            IconButton(
              icon: const Icon(Icons.link_off_rounded,
                  color: LearnTzColors.error, size: 22),
              tooltip: 'Revoke device',
              onPressed: () => _handleRevokeDevice(dev.id, dev.deviceName),
            ),
        ],
      ),
    );
  }
}
