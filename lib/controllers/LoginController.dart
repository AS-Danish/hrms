import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:intl/intl.dart';
import '../auth/AuthWrapper.dart';
import '../auth/login_page.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;

  // Office location coordinates (USED ONLY FOR EMPLOYEES and IF ATTENDANCE IS MARKED)
  static const double OFFICE_LATITUDE = 19.8895;
  static const double OFFICE_LONGITUDE = 75.3453;
  static const double ALLOWED_RADIUS_METERS = 50.0;

  // NEW: Time restrictions for ATTENDANCE MARKING (Applies to all attendance-required roles)
  static const int ATTENDANCE_START_HOUR = 10;
  static const int ATTENDANCE_START_MINUTE = 45;
  static const int ATTENDANCE_END_HOUR = 13;
  static const int ATTENDANCE_END_MINUTE = 15;

  // DEBUG MODE - Set to false in production!
  static const bool DEBUG_MODE = false;

  // --- NEW METHOD FOR ATTENDANCE TIME ---
  /// Check if current time is within allowed attendance marking window
  bool _isWithinAttendanceTime() {
    final now = DateTime.now();

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      ATTENDANCE_START_HOUR,
      ATTENDANCE_START_MINUTE,
    );

    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      ATTENDANCE_END_HOUR,
      ATTENDANCE_END_MINUTE,
    );

    debugPrint('Current time: ${DateFormat('HH:mm').format(now)}');
    debugPrint('Allowed Attendance window: ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}');

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // --- RENAMED & REFACTORED METHOD FOR EMPLOYEE LOGIN TIME ---
  /// Check if current time is within allowed *employee login* window (not attendance)
  bool _isWithinEmployeeLoginTime() {
    final now = DateTime.now();

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      ATTENDANCE_START_HOUR,
      ATTENDANCE_START_MINUTE,
    );

    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      ATTENDANCE_END_HOUR,
      ATTENDANCE_END_MINUTE,
    );

    debugPrint('Current time: ${DateFormat('HH:mm').format(now)}');
    debugPrint('Allowed Employee Login window: ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}');

    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  // ----------------------------------------------------------------------


  /// Mark attendance in Firestore
  Future<bool> _markAttendance({
    required String userId,
    required String userName,
    required String userRole,
    required String email,
    required Position location,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final docId = '${userId}_$today';

      // UPDATE the existing record (which was created as absent)
      await _firestore.collection('attendance').doc(docId).update({
        'status': 'present',  // Change from absent to present
        'loginTime': DateFormat('HH:mm:ss').format(now),
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
        'markedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Attendance updated to PRESENT for $userName on $today');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      return false;
    }
  }

  /// Create absent attendance records for all employees at start of day
  Future<void> initializeDailyAttendance() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get all employees and HR
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['employee', 'hr'])
          .get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final attendanceDocId = '${userId}_$today';

        // Check if today's record already exists
        DocumentSnapshot attendanceDoc = await _firestore
            .collection('attendance')
            .doc(attendanceDocId)
            .get();

        // Only create if doesn't exist (so we don't overwrite present status)
        if (!attendanceDoc.exists) {
          await _firestore.collection('attendance').doc(attendanceDocId).set({
            'userId': userId,
            'userName': userDoc.get('name') ?? 'Unknown',
            'userRole': userDoc.get('role') ?? 'employee',
            'email': userDoc.get('email') ?? '',
            'date': today,
            'status': 'absent',
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint('📝 Created absent record for ${userDoc.get('name')}');
        }
      }

      debugPrint('✅ Daily attendance initialized for $today');
    } catch (e) {
      debugPrint('❌ Error initializing daily attendance: $e');
    }
  }

  /// Check if location services are enabled and permissions are granted
  Future<bool> _checkLocationPermission() async {
    // ... (This function remains the same)
    bool serviceEnabled;
    LocationPermission permission;

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
    // ... (This function remains the same)
    try {
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
        timeLimit: const Duration(seconds: 30),
      );

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      return position;
    } on TimeoutException catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      debugPrint('Location timeout: $e');

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
        return await _getCurrentLocation();
      }

      return null;
    } catch (e) {
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
    // ... (This function remains the same)
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
    return distanceKm * 1000;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }

  double sin(double value) {
    return value - (value * value * value) / 6 + (value * value * value * value * value) / 120;
  }

  /// Check if user is within allowed radius
  bool _isWithinOfficeRadius(Position currentPosition) {
    // ... (This function remains the same)
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

  /// Get user details by email - OPTIMIZED: Single read returns all data
  Future<Map<String, dynamic>?> _getUserDetailsByEmail(String email) async {
    // ... (This function remains the same)
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        // Get attendance status in same call
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final attendanceDocId = '${doc.id}_$today';

        return {
          'userId': doc.id,
          'userName': doc.get('name') ?? 'Unknown',
          'userRole': doc.get('role') ?? 'employee',
          'email': doc.get('email') ?? email,
          'attendanceDocId': attendanceDocId,
        };
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
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

    Position? validatedLocation;
    Map<String, dynamic>? userDetails;

    try {
      // STEP 1: Get user details
      debugPrint('📖 Fetching user details for: $email');
      userDetails = await _getUserDetailsByEmail(email);

      if (userDetails == null) {
        isLoading.value = false;
        Get.snackbar(
          "User Not Found",
          "No user found with this email",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final userRole = userDetails['userRole']?.toLowerCase();
      debugPrint('User role: $userRole');

      // Define roles that require attendance marking
      final bool requiresAttendanceMarking = userRole == 'employee' || userRole == 'hr';

      // STEP 2: Pre-login validation based on role

      if (userRole == 'employee') {
        debugPrint('👤 Employee detected - validating login time and location...');

        if (!DEBUG_MODE) {
          // A. Employee Login Time Restriction (MUST PASS to proceed with login)
          if (!_isWithinEmployeeLoginTime()) {
            isLoading.value = false;
            final now = DateTime.now();
            Get.snackbar(
              "Login Time Restricted",
              "Employees can only login between ${ATTENDANCE_START_HOUR}:${ATTENDANCE_START_MINUTE.toString().padLeft(2, '0')} and ${ATTENDANCE_END_HOUR}:${ATTENDANCE_END_MINUTE.toString().padLeft(2, '0')}.\n\nCurrent time: ${DateFormat('HH:mm').format(now)}",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.access_time, color: Colors.white),
            );
            return;
          }
          debugPrint('✅ Employee Login Time check passed');

          // B. Location check (Required for both login proceedure and attendance marking)
          bool hasPermission = await _checkLocationPermission();
          if (!hasPermission) {
            isLoading.value = false;
            return;
          }

          validatedLocation = await _getCurrentLocation();
          if (validatedLocation == null) {
            isLoading.value = false;
            return;
          }

          bool isWithinRadius = _isWithinOfficeRadius(validatedLocation);
          if (!isWithinRadius) {
            isLoading.value = false;
            Get.snackbar(
              "Location Restricted",
              "You must be within ${ALLOWED_RADIUS_METERS.toInt()} meters of the office to login.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.location_off, color: Colors.white),
            );
            return;
          }
          debugPrint('✅ Location verified - within office radius');
        } else {
          debugPrint('⚠️ DEBUG MODE: Bypassing employee time and location checks');
        }

      } else if (userRole == 'hr') {
        // HR LOGIN: No time restriction for login itself, but location must be checked if attendance is to be marked.
        debugPrint('👤 HR detected - validating location only for attendance marking...');

        if (!DEBUG_MODE) {
          // Location check is only necessary if they are *currently* in the attendance window
          if (_isWithinAttendanceTime()) {
            bool hasPermission = await _checkLocationPermission();
            if (!hasPermission) {
              isLoading.value = false;
              // Allow login but skip attendance marking
              // We continue to STEP 3/4 but attendance will fail/skip
            } else {
              validatedLocation = await _getCurrentLocation();
              if (validatedLocation != null) {
                bool isWithinRadius = _isWithinOfficeRadius(validatedLocation);
                if (!isWithinRadius) {
                  validatedLocation = null; // Invalidate location if outside radius
                  Get.snackbar(
                    "Attendance Note",
                    "You are outside the office radius. Attendance will NOT be marked.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              }
            }
          } else {
            debugPrint('Attendance window closed. Skipping location check for HR.');
          }
        }
      }

      if (requiresAttendanceMarking) {
        await initializeDailyAttendance();
      }

      // STEP 3: Validation passed (for employee) or allowed (for HR) - Authenticate
      debugPrint('🔐 Proceeding with Firebase authentication...');
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // STEP 4: Mark attendance for employees AND HR
      if (requiresAttendanceMarking && !DEBUG_MODE) {
        debugPrint('📝 Checking attendance marking conditions...');

        if (!_isWithinAttendanceTime()) {
          Get.snackbar(
            "Attendance Note",
            "Login successful, but attendance can only be marked between ${ATTENDANCE_START_HOUR}:${ATTENDANCE_START_MINUTE.toString().padLeft(2, '0')} and ${ATTENDANCE_END_HOUR}:${ATTENDANCE_END_MINUTE.toString().padLeft(2, '0')}. Attendance skipped.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else if (validatedLocation == null) {
          // This case covers HR/Employee who failed the location check/fetch
          Get.snackbar(
            "Attendance Note",
            "Login successful. Attendance was not marked due to location or permission issues.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          // Final check for location, although location check should have been done earlier
          bool isWithinRadius = _isWithinOfficeRadius(validatedLocation);

          if (isWithinRadius) {
            bool attendanceMarked = await _markAttendance(
              userId: userDetails['userId'],
              userName: userDetails['userName'],
              userRole: userDetails['userRole'],
              email: userDetails['email'],
              location: validatedLocation,
            );

            if (attendanceMarked) {
              Get.snackbar(
                "Success",
                "Login Successful - Attendance Marked ✓",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            } else {
              Get.snackbar(
                "Warning",
                "Login successful but attendance marking failed",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          } else {
            // Should have been caught earlier, but serves as a final guard
            Get.snackbar(
              "Attendance Note",
              "Login successful. You are outside the office radius. Attendance skipped.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
        }
      } else {
        // Non-attendance role or debug mode
        Get.snackbar(
          "Success",
          "Login Successful",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      Get.offAll(() => const AuthWrapper());

    } on FirebaseAuthException catch (e) {
      // ... (Error handling remains the same)
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
      debugPrint('❌ Unexpected error: $e');
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

  /*@override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }*/
}