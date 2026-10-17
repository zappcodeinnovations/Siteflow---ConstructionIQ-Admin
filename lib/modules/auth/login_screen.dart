import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _brandBlue = Color(0xFF075AA6);
  static const _accentOrange = Color(0xFFF6A800);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final LoginController _loginController = LoginController();
  final _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remember_email');
    final savedPassword = prefs.getString('remember_password');
    if (!mounted || savedEmail == null || savedEmail.isEmpty) return;
    setState(() {
      emailController.text = savedEmail;
      passwordController.text = savedPassword ?? '';
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final success = await _loginController.login(email, password);
    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remember_email', email);
        await prefs.setString('remember_password', password);
      } else {
        await prefs.remove('remember_email');
        await prefs.remove('remember_password');
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_loginController.errorMessage ?? 'Login failed')),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    required bool compact,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF9FBFE),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF97A5B8), fontSize: 12),
      errorStyle: const TextStyle(fontSize: 9, height: .85),
      contentPadding: EdgeInsets.symmetric(vertical: compact ? 10 : 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2580D2), size: 19),
      prefixIconConstraints: const BoxConstraints(minWidth: 42),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCE5F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCE5F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _brandBlue, width: 1.4),
      ),
    );
  }

  Widget _loginCard({required bool compact}) {
    final gap = compact ? 7.0 : 10.0;
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x33094C86),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 18,
          compact ? 11 : 15,
          compact ? 14 : 18,
          compact ? 9 : 12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: const Color(0xFF12213A),
                    fontSize: compact ? 21 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'Sign in to your Euroside admin account\nto continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF718097),
                    fontSize: compact ? 9.5 : 10.5,
                    height: 1.25,
                  ),
                ),
              ),
              SizedBox(height: gap),
              const Text(
                'Email Address',
                style: TextStyle(
                  color: Color(0xFF27364C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Color(0xFF17253B), fontSize: 13),
                decoration: _fieldDecoration(
                  hint: 'Enter your email',
                  icon: Icons.mail_outline_rounded,
                  compact: compact,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: gap),
              const Text(
                'Password',
                style: TextStyle(
                  color: Color(0xFF27364C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                style: const TextStyle(color: Color(0xFF17253B), fontSize: 13),
                decoration: _fieldDecoration(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  compact: compact,
                  suffixIcon: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(
                      () => obscurePassword = !obscurePassword,
                    ),
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF8290A4),
                      size: 18,
                    ),
                  ),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Please enter your password'
                    : null,
              ),
              SizedBox(height: compact ? 1 : 3),
              Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: _brandBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      onChanged: (value) => setState(
                        () => _rememberMe = value ?? false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Remember me',
                    style: TextStyle(color: Color(0xFF485971), fontSize: 10.5),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/forgot_password'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: _brandBlue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 3 : 6),
              AnimatedBuilder(
                animation: _loginController,
                builder: (context, _) => SizedBox(
                  width: double.infinity,
                  height: compact ? 42 : 46,
                  child: ElevatedButton(
                    onPressed:
                        _loginController.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      elevation: 1,
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _brandBlue.withValues(alpha: .65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loginController.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 9),
                              Icon(Icons.arrow_forward_rounded, size: 17),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFDDE5EF))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: const Color(0xFF9AA6B6),
                        fontSize: compact ? 7 : 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFDDE5EF))),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: Color(0xFF8793A4), fontSize: 9.5),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.only(left: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      'Contact Admin',
                      style: TextStyle(
                        color: _brandBlue,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader({required bool compact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .93),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset('assets/images/app_icon.png'),
        ),
        const SizedBox(width: 8),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EUROSIDE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              'Construction IQ',
              style: TextStyle(
                color: Color(0xFFE6EEF8),
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final compact = height < 690 || width < 350;
            final heroHeight = (height * (compact ? .37 : .40))
                .clamp(compact ? 178.0 : 220.0, compact ? 235.0 : 310.0);
            final cardTop = heroHeight - (compact ? 20 : 26);
            final horizontal = width >= 600 ? width * .20 : 16.0;
            final cardWidth = (width - (horizontal * 2)).clamp(0.0, 440.0);

            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: heroHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/login_bg.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.35),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xB3122538),
                                Color(0x4D122538),
                                Color(0x11122538),
                              ],
                              stops: [0, .56, 1],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 17 : 22,
                            compact ? 11 : 16,
                            16,
                            compact ? 24 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _brandHeader(compact: compact),
                              const Spacer(),
                              Container(
                                width: 32,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _accentOrange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: 'Smarter\nSites\n'),
                                    TextSpan(
                                      text: 'Stronger\nTomorrow',
                                      style: TextStyle(color: _accentOrange),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  height: .93,
                                  fontSize: compact ? 18 : 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track. Build. Deliver.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .88),
                                  fontSize: compact ? 8.5 : 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: -height * .12,
                    right: -height * .20,
                    bottom: -height * .25,
                    height: height * .31,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -height * .10,
                    right: -height * .18,
                    bottom: -height * .27,
                    height: height * .30,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _brandBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: cardTop,
                    left: horizontal,
                    right: horizontal,
                    bottom: height >= 620 ? 48 : 6,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: cardWidth,
                          child: _loginCard(compact: compact),
                        ),
                      ),
                    ),
                  ),
                  if (height >= 620)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 15,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _footerBadge(Icons.verified_user_outlined, 'SAFE SITES'),
                          _footerBadge(Icons.groups_rounded, 'STRONGER PEOPLE'),
                          _footerBadge(Icons.bar_chart_rounded, 'HIGHER STANDARDS'),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _footerBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _accentOrange, size: 17),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF32465F),
            fontSize: 8.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
