import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    _password.addListener(_measureStrength);
  }

  void _measureStrength() {
    final value = _password.text;
    var score = 0.0;
    if (value.length >= 8) score += .35;
    if (value.length >= 12) score += .2;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += .15;
    if (RegExp(r'[0-9]').hasMatch(value)) score += .15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score += .15;
    setState(() => _strength = score.clamp(0, 1));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await context.read<AuthProvider>().register(
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    if (ok) {
      HapticFeedback.heavyImpact();
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _busy = false;
        _error =
            'We could not create this account. The email may already be used.';
      });
    }
  }

  Color get _strengthColor => _strength < .45
      ? AppTheme.secondary
      : _strength < .75
      ? const Color(0xFFF3A51B)
      : AppTheme.successGreen;

  String get _strengthLabel => _strength == 0
      ? 'Use 8+ characters'
      : _strength < .45
      ? 'Getting there'
      : _strength < .75
      ? 'Good password'
      : 'Strong password';

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Create\naccount.',
    subtitle: 'Build a smarter relationship with the clothes you own.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newUsername],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Enter your email';
              if (!text.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Create password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscure = !_obscure);
                },
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value ?? '').length < 8 ? 'Use at least 8 characters' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: _strength,
                    backgroundColor: AppTheme.borderLight,
                    color: _strengthColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _strengthLabel,
                  key: ValueKey(_strengthLabel),
                  style: TextStyle(
                    fontSize: 12,
                    color: _strengthColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            child: _error == null
                ? const SizedBox(height: 22)
                : Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppTheme.blush,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _busy
                    ? const SizedBox.square(
                        key: ValueKey('busy'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create my wardrobe', key: ValueKey('label')),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'By continuing, you agree to keep DressMate kind, private, and personal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
