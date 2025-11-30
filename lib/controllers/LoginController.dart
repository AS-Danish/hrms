import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import '../auth/AuthWrapper.dart';
import '../auth/login_page.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;

  // Office location coordinates (Change these to your office location)
  static const double OFFICE_LATITUDE = 19.8762; // Replace with your office latitude
  static const double OFFICE_LONGITUDE = 75.3433; // Replace with your office longitude
  static const double ALLOWED_RADIUS_METERS = 50.0; // 50 meters radius

  // DEBUG MODE - Set to true during development to bypass location check
  // IMPORTANT: Set to false in production!
  static const bool DEBUG_MODE = false; // Change to false for production

  /// Check if location services are enabled and permissions are granted
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "Location Required",
        "Please enable location services to login",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          "Permission Denied",
          "Location permission is required for employee login",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        "Permission Denied",
        "Location permission is permanently denied. Please enable it in settings.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    return true;
  }

  /// Get current device location with better error handling
  Future<Position?> _getCurrentLocation() async {
    try {
      // Show a loading indicator
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                    SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Increased timeout
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      return position;
    } on TimeoutException catch (e) {
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      debugPrint('Location timeout: $e');

      // Show retry dialog
      bool? shouldRetry = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Location Timeout'),
          content: const Text(
            'Unable to get your location. This might be because:\n\n'
                '• GPS signal is weak\n'
                '• You\'re indoors\n'
                '• Location services just started\n\n'
                'Would you like to try again?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

      if (shouldRetry == true) {
        // Retry getting location
        return await _getCurrentLocation();
      }

      return null;
    } catch (e) {
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      debugPrint('Error getting location: $e');
      Get.snackbar(
        "Location Error",
        "Failed to get your location: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return null;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * asin(sqrt(a));
    double distanceKm = earthRadiusKm * c;
    return distanceKm * 1000; // Convert to meters
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }

  double sin(double value) {
    return value - (value * value * value) / 6 + (value * value * value * value * value) / 120;
  }

  /// Check if user is within allowed radius
  Future<bool> _isWithinOfficeRadius(Position currentPosition) async {
    double distance = _calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      OFFICE_LATITUDE,
      OFFICE_LONGITUDE,
    );

    debugPrint('Current location: ${currentPosition.latitude}, ${currentPosition.longitude}');
    debugPrint('Office location: $OFFICE_LATITUDE, $OFFICE_LONGITUDE');
    debugPrint('Distance from office: ${distance.toStringAsFixed(2)} meters');

    return distance <= ALLOWED_RADIUS_METERS;
  }

  /// Get user role from email (check Firestore without signing in)
  Future<String?> _getUserRoleByEmail(String email) async {
    try {
      // Query Firestore to find user by email
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic>? data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
        return data?['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching user role by email: $e');
    }
    return null;
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
      // STEP 1: Check if user is an employee BEFORE authentication
      debugPrint('Checking user role for: $email');
      String? userRole = await _getUserRoleByEmail(email);
      debugPrint('User role: $userRole');

      // STEP 2: If employee, verify location BEFORE signing in
      if (userRole?.toLowerCase() == 'employee') {
        debugPrint('Employee detected - checking location before login...');

        // DEBUG MODE - Skip location check during development
        if (DEBUG_MODE) {
          debugPrint('⚠️ DEBUG MODE: Bypassing location check');
          Get.snackbar(
            "Debug Mode",
            "Location check bypassed (DEBUG_MODE = true)",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Production mode - enforce location check BEFORE login

          // Check location permissions
          bool hasPermission = await _checkLocationPermission();
          if (!hasPermission) {
            isLoading.value = false;
            Get.snackbar(
              "Permission Required",
              "Location permission is required for employee login. Please grant permission and try again.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
            return;
          }

          // Get current location
          Position? currentPosition = await _getCurrentLocation();
          if (currentPosition == null) {
            isLoading.value = false;
            Get.snackbar(
              "Location Required",
              "Unable to verify your location. Please ensure location services are enabled and try again.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
            return;
          }

          // Check if within office radius
          bool isWithinRadius = await _isWithinOfficeRadius(currentPosition);
          if (!isWithinRadius) {
            isLoading.value = false;
            Get.snackbar(
              "Location Restricted",
              "You must be within 50 meters of the office to login.\nPlease come to the office and try again.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.location_off, color: Colors.white),
            );
            return;
          }

          debugPrint('✅ Location verified - user is within office radius');
        }
      }

      // STEP 3: Location check passed (or not needed) - Now sign in with Firebase
      debugPrint('Proceeding with Firebase authentication...');
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Login successful
      Get.snackbar(
        "Success",
        "Login Successful",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // AuthWrapper's StreamBuilder will automatically handle navigation
      Get.offAll(() => const AuthWrapper());

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
        case "invalid-credential":
          message = "Invalid email or password";
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
    await _auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}