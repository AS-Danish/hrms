import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/LeaveRequestModel.dart';

class LeaveRequestController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Observable variables for form
  final RxString selectedLeaveType = 'Sick Leave'.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString note = ''.obs;
  final Rx<File?> selectedDocument = Rx<File?>(null);
  final RxString documentName = ''.obs;
  final RxInt numberOfDays = 0.obs;

  // Loading states
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingLeaves = false.obs;
  final RxBool isUploadingDocument = false.obs;

  // Leave requests list for employee
  final RxList<LeaveRequestModel> myLeaveRequests = <LeaveRequestModel>[].obs;
  final RxList<LeaveRequestModel> filteredLeaves = <LeaveRequestModel>[].obs;

  // Filter
  final RxString statusFilter = 'all'.obs;

  // Leave types
  final List<String> leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Annual Leave',
    'Emergency Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
  ];

  @override
  void onInit() {
    super.onInit();
    loadMyLeaveRequests();

    // Listen to filter changes
    ever(statusFilter, (_) => _applyFilters());
  }

  // Calculate number of days between dates
  void calculateNumberOfDays() {
    if (startDate.value != null && endDate.value != null) {
      final start = DateTime(
        startDate.value!.year,
        startDate.value!.month,
        startDate.value!.day,
      );
      final end = DateTime(
        endDate.value!.year,
        endDate.value!.month,
        endDate.value!.day,
      );

      if (end.isBefore(start)) {
        numberOfDays.value = 0;
        Get.snackbar(
          'Invalid Date Range',
          'End date cannot be before start date',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }

      numberOfDays.value = end.difference(start).inDays + 1;
    } else {
      numberOfDays.value = 0;
    }
  }

  // Pick document
  Future<void> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        selectedDocument.value = File(result.files.single.path!);
        documentName.value = result.files.single.name;

        Get.snackbar(
          'Document Selected',
          documentName.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  // Remove selected document
  void removeDocument() {
    selectedDocument.value = null;
    documentName.value = '';
  }

  // Upload document to Firebase Storage
  Future<String?> uploadDocument() async {
    if (selectedDocument.value == null) return null;

    try {
      isUploadingDocument.value = true;

      final userId = _auth.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${timestamp}_${documentName.value}';
      final storageRef = _storage.ref().child('leave_documents/$fileName');

      final uploadTask = await storageRef.putFile(selectedDocument.value!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isUploadingDocument.value = false;
    }
  }

  // Submit leave request
  Future<void> submitLeaveRequest() async {
    // Validation
    if (startDate.value == null || endDate.value == null) {
      Get.snackbar(
        'Missing Information',
        'Please select start and end dates',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    if (numberOfDays.value <= 0) {
      Get.snackbar(
        'Invalid Date Range',
        'Please select valid dates',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user details from Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      String? documentUrl;
      if (selectedDocument.value != null) {
        documentUrl = await uploadDocument();
        if (documentUrl == null) {
          throw Exception('Failed to upload document');
        }
      }

      // Create leave request
      await _firestore.collection('leaveRequests').add({
        'userId': currentUser.uid,
        'employeeId': userData?['empId'] ?? '',
        'employeeEmail': currentUser.email ?? '',
        'employeeName': userData?['name'],
        'leaveType': selectedLeaveType.value,
        'startDate': Timestamp.fromDate(startDate.value!),
        'endDate': Timestamp.fromDate(endDate.value!),
        'numberOfDays': numberOfDays.value,
        'note': note.value.trim(),
        'documentUrl': documentUrl,
        'documentName': documentName.value.isNotEmpty ? documentName.value : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      resetForm();

      // Reload leave requests
      await loadMyLeaveRequests();

      Get.snackbar(
        'Success',
        'Leave request submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate to My Leaves page
      Get.back();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit leave request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Reset form
  void resetForm() {
    selectedLeaveType.value = 'Sick Leave';
    startDate.value = null;
    endDate.value = null;
    note.value = '';
    selectedDocument.value = null;
    documentName.value = '';
    numberOfDays.value = 0;
  }

  // Load employee's leave requests
  Future<void> loadMyLeaveRequests() async {
    try {
      isLoadingLeaves.value = true;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('leaveRequests')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      myLeaveRequests.value = querySnapshot.docs
          .map((doc) => LeaveRequestModel.fromFirestore(doc))
          .toList();

      _applyFilters();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load leave requests: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      isLoadingLeaves.value = false;
    }
  }

  // Apply filters
  void _applyFilters() {
    var filtered = myLeaveRequests.toList();

    if (statusFilter.value != 'all') {
      filtered = filtered.where((req) => req.status == statusFilter.value).toList();
    }

    filteredLeaves.value = filtered;
  }

  // View document
  Future<void> viewDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  // Get statistics
  int get totalRequests => myLeaveRequests.length;
  int get pendingRequests => myLeaveRequests.where((req) => req.status == 'pending').length;
  int get approvedRequests => myLeaveRequests.where((req) => req.status == 'approved').length;
  int get rejectedRequests => myLeaveRequests.where((req) => req.status == 'rejected').length;

  // Get color for status
  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get icon for status
  IconData getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  // Format date
  String formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}