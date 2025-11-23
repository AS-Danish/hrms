import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hrms/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/DashboardPage.dart';
import '../views/OnboardingScreen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _saveUserDataToPrefs(String uid, Map<String, dynamic>? data) async {
    if (data == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final role = data['role'] as String?;
      final onboardingCompleted = data['onboardingCompleted'] as bool? ?? false;

      if (role != null) {
        await prefs.setString('userRole', role);
        await prefs.setString('userId', uid);
        await prefs.setBool('onboardingCompleted', onboardingCompleted);

        final email = FirebaseAuth.instance.currentUser?.email;
        if (email != null) {
          await prefs.setString('userEmail', email);
        }

        debugPrint('User data saved: role=$role, onboarding=$onboardingCompleted for user: $uid');
      }
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        debugPrint('AuthWrapper - Connection State: ${authSnapshot.connectionState}');
        debugPrint('AuthWrapper - Has Data: ${authSnapshot.hasData}');
        debugPrint('AuthWrapper - User: ${authSnapshot.data?.email}');

        // Show loading while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is NOT logged in, show LoginPage
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint('No authenticated user - showing RegisterPage');
          return const LoginPage(); // Use const here
        }

        // User is logged in - fetch their Firestore data
        final uid = authSnapshot.data!.uid;
        debugPrint('User authenticated: $uid');

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {

            // Show loading while fetching data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // If data is fetched successfully
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              final onboardingCompleted = data?['onboardingCompleted'] as bool? ?? false;


              // Save data to SharedPreferences asynchronously
              _saveUserDataToPrefs(uid, data);

              // Check if onboarding is completed
              if (!onboardingCompleted) {
                return const OnboardingScreen();
              } else {
                return const Dashboard();
              }
            }

            // If data fetch failed, show error
            debugPrint('Error loading user data: ${userSnapshot.error}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load user data',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userSnapshot.error?.toString() ?? 'Please contact administrator',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}