import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save login state with role
  Future<void> saveLoginState(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("uid", uid);
    await prefs.setString("role", role); // Add this line
  }

  // Clear login state
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uid");
    await prefs.remove("role"); // Add this line
  }

  // Check state
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("uid");
  }

  // Get saved role
  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  // Firebase getter
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authChanges => _auth.authStateChanges();
}