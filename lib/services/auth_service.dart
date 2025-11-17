import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save login state
  Future<void> saveLoginState(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("uid", uid);
  }

  // Clear login state
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uid");
  }

  // Check state
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("uid");
  }

  // Firebase getter
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authChanges => _auth.authStateChanges();
}