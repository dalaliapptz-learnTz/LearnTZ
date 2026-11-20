import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/country_configuration.dart';
import '../../core/config/country_providers.dart';
import '../../core/design_system/components/app_brand_logo.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.signIn(email: _email.text, password: _password.text);
      if (mounted) context.go(_safeNextPath(widget.next));
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = ref.watch(selectedCountryProvider);
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }

    return AuthFormFrame(
      title: l10n.signInTitle,
      description: l10n.signInDescription,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                decoration: _fieldDecoration(
                  label: l10n.emailLabel,
                  icon: Icons.mail_outline_rounded,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                decoration: _fieldDecoration(
                  label: l10n.passwordLabel,
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => _required(value, l10n),
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F4C81),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.forgotPasswordAction),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.signInAction),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 18),
        Material(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const Key('student-learner-sign-in-button'),
            onTap: () => context.go(AppRoutes.learnerLogin),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student / Learner Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sign in with your Learner ID & PIN',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFF0F4C81),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AuthLink(
          text: l10n.noAccountPrompt(country.productName),
          label: l10n.createAccountAction,
          onPressed: () => context.go(AppRoutes.signUp),
        ),
      ],
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  String? _countryCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final response = await repository.signUp(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        countryCode: _countryCode!,
      );
      if (!mounted) return;
      if (response.session != null) {
        context.go(AppRoutes.account);
      } else {
        context.go(
          Uri(
            path: AppRoutes.verifyEmail,
            queryParameters: {'email': _email.text.trim()},
          ).toString(),
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = ref.watch(selectedCountryProvider);
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    return ref
        .watch(countriesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AuthFormFrame(
            title: l10n.signUpTitle,
            description: l10n.signUpDescription(country.productName),
            children: [
              AuthInlineMessage(
                message: error is CountriesBackendNotConfiguredException
                    ? l10n.countriesNotConfigured(country.productName)
                    : l10n.requestFailed,
                isError: true,
              ),
              TextButton(
                onPressed: () => ref.invalidate(countriesProvider),
                child: Text(l10n.tryAgainAction),
              ),
            ],
          ),
          data: (countries) => _buildForm(context, l10n, countries),
        );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    List<CountryConfiguration> countries,
  ) {
    final country = ref.watch(selectedCountryProvider);
    if (_countryCode == null && countries.isNotEmpty) {
      _countryCode = countries
          .firstWhere(
            (c) => c.isDefault,
            orElse: () => countries.first,
          )
          .countryCode;
    }
    return AuthFormFrame(
      title: l10n.signUpTitle,
      description: l10n.signUpDescription(country.productName),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _countryCode,
                decoration: InputDecoration(labelText: l10n.countryTitle),
                items: [
                  for (final country in countries)
                    DropdownMenuItem(
                      value: country.countryCode,
                      child: Text(country.displayName),
                    ),
                ],
                onChanged: (value) => setState(() => _countryCode = value),
                validator: (value) => value == null ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) => _validateName(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => _validatePassword(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    value != _password.text ? l10n.passwordsDoNotMatch : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.createAccountAction,
          onPressed: _isSubmitting ? null : _submit,
        ),
        AuthLink(
          text: l10n.haveAccountPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  String? _error;
  bool _isSending = false;
  bool _sentAgain = false;

  Future<void> _resend() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await repository.resendVerificationEmail(widget.email);
      if (mounted) setState(() => _sentAgain = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    return AuthFormFrame(
      title: l10n.verifyEmailTitle,
      description: l10n.verifyEmailDescription(widget.email),
      children: [
        if (_sentAgain) AuthInlineMessage(message: l10n.verificationResent),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        AppButton(
          label: l10n.resendVerificationAction,
          onPressed: _isSending || widget.email.isEmpty ? null : _resend,
        ),
        AuthLink(
          text: l10n.alreadyVerifiedPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _requestSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.requestPasswordReset(_email.text);
      if (mounted) setState(() => _requestSent = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }

    return AuthFormFrame(
      title: l10n.forgotPasswordTitle,
      description: l10n.forgotPasswordDescription,
      children: [
        if (_requestSent)
          AuthInlineMessage(message: l10n.passwordResetEmailSent)
        else ...[
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) => _validateEmail(value, l10n),
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
          if (_error != null)
            AuthInlineMessage(message: _error!, isError: true),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.sendResetLinkAction,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
        AuthLink(
          text: l10n.rememberPasswordPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _updated = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.updatePassword(_password.text);
      if (mounted) setState(() => _updated = true);
      ref.read(passwordRecoveryModeProvider.notifier).complete();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    final isRecoverySession = ref.watch(passwordRecoveryModeProvider);

    return AuthFormFrame(
      title: l10n.passwordRecoveryTitle,
      description: isRecoverySession
          ? l10n.passwordRecoveryDescription
          : l10n.openResetLinkFirst,
      children: [
        if (_updated)
          AuthInlineMessage(message: l10n.passwordUpdated)
        else if (isRecoverySession) ...[
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(labelText: l10n.newPasswordLabel),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validatePassword(value, l10n),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordLabel,
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value != _password.text ? l10n.passwordsDoNotMatch : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          if (_error != null)
            AuthInlineMessage(message: _error!, isError: true),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.updatePasswordAction,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
        AuthLink(
          text: '',
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class AuthCallbackScreen extends ConsumerWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return const AuthBackendNotice();
    if (client.auth.currentSession != null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AuthFormFrame(
      title: l10n.emailLinkProcessedTitle,
      description: l10n.emailLinkProcessedDescription,
      children: [
        AppButton(
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class AuthFormFrame extends StatelessWidget {
  const AuthFormFrame({
    required this.title,
    required this.description,
    required this.children,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 24 : 44,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top brand accent strip
                  Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F4C81), Color(0xFF15803D)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 20 : 32,
                      isMobile ? 24 : 32,
                      isMobile ? 20 : 32,
                      isMobile ? 24 : 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: AppBrandLogo(height: 46),
                          ),
                        ),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        ...children,
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
}

class AuthBackendNotice extends ConsumerWidget {
  const AuthBackendNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final country = ref.watch(selectedCountryProvider);
    return AuthFormFrame(
      title: l10n.authNotConfiguredTitle,
      description: l10n.authNotConfiguredDescription(country.productName),
      children: [
        AuthInlineMessage(message: l10n.authNotConfiguredAction, isError: true),
      ],
    );
  }
}

class AuthInlineMessage extends StatelessWidget {
  const AuthInlineMessage({
    required this.message,
    this.isError = false,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor =
        isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  const AuthLink({
    required this.text,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String text;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (text.isNotEmpty) Text(text),
        TextButton(onPressed: onPressed, child: Text(label)),
      ],
    );
  }
}

String? _required(String? value, AppLocalizations l10n) {
  return value == null || value.trim().isEmpty ? l10n.requiredField : null;
}

String? _validateName(String? value, AppLocalizations l10n) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return l10n.requiredField;
  return name.length <= 120 ? null : l10n.nameTooLong;
}

String? _validateEmail(String? value, AppLocalizations l10n) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.requiredField;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return l10n.invalidEmail;
  }
  return null;
}

String? _validatePassword(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.requiredField;
  if (value.length < 8) return l10n.passwordMinimumLength;
  return null;
}

String _safeNextPath(String? path) {
  if (path == null || path.isEmpty) return AppRoutes.account;
  if (path.startsWith('/') && !path.startsWith('//')) {
    return path;
  }
  return AppRoutes.account;
}
