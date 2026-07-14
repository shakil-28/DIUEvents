import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/admin_home_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart'; // IMPORTED: Needed for the sign-out route reset
import '../screens/sign_up_screen.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static const String _serverClientId = "618114582605-92lhjt67kbt4hi8lbs5egpg15jk9fkds.apps.googleusercontent.com";
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Sign in with Email & Password
  static Future<void> signInWithEmailPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!context.mounted) return;

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          final role = data != null && data.containsKey('role') ? data['role'] : 'student';

          if (role == 'admin') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Admin user, navigating to Admin Home")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User exists, navigating to Home")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          // Handle case where user is authenticated but no document exists in Firestore
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SignUpScreen(user: user)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    }
  }

  /// Google Sign-In (Updated for google_sign_in v7+)
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.initialize(serverClientId: _serverClientId);

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return; // Flow cancelled by user

      final List<String> scopes = ['email', 'profile'];
      final authorizedUser = await googleUser.authorizationClient.authorizeScopes(scopes);
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: authorizedUser.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!context.mounted) return;

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          final role = data != null && data.containsKey('role') ? data['role'] : 'student';

          if (role == 'admin') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Admin user, navigating to Admin Home")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User exists, navigating to Home")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New user, navigating to Signup")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SignUpScreen(user: user)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send reset link')),
        );
      }
    }
  }

  /// Get Current User
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign Out & Route Back to Login Page
  static Future<void> signOut(BuildContext context) async {
    try {
      // 1. Clear session data from both platforms
      await _auth.signOut();
      await _googleSignIn.initialize(serverClientId: _serverClientId);
      await _googleSignIn.signOut();

      // 2. Safeguard async frame transition
      if (!context.mounted) return;

      // 3. Clear whole route stack and push LoginScreen to root
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing auth session: $e')),
        );
      }
    }
  }
}