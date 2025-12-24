import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserManagementController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var selectedRole = 'employee'.obs;
  var users = <Map<String, dynamic>>[].obs;
  var isLoadingUsers = false.obs;

  final List<String> roles = ['employee', 'hr'];

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  // Fetch all users from Firestore
  Future<void> fetchUsers() async {
    try {
      isLoadingUsers.value = true;
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      users.value = querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      })
          .toList();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch users: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // Create new user with specified role
  Future<void> createUser(String name, String email, String password, String role) async {
    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        "Error",
        "Password must be at least 6 characters",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        "Error",
        "Please enter a valid email",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Store current user
      final currentUser = _auth.currentUser;

      // Create new user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final newUser = userCredential.user;

      if (newUser != null) {
        // Save user data to Firestore
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Update display name
        await newUser.updateDisplayName(name.trim());

        // Sign out the newly created user and sign back in as admin
        await _auth.signOut();
        if (currentUser != null) {
          // Note: You'll need to handle re-authentication of the admin user
          // This is a limitation of Firebase Admin SDK not being available in Flutter
          // Consider using Cloud Functions for better user management
        }

        // Close the dialog
        Get.back();

        Get.snackbar(
          "Success",
          "User created successfully with role: $role",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Clear form
        clearForm();

        // Refresh users list
        await fetchUsers();
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "weak-password":
          message = "Password is too weak";
          break;
        case "email-already-in-use":
          message = "Account already exists with this email";
          break;
        case "invalid-email":
          message = "Invalid email format";
          break;
        case "operation-not-allowed":
          message = "Email/password accounts are not enabled";
          break;
        default:
          message = "Failed to create user: ${e.code}";
      }

      Get.snackbar(
        "Creation Failed",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unexpected error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "User role updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await fetchUsers();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update role: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Toggle user active status
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "User status updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await fetchUsers();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update status: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Note: This only deletes from Firestore
      // To delete from Firebase Auth, you need Firebase Admin SDK or Cloud Functions
      await _firestore.collection('users').doc(userId).delete();

      Get.snackbar(
        "Success",
        "User deleted from database",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await fetchUsers();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete user: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    selectedRole.value = 'employee';
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}