import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hrms/auth/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms/auth/login_page.dart';
import 'package:hrms/components/NavBar.dart';
import '../views/DashboardPage.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _getUserRoleAndSave(String uid) async {
    try {
      // Add timeout and retry logic
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;

        if (role != null) {
          // Save role to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', role);
          await prefs.setString('userId', uid);

          // Also save user email for reference
          final email = FirebaseAuth.instance.currentUser?.email;
          if (email != null) {
            await prefs.setString('userEmail', email);
          }

          debugPrint('User role saved: $role for user: $uid');
          return role;
        } else {
          debugPrint('Role field is null in user document');
        }
      } else {
        debugPrint('User document does not exist for uid: $uid');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, fetch role and redirect
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String?>(
            future: _getUserRoleAndSave(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              // Show loading while fetching role
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If role is fetched successfully
              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                // Navigate to dashboard with role
                return Dashboard();
              }

              // If role fetch failed, show error
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
                      const Text(
                        'Please contact administrator',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Otherwise show login page
        return RegisterPage();
      },
    );
  }
}