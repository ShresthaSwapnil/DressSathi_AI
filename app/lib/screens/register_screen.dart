import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  // Password strength tracking
  double _passwordStrength = 0;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));
    _animController.forward();

    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;
    if (password.length >= 6) strength += 0.3;
    if (password.length >= 10) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() => _passwordStrength = strength.clamp(0.0, 1.0));
  }

  Color _strengthColor() {
    if (_passwordStrength < 0.3) return AppTheme.errorRed;
    if (_passwordStrength < 0.6) return AppTheme.primary;
    return AppTheme.successGreen;
  }

  String _strengthLabel() {
    if (_passwordStrength == 0) return '';
    if (_passwordStrength < 0.3) return 'Weak';
    if (_passwordStrength < 0.6) return 'Fair';
    if (_passwordStrength < 0.8) return 'Good';
    return 'Strong';
  }

  Future<void> _register() async {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        HapticFeedback.vibrate();
        if (mounted) {
          _showErrorSnackBar('Registration failed. Email may already be in use.');
        }
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.offBlack,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        28, 0, 28, bottomInset > 0 ? 20 : 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // ── Back Button ──
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: AppTheme.black,
                                size: 24,
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),

                          // ── Logo ──
                          Image.asset(
                            'assets/logo.png',
                            width: 72,
                            height: 72,
                          ),
                          const SizedBox(height: 32),

                          // ── Heading ──
                          const Text(
                            'Create\naccount.',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.black,
                              height: 1.15,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start building your wardrobe',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.midGray,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.1,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Form ──
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.black,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Email address',
                                  ),
                                  onFieldSubmitted: (_) {
                                    HapticFeedback.selectionClick();
                                    _passwordFocus.requestFocus();
                                  },
                                  onTap: () => HapticFeedback.selectionClick(),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppTheme.lightGray,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    suffixIconConstraints:
                                        const BoxConstraints(
                                      minHeight: 20,
                                      minWidth: 20,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _register(),
                                  onTap: () => HapticFeedback.selectionClick(),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'At least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                // ── Password Strength Bar ──
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            height: 3,
                                            child: LinearProgressIndicator(
                                              value: _passwordStrength,
                                              backgroundColor:
                                                  AppTheme.paleGray,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                _strengthColor(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _strengthLabel(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _strengthColor(),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Create Account Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: authProvider.isLoading
                                  ? Container(
                                      key: const ValueKey('loading'),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMedium,
                                        ),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppTheme.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      key: const ValueKey('button'),
                                      onPressed: _register,
                                      child: const Text('Create account'),
                                    ),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // ── Footer: Sign In link ──
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Already have an account?  ',
                                    style: TextStyle(
                                      color: AppTheme.lightGray,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
