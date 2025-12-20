import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/LeaveRequestModel.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class HRLeaveManagementController extends GetxController {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable lists
  final RxList<LeaveRequestModel> leaveRequests = <LeaveRequestModel>[].obs;
  final RxList<LeaveRequestModel> filteredRequests = <LeaveRequestModel>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Filters
  final RxString statusFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedMonth = 'all'.obs;

  // Pagination
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  ScrollController scrollController = ScrollController();

  // Month options
  final List<Map<String, String>> monthOptions = [
    {'value': 'all', 'label': 'All Months'},
    {'value': '0', 'label': 'January'},
    {'value': '1', 'label': 'February'},
    {'value': '2', 'label': 'March'},
    {'value': '3', 'label': 'April'},
    {'value': '4', 'label': 'May'},
    {'value': '5', 'label': 'June'},
    {'value': '6', 'label': 'July'},
    {'value': '7', 'label': 'August'},
    {'value': '8', 'label': 'September'},
    {'value': '9', 'label': 'October'},
    {'value': '10', 'label': 'November'},
    {'value': '11', 'label': 'December'},
  ];

  @override
  void onInit() {
    super.onInit();
    _enableFirestorePersistence();
    loadLeaveRequests();
    _setupScrollListener();

    // Listen to filter changes
    ever(statusFilter, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedMonth, (_) => _applyFilters());
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Enable Firestore offline persistence
  void _enableFirestorePersistence() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ Firestore persistence enabled');
    } catch (e) {
      print('⚠️ Firestore persistence error: $e');
    }
  }

  // Setup scroll listener for pagination
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore.value && _hasMoreData) {
          _loadMoreLeaveRequests();
        }
      }
    });
  }

  // Load initial leave requests from Firestore with pagination
  Future<void> loadLeaveRequests() async {
    try {
      isLoading.value = true;
      _lastDocument = null;
      _hasMoreData = true;

      // Query with pagination and ordering
      Query query = _firestore
          .collection('leaveRequests')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final querySnapshot = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      // Fetch employee details for each request
      List<LeaveRequestModel> requests = [];

      for (var doc in querySnapshot.docs) {
        final request = await _buildLeaveRequestModel(doc);
        if (request != null) {
          requests.add(request);
        }
      }

      leaveRequests.value = requests;
      _applyFilters();

      print('✅ Loaded ${requests.length} leave requests');

    } catch (e) {
      print('❌ Error loading leave requests: $e');
      Get.snackbar(
        'Error',
        'Failed to load leave requests: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load more leave requests (pagination)
  Future<void> _loadMoreLeaveRequests() async {
    if (_lastDocument == null || !_hasMoreData) return;

    try {
      isLoadingMore.value = true;

      Query query = _firestore
          .collection('leaveRequests')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final querySnapshot = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (querySnapshot.docs.isEmpty) {
        _hasMoreData = false;
        print('📭 No more leave requests to load');
        return;
      }

      _lastDocument = querySnapshot.docs.last;

      List<LeaveRequestModel> newRequests = [];

      for (var doc in querySnapshot.docs) {
        final request = await _buildLeaveRequestModel(doc);
        if (request != null) {
          newRequests.add(request);
        }
      }

      leaveRequests.addAll(newRequests);
      _applyFilters();

      print('✅ Loaded ${newRequests.length} more leave requests');

    } catch (e) {
      print('❌ Error loading more requests: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Refresh leave requests (pull to refresh)
  Future<void> refreshLeaveRequests() async {
    _lastDocument = null;
    _hasMoreData = true;
    await loadLeaveRequests();
  }

  // Build LeaveRequestModel from document
  Future<LeaveRequestModel?> _buildLeaveRequestModel(
      QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] as String;

      // Get employee details from users collection
      String employeeId = '';
      String employeeEmail = '';
      String? employeeName;

      try {
        final userDoc = await _firestore.collection('users').doc(userId).get(
          const GetOptions(source: Source.cache),
        );

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          employeeId = userData['empId'] ?? '';
          employeeEmail = userData['email'] ?? '';
          employeeName = userData['name'];
        } else {
          // If not in cache, fetch from server
          final userDocServer = await _firestore.collection('users').doc(userId).get();
          if (userDocServer.exists) {
            final userData = userDocServer.data()!;
            employeeId = userData['empId'] ?? '';
            employeeEmail = userData['email'] ?? '';
            employeeName = userData['name'];
          }
        }
      } catch (e) {
        print('⚠️ Error fetching user details for $userId: $e');
      }

      return LeaveRequestModel(
        id: doc.id,
        userId: userId,
        employeeId: employeeId,
        employeeEmail: employeeEmail,
        employeeName: employeeName,
        leaveType: data['leaveType'] ?? '',
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
        numberOfDays: data['numberOfDays'] ?? 0,
        note: data['note'] ?? '',
        documentUrl: data['documentUrl'],
        documentName: data['documentName'],
        status: data['status'] ?? 'pending',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        rejectionReason: data['rejectionReason'],
        reviewedAt: data['reviewedAt'] != null
            ? (data['reviewedAt'] as Timestamp).toDate()
            : null,
        reviewedBy: data['reviewedBy'],
      );
    } catch (e) {
      print('❌ Error building leave request model: $e');
      return null;
    }
  }

  // Apply filters (status, search, month)
  void _applyFilters() {
    var filtered = leaveRequests.toList();

    // Apply status filter
    if (statusFilter.value != 'all') {
      filtered = filtered.where((req) => req.status == statusFilter.value).toList();
    }

    // Apply month filter
    if (selectedMonth.value != 'all') {
      final monthIndex = int.parse(selectedMonth.value);
      filtered = filtered.where((req) {
        return req.startDate.month - 1 == monthIndex ||
            req.endDate.month - 1 == monthIndex;
      }).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((req) {
        return req.employeeEmail.toLowerCase().contains(query) ||
            req.employeeId.toLowerCase().contains(query) ||
            (req.employeeName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    filteredRequests.value = filtered;
    print('🔍 Filtered: ${filtered.length} requests');
  }

  // Approve leave request
  Future<void> approveLeaveRequest(String leaveRequestId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('leaveRequests').doc(leaveRequestId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentUser.uid,
      });

      // Update local list
      final index = leaveRequests.indexWhere((req) => req.id == leaveRequestId);
      if (index != -1) {
        final request = leaveRequests[index];
        leaveRequests[index] = LeaveRequestModel(
          id: request.id,
          userId: request.userId,
          employeeId: request.employeeId,
          employeeEmail: request.employeeEmail,
          employeeName: request.employeeName,
          leaveType: request.leaveType,
          startDate: request.startDate,
          endDate: request.endDate,
          numberOfDays: request.numberOfDays,
          note: request.note,
          documentUrl: request.documentUrl,
          documentName: request.documentName,
          status: 'approved',
          createdAt: request.createdAt,
          rejectionReason: null,
          reviewedAt: DateTime.now(),
          reviewedBy: currentUser.uid,
        );
      }

      _applyFilters();

      Get.snackbar(
        'Success',
        'Leave request approved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

    } catch (e) {
      print('❌ Error approving leave: $e');
      Get.snackbar(
        'Error',
        'Failed to approve leave request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Reject leave request
  Future<void> rejectLeaveRequest(String leaveRequestId, String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('leaveRequests').doc(leaveRequestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentUser.uid,
      });

      // Update local list
      final index = leaveRequests.indexWhere((req) => req.id == leaveRequestId);
      if (index != -1) {
        final request = leaveRequests[index];
        leaveRequests[index] = LeaveRequestModel(
          id: request.id,
          userId: request.userId,
          employeeId: request.employeeId,
          employeeEmail: request.employeeEmail,
          employeeName: request.employeeName,
          leaveType: request.leaveType,
          startDate: request.startDate,
          endDate: request.endDate,
          numberOfDays: request.numberOfDays,
          note: request.note,
          documentUrl: request.documentUrl,
          documentName: request.documentName,
          status: 'rejected',
          createdAt: request.createdAt,
          rejectionReason: reason,
          reviewedAt: DateTime.now(),
          reviewedBy: currentUser.uid,
        );
      }

      _applyFilters();

      Get.snackbar(
        'Success',
        'Leave request rejected',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );

    } catch (e) {
      print('❌ Error rejecting leave: $e');
      Get.snackbar(
        'Error',
        'Failed to reject leave request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Export to Excel (Placeholder - implement later)
  Future<void> exportToExcel() async {
    try {
      if (filteredRequests.isEmpty) {
        Get.snackbar(
          'No Data',
          'No leave requests to export',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating Excel file...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Create Excel workbook
      var excel = Excel.createExcel();

      // Remove default sheet and create new one
      excel.delete('Sheet1');
      String sheetName = 'Leave Requests';
      Sheet sheetObject = excel[sheetName];

      // Define header style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('FF3B82F6'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Define data style
      CellStyle dataStyle = CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
      );

      // Define status styles
      CellStyle approvedStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FF10B981'),
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle rejectedStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FFEF4444'),
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle pendingStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FFF59E0B'),
        verticalAlign: VerticalAlign.Center,
      );

      // Add title row
      String monthName = selectedMonth.value == 'all'
          ? 'All Months'
          : monthOptions.firstWhere((m) => m['value'] == selectedMonth.value)['label']!;

      var titleCell = sheetObject.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('Leave Requests Report - $monthName');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('FF1E293B'),
      );

      // Merge title cells
      sheetObject.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('K1'));

      // Add export info
      var dateCell = sheetObject.cell(CellIndex.indexByString('A2'));
      dateCell.value = TextCellValue('Generated on: ${DateTime.now().toString().split('.')[0]}');
      dateCell.cellStyle = CellStyle(fontSize: 10, italic: true);
      sheetObject.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('K2'));

      // Add summary
      var summaryCell = sheetObject.cell(CellIndex.indexByString('A3'));
      int pending = filteredRequests.where((r) => r.status == 'pending').length;
      int approved = filteredRequests.where((r) => r.status == 'approved').length;
      int rejected = filteredRequests.where((r) => r.status == 'rejected').length;
      summaryCell.value = TextCellValue(
          'Total: ${filteredRequests.length} | Pending: $pending | Approved: $approved | Rejected: $rejected');
      summaryCell.cellStyle = CellStyle(fontSize: 10, italic: true);
      sheetObject.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('K3'));

      // Add headers in row 5
      List<String> headers = [
        'S.No',
        'Employee ID',
        'Employee Name',
        'Email',
        'Leave Type',
        'Start Date',
        'End Date',
        'Days',
        'Status',
        'Note',
        'Rejection Reason',
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int i = 0; i < filteredRequests.length; i++) {
        final request = filteredRequests[i];
        int rowIndex = i + 5; // Start from row 6 (index 5)

        // S.No
        var cell0 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        cell0.value = IntCellValue(i + 1);
        cell0.cellStyle = dataStyle;

        // Employee ID
        var cell1 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        cell1.value = TextCellValue(request.employeeId);
        cell1.cellStyle = dataStyle;

        // Employee Name
        var cell2 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        cell2.value = TextCellValue(request.employeeName ?? 'N/A');
        cell2.cellStyle = dataStyle;

        // Email
        var cell3 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        cell3.value = TextCellValue(request.employeeEmail);
        cell3.cellStyle = dataStyle;

        // Leave Type
        var cell4 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        cell4.value = TextCellValue(request.leaveType);
        cell4.cellStyle = dataStyle;

        // Start Date
        var cell5 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
        cell5.value = TextCellValue(formatDate(request.startDate));
        cell5.cellStyle = dataStyle;

        // End Date
        var cell6 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
        cell6.value = TextCellValue(formatDate(request.endDate));
        cell6.cellStyle = dataStyle;

        // Days
        var cell7 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
        cell7.value = IntCellValue(request.numberOfDays);
        cell7.cellStyle = dataStyle;

        // Status with color
        var cell8 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex));
        cell8.value = TextCellValue(request.status.toUpperCase());
        cell8.cellStyle = request.status == 'approved'
            ? approvedStyle
            : request.status == 'rejected'
            ? rejectedStyle
            : pendingStyle;

        // Note
        var cell9 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
        cell9.value = TextCellValue(request.note.isEmpty ? '-' : request.note);
        cell9.cellStyle = dataStyle;

        // Rejection Reason
        var cell10 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex));
        cell10.value = TextCellValue(request.rejectionReason ?? '-');
        cell10.cellStyle = dataStyle;
      }

      // Request storage permission
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we need different permissions
        PermissionStatus status;

        // Check Android version
        if (await Permission.photos.status.isDenied) {
          // Android 13+ uses photos/videos permissions
          status = await Permission.photos.request();
        } else {
          // Android 12 and below use storage permission
          status = await Permission.storage.request();
        }

        // If still not granted, try manageExternalStorage for older approach
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      // Get directory to save file
      Directory? directory;
      String fileName = 'Leave_Requests_${monthName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (Platform.isAndroid) {
        // Try to save in Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Save the file
      String filePath = '${directory.path}/$fileName';
      var fileBytes = excel.save();

      if (fileBytes != null) {
        File file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);

        // Close loading dialog
        Get.back();

        print('✅ Excel file saved: $filePath');

        // Show success dialog with options
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Excel file has been saved successfully!'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filePath,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Records: ${filteredRequests.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Get.back();
                  try {
                    await OpenFile.open(filePath);
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Could not open file: $e',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade400,
                      colorText: Colors.white,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );

        // Also show a snackbar
        Get.snackbar(
          'Export Complete',
          '${filteredRequests.length} records exported successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      print('❌ Error exporting to Excel: $e');
      Get.snackbar(
        'Export Failed',
        'Could not export to Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
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

  // Get count of active filters
  int getActiveFiltersCount() {
    int count = 0;
    if (statusFilter.value != 'all') count++;
    if (selectedMonth.value != 'all') count++;
    return count;
  }

// Reset all filters
  void resetFilters() {
    statusFilter.value = 'all';
    selectedMonth.value = 'all';
    searchQuery.value = '';

    Get.snackbar(
      'Filters Reset',
      'All filters have been cleared',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  // Get statistics
  int get totalRequests => leaveRequests.length;
  int get pendingRequests => leaveRequests.where((req) => req.status == 'pending').length;
  int get approvedRequests => leaveRequests.where((req) => req.status == 'approved').length;
  int get rejectedRequests => leaveRequests.where((req) => req.status == 'rejected').length;

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