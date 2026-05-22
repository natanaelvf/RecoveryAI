import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// Login screen — email/password + Google native sign-in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Client-side password strength validation (min 8 chars, 1 uppercase, 1 digit).
  String? _validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }
    return null;
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    // For registration, enforce stricter password requirements client-side.
    if (_isRegistering) {
      final error = _validatePassword(password);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    final auth = ref.read(authProvider);
    if (_isRegistering) {
      await auth.signUpWithEmail(email, password);
    } else {
      await auth.signInWithEmail(email, password);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authProvider).signInWithGoogle();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your email address first'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }
    await ref.read(authProvider).resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final authState = ref.watch(authProvider).state;

    // Show error snackbar when auth state has an error.
    ref.listen(authProvider, (previous, next) {
      final msg = next.state.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: msg.contains('Check your email') || msg.contains('reset link')
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        );
        next.clearError();
      }
    });

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.accentPrimaryMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.phone_missed_rounded,
                      color: colors.accentPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.displaySmall,
                      children: [
                        TextSpan(text: l10n.loginTitle),
                        TextSpan(
                          text: l10n.loginTitleHighlight,
                          style: TextStyle(color: colors.accentPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // ─── Google sign-in button ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      label: Text(l10n.loginGoogleButton),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── OR divider ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.loginOrDivider,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Email field ─────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loginEmailLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: l10n.loginEmailPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Password field ──────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loginPasswordLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleEmailAuth(),
                        decoration: InputDecoration(
                          hintText: l10n.loginPasswordPlaceholder,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colors.textTertiary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),
                      if (_isRegistering) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.loginPasswordRequirements,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Submit button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleEmailAuth,
                      child: authState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textInverse,
                              ),
                            )
                          : Text(
                              _isRegistering
                                  ? l10n.loginSignUp
                                  : l10n.loginSubmit,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Toggle login / register ─────────────────────
                  TextButton(
                    onPressed: () {
                      setState(() => _isRegistering = !_isRegistering);
                    },
                    child: Text(
                      _isRegistering
                          ? l10n.loginBackToSignIn
                          : l10n.loginCreateAccount,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),

                  // ─── Forgot password (only in login mode) ───────
                  if (!_isRegistering)
                    TextButton(
                      onPressed: authState.isLoading ? null : _handleForgotPassword,
                      child: Text(
                        l10n.loginForgot,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textTertiary,
                        ),
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
