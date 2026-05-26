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
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

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
                          const Spacer(flex: 2),

                          // ── Logo ──
                          Image.asset(
                            'assets/logo.png',
                            width: 72,
                            height: 72,
                          ),
                          const SizedBox(height: 32),

                          // ── Heading ──
                          const Text(
                            'Welcome\nback.',
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
                            'Sign in to your wardrobe',
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
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppTheme.lightGray,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minHeight: 20,
                                      minWidth: 20,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _login(),
                                  onTap: () => HapticFeedback.selectionClick(),
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

                          const SizedBox(height: 28),

                          // ── Sign In Button ──
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
                                      onPressed: _login,
                                      child: const Text('Sign in'),
                                    ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // ── Footer: Sign Up link ──
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Don't have an account?  ",
                                    style: TextStyle(
                                      color: AppTheme.lightGray,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign up',
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
