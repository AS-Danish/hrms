import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var currentStep = 0.obs;
  var isLoading = false.obs;

  // Personal Details Controllers
  final fullNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();

  // Verification Details Controllers
  final panController = TextEditingController();
  final aadharController = TextEditingController();
  final passportController = TextEditingController();

  // Bank Details Controllers
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscController = TextEditingController();
  final accountHolderNameController = TextEditingController();

  // Employment Details Controllers
  final departmentController = TextEditingController();
  final designationController = TextEditingController();
  final joiningDateController = TextEditingController();
  final employeeIdController = TextEditingController();

  var selectedGender = ''.obs;

  void nextStep() {
    if (currentStep.value < 3) {
      if (validateCurrentStep()) {
        currentStep.value++;
      }
    } else {
      completeOnboarding();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 0: // Personal Details
        if (fullNameController.text.isEmpty ||
            dateOfBirthController.text.isEmpty ||
            selectedGender.value.isEmpty ||
            phoneController.text.isEmpty ||
            addressController.text.isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please fill in all required personal details",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        break;

      case 1: // Verification Details
        if (panController.text.isEmpty || aadharController.text.isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please fill in PAN and Aadhar details",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        break;

      case 2: // Bank Details
        if (bankNameController.text.isEmpty ||
            accountNumberController.text.isEmpty ||
            ifscController.text.isEmpty ||
            accountHolderNameController.text.isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please fill in all bank details",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        break;

      case 3: // Employment Details
        if (departmentController.text.isEmpty ||
            designationController.text.isEmpty ||
            joiningDateController.text.isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please fill in all employment details",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> completeOnboarding() async {
    if (!validateCurrentStep()) return;

    isLoading.value = true;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final onboardingData = {
        'personalDetails': {
          'fullName': fullNameController.text.trim(),
          'dateOfBirth': dateOfBirthController.text.trim(),
          'gender': selectedGender.value,
          'phoneNumber': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'zipCode': zipCodeController.text.trim(),
        },
        'verificationDetails': {
          'panNumber': panController.text.trim(),
          'aadharNumber': aadharController.text.trim(),
          'passportNumber': passportController.text.trim(),
        },
        'bankDetails': {
          'bankName': bankNameController.text.trim(),
          'accountNumber': accountNumberController.text.trim(),
          'ifscCode': ifscController.text.trim(),
          'accountHolderName': accountHolderNameController.text.trim(),
        },
        'employmentDetails': {
          'department': departmentController.text.trim(),
          'designation': designationController.text.trim(),
          'joiningDate': joiningDateController.text.trim(),
          'employeeId': employeeIdController.text.trim(),
        },
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).update(onboardingData);

      Get.snackbar(
        "Success",
        "Onboarding completed successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // The StreamBuilder in AuthWrapper will automatically detect the change
      // and navigate to Dashboard. No need to manually navigate.

    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to complete onboarding: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /*@override
  void onClose() {
    fullNameController.dispose();
    dateOfBirthController.dispose();
    genderController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    panController.dispose();
    aadharController.dispose();
    passportController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    accountHolderNameController.dispose();
    departmentController.dispose();
    designationController.dispose();
    joiningDateController.dispose();
    employeeIdController.dispose();
    super.onClose();
  }*/
}