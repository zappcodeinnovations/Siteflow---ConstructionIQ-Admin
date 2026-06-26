import 'dart:ui';

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
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(.12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),

        prefixIcon: Icon(icon, color: Colors.white),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.55),
                    Colors.black.withOpacity(.35),
                    Colors.black.withOpacity(.85),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: size.height,
                child: Column(
                  children: [
                    const Spacer(),

                    /// LOGO
                    // Container(
                    //   height: 120,
                    //   width: 120,
                    //   padding: const EdgeInsets.all(18),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     shape: BoxShape.circle,
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(.25),
                    //         blurRadius: 25,
                    //         offset: const Offset(0, 10),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Image.asset("assets/images/Euroside_Logo.png"),
                    // ),

                    const SizedBox(height: 25),

                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "EuroSide Admin Panel",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),

                    const SizedBox(height: 40),

                    /// GLASS CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color.fromARGB(50, 255, 255, 255)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  buildTextField(
                                    controller: emailController,
                                    hint: "Email Address",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
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

                                  buildTextField(
                                    controller: passwordController,
                                    hint: "Password",
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "Please enter your password";
                                      }
                                      return null;
                                    },
                                  ),

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Colors.white , fontSize: 13),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                AnimatedBuilder(
                                  animation: _loginController,
                                  builder: (context, child) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 58,
                                      child: ElevatedButton(
                                        onPressed: _loginController.isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 100, 23, 235), // Light purple
                                          elevation: 8,
                                          shadowColor: const Color.fromARGB(255, 6, 14, 232),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                        child: _loginController.isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.black,
                                                    ),
                                              )
                                            : const Text(
                                                "LOGIN",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "© 2026 Euroside Construction",
                        style: TextStyle(color: Colors.white.withOpacity(.7)),
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
