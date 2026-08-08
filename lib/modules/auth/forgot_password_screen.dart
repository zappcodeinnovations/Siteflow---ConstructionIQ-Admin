import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent successfully!")),
      );
    }
  }

  Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
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
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 22,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Enter your registered email and we will send a 6-digit OTP.",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
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
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: buttonTextColor,
                                          ),
                                        )
                                      : Text(
                                          "SEND OTP",
                                          style: TextStyle(
                                            color: buttonTextColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Back to sign in",
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF00529B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
