import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hrms/auth/register_page.dart';
import 'package:hrms/controllers/LoginController.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final LoginController loginController = Get.put(LoginController());
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF3B82F6), // Bright blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Company Branding at Top
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Color(0xFF3B82F6),
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Company Name
                      const Text(
                        "HRMS Pro",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        "Human Resource Management System",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Login Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: 400,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              "Sign in to continue",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          _AnimatedTextField(
                            controller: loginController.emailController,
                            hintText: "Email address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            delay: 200,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _AnimatedTextField(
                            controller: loginController.passwordController,
                            hintText: "Password",
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            delay: 300,
                          ),

                          const SizedBox(height: 32),

                          // Login Button
                          Obx(() => _PremiumButton(
                            onPressed: loginController.isLoading.value
                                ? null
                                : () async {
                              final email = loginController.emailController.text;
                              final password = loginController.passwordController.text;
                              await loginController.login(email, password);
                            },
                            isLoading: loginController.isLoading.value,
                          )),

                          const SizedBox(height: 24),

                          // Register Link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Not registered yet? ",
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    // Navigate to registration page
                                    // Get.toNamed('/register');
                                    Get.to(RegisterPage());
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: const Text(
                                      "Register now",
                                      style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int delay;

  const _AnimatedTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.delay = 0,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: _isFocused
                  ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: const Color(0xFF94A3B8).withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  widget.icon,
                  color: _isFocused
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PremiumButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: widget.onPressed,
            child: widget.isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              "Sign In",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}