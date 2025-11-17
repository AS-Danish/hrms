import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hrms/views/DashboardPage.dart';

import '../auth/login_page.dart';
import '../services/auth_service.dart';
import '../components/NavBar.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  var isLoading = false.obs;

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

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter email and password",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _authService.saveLoginState(cred.user!.uid);

      Get.snackbar(
        "Success",
        "Login Successful",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAll(() => Dashboard());

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "user-not-found":
          message = "User Not Found";
          break;
        case "wrong-password":
          message = "Wrong Password";
          break;
        case "invalid-email":
          message = "Invalid Email Format";
          break;
        case "user-disabled":
          message = "This account has been disabled";
          break;
        default:
          message = "Auth Error: ${e.code}";
      }

      Get.snackbar(
        "Login Failed",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unexpected Error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _authService.clearLoginState();
    Get.offAll(() => LoginPage());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}