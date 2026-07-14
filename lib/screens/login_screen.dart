import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth.dart';
import 'components/button.dart';
import 'components/customPasswordField.dart';
import 'components/emailField.dart';
import 'forget_screen.dart';
import 'sign_up_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    await AuthService.signInWithEmailPassword(context, email, password);

    if (!mounted) return;
    final currentUser = AuthService.getCurrentUser();
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc['role'];

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUpScreen(user: currentUser)),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    await AuthService.signInWithGoogle(context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background Aesthetic Decorator Gradient
          Positioned(
            top: -mediaQuery.size.height * 0.15,
            right: -mediaQuery.size.width * 0.2,
            child: Container(
              width: mediaQuery.size.width * 0.7,
              height: mediaQuery.size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width * 0.06,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: mediaQuery.size.height * 0.08,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.04),
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Sign in to manage your events and registrations seamlessly.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF757575),
                        ),
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.04),

                      // Input Fields Group
                      EmailTextField(controller: emailController),
                      const SizedBox(height: 20.0),
                      PasswordTextField(controller: passwordController),
                      
                      // Utilities Row
                      const SizedBox(height: 8.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.03),

                      // Action Button Pipelines
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            )
                          : Column(
                              children: [
                                CustomButton(
                                  label: 'Sign In',
                                  onPressed: _handleSignIn,
                                  color: const Color(0xFF1A1A1A),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  elevation: 2.0,
                                  height: 52,
                                ),
                                SizedBox(height: mediaQuery.size.height * 0.03),
                                
                                // Elegant Split Divider
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        'OR',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF9E9E9E),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                                  ],
                                ),
                                SizedBox(height: mediaQuery.size.height * 0.03),
                                
                                // Social Framework Auth Node
                                CustomButton(
                                  label: "Continue with Google",
                                  onPressed: _handleGoogleSignIn,
                                  color: Colors.white,
                                  textStyle: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  height: 52,
                                  elevation: 0,
                                  leading: SvgPicture.asset(
                                    'assets/images/google_logo.svg',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: mediaQuery.size.height * 0.04),

                      // Navigation Invitation Pipeline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF757575)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
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
          ),
        ],
      ),
    );
  }
}