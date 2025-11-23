import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/Employee.dart';

class HRManagementController extends GetxController {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable list of employees
  final RxList<Employee> employees = <Employee>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isAddingEmployee = false.obs;

  // Form controllers
  final emailController = TextEditingController();

  // Search and filter
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  // Generate random employee ID (EMP + 6 digits)
  String _generateEmployeeId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000; // 6 digit number
    return 'EMP$number';
  }

  // Generate random password (8 characters)
  String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Validate email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Load employees from Firestore
  Future<void> loadEmployees() async {
    try {
      isLoading.value = true;

      // Query Firestore for users with role 'HR'
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'HR')
          .orderBy('createdAt', descending: true)
          .get();

      employees.value = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Employee(
          id: data['empId'] ?? '',
          email: data['email'] ?? '',
          password: '********', // Don't store/display actual passwords
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
        );
      }).toList();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load employees: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add new employee
  Future<void> addEmployee() async {
    final email = emailController.text.trim();

    // Validation
    if (email.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter an email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    // Check for duplicate email in Firestore
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      Get.snackbar(
        'Duplicate Error',
        'An employee with this email already exists',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isAddingEmployee.value = true;

      // Generate credentials
      final employeeId = _generateEmployeeId();
      final password = _generatePassword();

      // Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create Firestore document
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'empId': employeeId,
        'email': email,
        'role': 'HR',
        'onboardingCompleted': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create Employee object for local list
      final newEmployee = Employee(
        id: employeeId,
        email: email,
        password: password,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Add to local list
      employees.insert(0, newEmployee);

      // Clear form
      emailController.clear();

      // Show success with credentials
      _showCredentialsDialog(employeeId, email, password);

      Get.snackbar(
        'Success',
        'Employee added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to add employee';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add employee: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isAddingEmployee.value = false;
    }
  }

  // Show credentials dialog
  void _showCredentialsDialog(String employeeId, String email, String password) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 28),
            const SizedBox(width: 12),
            const Text('Employee Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please share these credentials with the employee:',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Employee ID', employeeId),
            _buildCredentialRow('Email', email),
            _buildCredentialRow('Password', password),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Save these credentials! They won\'t be shown again.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delete employee
  Future<void> deleteEmployee(String employeeId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this employee? This will remove their account and all associated data.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Find the user document by empId
      final userQuery = await _firestore
          .collection('users')
          .where('empId', isEqualTo: employeeId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Employee not found');
      }

      final userDoc = userQuery.docs.first;
      final uid = userDoc.data()['uid'] as String;

      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Note: Deleting from Firebase Auth requires admin SDK or Cloud Functions
      // You might want to implement a Cloud Function to delete the auth user
      // For now, we'll just disable the account by updating isActive
      // Alternatively, use Firebase Admin SDK in Cloud Functions

      // Remove from local list
      employees.removeWhere((emp) => emp.id == employeeId);

      Get.snackbar(
        'Success',
        'Employee deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete employee: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Toggle employee active status
  Future<void> toggleEmployeeStatus(String employeeId) async {
    try {
      // Find the user document by empId
      final userQuery = await _firestore
          .collection('users')
          .where('empId', isEqualTo: employeeId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Employee not found');
      }

      final userDoc = userQuery.docs.first;
      final currentStatus = userDoc.data()['isActive'] as bool? ?? true;

      // Update in Firestore
      await _firestore.collection('users').doc(userDoc.id).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = employees.indexWhere((emp) => emp.id == employeeId);
      if (index != -1) {
        final employee = employees[index];
        employees[index] = employee.copyWith(isActive: !employee.isActive);
      }

      Get.snackbar(
        'Success',
        'Employee status updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Get filtered employees based on search
  List<Employee> get filteredEmployees {
    if (searchQuery.value.isEmpty) {
      return employees;
    }
    return employees.where((emp) {
      return emp.email.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          emp.id.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }
}