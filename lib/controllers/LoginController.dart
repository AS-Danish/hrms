import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createAccount(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return "Account Created";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "weak-password":
          return "Weak Password";
        case "email-already-in-use":
          return "Account Already Exists";
        case "invalid-email":
          return "Invalid Email Format";
        default:
          return "Auth Error: ${e.code}";
      }
    } catch (e) {
      return "Unexpected Error";
    }
  }

  Future<String> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "User Not Found";
        case "wrong-password":
          return "Wrong Password";
        default:
          return "Auth Error: ${e.code}";
      }
    } catch (_) {
      return "Unexpected Error";
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
