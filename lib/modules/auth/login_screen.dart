import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loginController.errorMessage ?? "Login Failed"),
        ),
      );
    }
  }

  Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.none,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: isDark ? Colors.white : Colors.grey.shade600),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white : Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.white : const Color(0xFF00529B), width: 1.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
    final bgColor = isDark ? const Color(0xFF00529B) : const Color(0xFFF0F4F8);
    final cardColor = isDark ? Colors.transparent : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final buttonColor = isDark ? const Color(0xFFFFC000) : const Color(0xFF00529B);
    final buttonTextColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (isDark)
            Positioned.fill(
              child: ClipRRect(
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 150,
                          height: 300,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 50,
                      top: -100,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 100,
                          height: 400,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    const Spacer(),

                    /// LOGO
                    if (!isDark)
                      Container(
                        height: 80,
                        width: 80,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.asset("assets/images/app_icon.png"),
                      )
                    else
                      Image.asset("assets/images/app_icon.png", height: 80),

                    const SizedBox(height: 20),

                    Text(
                      "Sign in to Euroside",
                      style: TextStyle(
                        fontSize: 22,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Welcome back! Please sign in to continue",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 14),
                    ),

                    const SizedBox(height: 30),

                    /// FORM CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        padding: EdgeInsets.all(isDark ? 0 : 24),
                        decoration: isDark
                            ? null
                            : BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "EMAIL ADDRESS",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                context: context,
                                controller: emailController,
                                hint: "Enter your email address",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                isDark: isDark,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your email";
                                  }
                                  if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                    return "Please enter a valid email address";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "PASSWORD",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                context: context,
                                controller: passwordController,
                                hint: "Enter your password",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isDark: isDark,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your password";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) {
                                            setState(() {
                                              _rememberMe = val ?? false;
                                            });
                                          },
                                          side: BorderSide(color: isDark ? Colors.white70 : Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Remember me",
                                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/forgot_password');
                                    },
                                    child: Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF00529B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              AnimatedBuilder(
                                animation: _loginController,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _loginController.isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _loginController.isLoading
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: buttonTextColor,
                                              ),
                                            )
                                          : Text(
                                              "SIGN IN",
                                              style: TextStyle(
                                                color: buttonTextColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: Text(
                                      "Sign up",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF00529B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "© 2026 Euroside Construction",
                        style: TextStyle(color: isDark ? Colors.white.withOpacity(.7) : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
