import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _headerFade;
  late Animation<double> _cardSlide;
  late Animation<double> _formFade;

  // Focus tracking for animated prefix icons
  bool _emailHasFocus = false;
  bool _passwordHasFocus = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _formFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _animController.forward();

    _emailFocus.addListener(() {
      setState(() => _emailHasFocus = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordHasFocus = _passwordFocus.hasFocus);
    });
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

  Future<void> _login() async {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
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
          _showErrorSnackBar('Invalid email or password');
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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
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
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = screenHeight * 0.38;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return SingleChildScrollView(
              child: SizedBox(
                height: math.max(screenHeight, 700),
                child: Stack(
                  children: [
                    // ── Dark Gradient Header ──
                    FadeTransition(
                      opacity: _headerFade,
                      child: Container(
                        height: headerHeight,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0A0A0F),
                              Color(0xFF0D1B3E),
                              Color(0xFF142850),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Subtle decorative gradient orb
                            Positioned(
                              right: -60,
                              top: -30,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primary.withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -40,
                              bottom: 20,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.secondary.withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Back button + Logo row
                            Positioned(
                              top: topPadding + 12,
                              left: 20,
                              right: 20,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.pop(context);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: AppTheme.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'DressMate',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Heading text
                            Positioned(
                              left: 28,
                              right: 28,
                              bottom: 70,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome\nback.',
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.white,
                                      height: 1.1,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Sign in to continue your style journey',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.white.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── White Form Card ──
                    Positioned(
                      top: headerHeight - 32,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Transform.translate(
                        offset: Offset(0, _cardSlide.value),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          child: FadeTransition(
                            opacity: _formFade,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Form ──
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        // Email Field
                                        _buildInputField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          hint: 'Email address',
                                          icon: Icons.mail_outline_rounded,
                                          hasFocus: _emailHasFocus,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) {
                                            HapticFeedback.selectionClick();
                                            _passwordFocus.requestFocus();
                                          },
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
                                        const SizedBox(height: 14),

                                        // Password Field
                                        _buildInputField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          hint: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          hasFocus: _passwordHasFocus,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _login(),
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                key: ValueKey(_obscurePassword),
                                                color: _passwordHasFocus
                                                    ? AppTheme.primary
                                                    : AppTheme.lightGray,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Enter your password';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: GestureDetector(
                                        onTap: () => HapticFeedback.selectionClick(),
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ── Sign In Button ──
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: authProvider.isLoading
                                          ? Container(
                                              key: const ValueKey('loading'),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppTheme.primary,
                                                    Color(0xFF4D9BFF),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  AppTheme.radiusPill,
                                                ),
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      AppTheme.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              key: const ValueKey('button'),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppTheme.primary,
                                                    Color(0xFF4D9BFF),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  AppTheme.radiusPill,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primary
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: _login,
                                                  borderRadius: BorderRadius.circular(
                                                    AppTheme.radiusPill,
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Sign In',
                                                      style: TextStyle(
                                                        color: AppTheme.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ── Divider ──
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: AppTheme.paleGray,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'or continue with',
                                          style: TextStyle(
                                            color: AppTheme.lightGray,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: AppTheme.paleGray,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // ── Social Buttons ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildSocialButton(
                                        icon: Icons.g_mobiledata_rounded,
                                        label: 'Google',
                                      ),
                                      const SizedBox(width: 14),
                                      _buildSocialButton(
                                        icon: Icons.apple_rounded,
                                        label: 'Apple',
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // ── Footer: Sign Up link ──
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (context, animation, secondaryAnimation) =>
                                                    const RegisterScreen(),
                                            transitionsBuilder:
                                                (context, animation, secondaryAnimation, child) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration:
                                                const Duration(milliseconds: 300),
                                          ),
                                        );
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: RichText(
                                          text: const TextSpan(
                                            text: "Don't have an account?  ",
                                            style: TextStyle(
                                              color: AppTheme.midGray,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Sign up',
                                                style: TextStyle(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).padding.bottom + 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Custom Input Field with animated prefix icon ──
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool hasFocus,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: hasFocus ? AppTheme.primary.withValues(alpha: 0.03) : AppTheme.offWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus ? AppTheme.primary.withValues(alpha: 0.35) : AppTheme.paleGray,
          width: hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.lightGray,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(hasFocus),
                color: hasFocus ? AppTheme.primary : AppTheme.lightGray,
                size: 20,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 20,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 20,
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.8),
        ),
        onFieldSubmitted: onFieldSubmitted,
        onTap: () => HapticFeedback.selectionClick(),
        validator: validator,
      ),
    );
  }

  // ── Social Button ──
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        width: 140,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.paleGray, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppTheme.charcoal),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
