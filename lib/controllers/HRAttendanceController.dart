// lib/controllers/HRAttendanceController.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

import '../models/AttendanceModel.dart';

class HRAttendanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<AttendanceModel> allRecords = <AttendanceModel>[].obs;
  final RxList<AttendanceModel> filteredRecords = <AttendanceModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // Load data for the current day initially
    loadAttendanceRecords(selectedDate.value);

    // React to filter/date changes
    ever(statusFilter, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedDate, (date) => loadAttendanceRecords(date));
  }

  // Fetch Attendance Records - FIXED VERSION
  Future<void> loadAttendanceRecords(DateTime date) async {
    isLoading.value = true;
    allRecords.clear();
    filteredRecords.clear();

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      // Method 1: Query using 'date' field (RECOMMENDED if you have a 'date' field)
      // This assumes your AttendanceModel has a 'date' field stored in Firestore
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateString)
          .get(const GetOptions(source: Source.serverAndCache));

      final List<AttendanceModel> fetchedRecords = [];

      for (var doc in querySnapshot.docs) {
        try {
          final record = AttendanceModel.fromFirestore(doc.data(), doc.id);
          fetchedRecords.add(record);
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
        }
      }

      // Sort by login time for better readability
      fetchedRecords.sort((a, b) {
        try {
          // Parse time strings and compare
          final aTime = DateFormat('hh:mm a').parse(a.loginTime);
          final bTime = DateFormat('hh:mm a').parse(b.loginTime);
          return aTime.compareTo(bTime);
        } catch (e) {
          // If parsing fails, do string comparison
          return a.loginTime.compareTo(b.loginTime);
        }
      });

      allRecords.value = fetchedRecords;
      _applyFilters();

      print('✅ Loaded ${fetchedRecords.length} attendance records for $dateString');

      if (fetchedRecords.isEmpty) {
        Get.snackbar(
          'No Records',
          'No attendance records found for ${formatDate(date)}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Error loading attendance records: $e');
      Get.snackbar(
        'Error',
        'Failed to load attendance records: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Alternative method if you don't have a 'date' field
  // This fetches all records and filters client-side
  Future<void> loadAttendanceRecordsClientSide(DateTime date) async {
    isLoading.value = true;
    allRecords.clear();
    filteredRecords.clear();

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      // Fetch all attendance records
      final querySnapshot = await _firestore
          .collection('attendance')
          .get(const GetOptions(source: Source.serverAndCache));

      final List<AttendanceModel> fetchedRecords = [];

      for (var doc in querySnapshot.docs) {
        try {
          final record = AttendanceModel.fromFirestore(doc.data(), doc.id);

          // Filter by date (check if document ID ends with the date)
          if (doc.id.endsWith('_$dateString') || record.date == dateString) {
            fetchedRecords.add(record);
          }
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
        }
      }

      // Sort by login time
      fetchedRecords.sort((a, b) {
        try {
          final aTime = DateFormat('hh:mm a').parse(a.loginTime);
          final bTime = DateFormat('hh:mm a').parse(b.loginTime);
          return aTime.compareTo(bTime);
        } catch (e) {
          return a.loginTime.compareTo(b.loginTime);
        }
      });

      allRecords.value = fetchedRecords;
      _applyFilters();

      print('✅ Loaded ${fetchedRecords.length} attendance records for $dateString');

      if (fetchedRecords.isEmpty) {
        Get.snackbar(
          'No Records',
          'No attendance records found for ${formatDate(date)}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Error loading attendance records: $e');
      Get.snackbar(
        'Error',
        'Failed to load attendance records: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Apply filters (status, search)
  void _applyFilters() {
    var filtered = allRecords.toList();

    // Apply status filter
    if (statusFilter.value != 'all') {
      filtered = filtered.where((rec) {
        return rec.status.toLowerCase() == statusFilter.value.toLowerCase();
      }).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((rec) {
        return rec.email.toLowerCase().contains(query) ||
            rec.userId.toLowerCase().contains(query) ||
            rec.userName.toLowerCase().contains(query);
      }).toList();
    }

    filteredRecords.value = filtered;
    print('🔍 Filtered: ${filtered.length} records (Total: ${allRecords.length})');
  }

  // Date Picker
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      print('📅 Date changed to: ${formatDate(picked)}');
    }
  }

  // Update Status (for manual override/correction by HR)
  Future<void> updateAttendanceStatus(String recordId, String newStatus) async {
    try {
      await _firestore.collection('attendance').doc(recordId).update({
        'status': newStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = allRecords.indexWhere((rec) => rec.id == recordId);
      if (index != -1) {
        final record = allRecords[index];
        allRecords[index] = AttendanceModel(
          id: record.id,
          userId: record.userId,
          userName: record.userName,
          userRole: record.userRole,
          email: record.email,
          date: record.date,
          loginTime: record.loginTime,
          status: newStatus, // Updated status
          latitude: record.latitude,
          longitude: record.longitude,
          accuracy: record.accuracy,
          markedAt: record.markedAt,
        );
      }
      _applyFilters();

      Get.snackbar(
        'Success',
        'Attendance status updated to ${newStatus.toUpperCase()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      print('❌ Error updating attendance status: $e');
      Get.snackbar(
        'Error',
        'Failed to update attendance status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadAttendanceRecords(selectedDate.value);
  }

  // Helper functions for UI
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade600;
      case 'on_leave':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'on_leave':
        return Icons.event_available;
      default:
        return Icons.info;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String formatTime(String time) {
    try {
      final parsedTime = DateFormat('hh:mm a').parse(time);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  // Get statistics for current filtered data
  Map<String, int> getStatistics() {
    int present = filteredRecords.where((r) => r.status.toLowerCase() == 'present').length;
    int absent = filteredRecords.where((r) => r.status.toLowerCase() == 'absent').length;
    int onLeave = filteredRecords.where((r) => r.status.toLowerCase() == 'on_leave').length;

    return {
      'total': filteredRecords.length,
      'present': present,
      'absent': absent,
      'onLeave': onLeave,
    };
  }

  // Export to Excel - Complete Implementation
  Future<void> exportToExcel() async {
    try {
      if (filteredRecords.isEmpty) {
        Get.snackbar(
          'No Data',
          'No attendance records to export',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading dialog
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
      String sheetName = 'Attendance Records';
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
      CellStyle presentStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FF10B981'),
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle absentStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FFEF4444'),
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle leaveStyle = CellStyle(
        fontSize: 11,
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FF3B82F6'),
        verticalAlign: VerticalAlign.Center,
      );

      // Add title row
      String dateStr = formatDate(selectedDate.value);
      var titleCell = sheetObject.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('Attendance Report - $dateStr');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('FF1E293B'),
      );

      // Merge title cells
      sheetObject.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('J1'));

      // Add export info
      var dateCell = sheetObject.cell(CellIndex.indexByString('A2'));
      dateCell.value = TextCellValue('Generated on: ${DateTime.now().toString().split('.')[0]}');
      dateCell.cellStyle = CellStyle(fontSize: 10, italic: true);
      sheetObject.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('J2'));

      // Add summary
      var stats = getStatistics();
      var summaryCell = sheetObject.cell(CellIndex.indexByString('A3'));
      summaryCell.value = TextCellValue(
          'Total: ${stats['total']} | Present: ${stats['present']} | Absent: ${stats['absent']} | On Leave: ${stats['onLeave']}');
      summaryCell.cellStyle = CellStyle(fontSize: 10, italic: true);
      sheetObject.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('J3'));

      // Add headers in row 5
      List<String> headers = [
        'S.No',
        'Employee Name',
        'Email',
        'Role',
        'Login Time',
        'Status',
        'Latitude',
        'Longitude',
        'Accuracy (m)',
        'Date',
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int i = 0; i < filteredRecords.length; i++) {
        final record = filteredRecords[i];
        int rowIndex = i + 5; // Start from row 6 (index 5)

        // S.No
        var cell0 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        cell0.value = IntCellValue(i + 1);
        cell0.cellStyle = dataStyle;

        // Employee Name
        var cell1 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        cell1.value = TextCellValue(record.userName);
        cell1.cellStyle = dataStyle;

        // Email
        var cell2 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        cell2.value = TextCellValue(record.email);
        cell2.cellStyle = dataStyle;

        // Role
        var cell3 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        cell3.value = TextCellValue(record.userRole);
        cell3.cellStyle = dataStyle;

        // Login Time
        var cell4 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        cell4.value = TextCellValue(record.loginTime);
        cell4.cellStyle = dataStyle;

        // Status with color
        var cell5 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
        cell5.value = TextCellValue(record.status.toUpperCase());
        cell5.cellStyle = record.status.toLowerCase() == 'present'
            ? presentStyle
            : record.status.toLowerCase() == 'absent'
            ? absentStyle
            : leaveStyle;

        // Latitude
        var cell6 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
        cell6.value = DoubleCellValue(record.latitude);
        cell6.cellStyle = dataStyle;

        // Longitude
        var cell7 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
        cell7.value = DoubleCellValue(record.longitude);
        cell7.cellStyle = dataStyle;

        // Accuracy
        var cell8 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex));
        cell8.value = DoubleCellValue(record.accuracy);
        cell8.cellStyle = dataStyle;

        // Date
        var cell9 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
        cell9.value = TextCellValue(record.date);
        cell9.cellStyle = dataStyle;
      }

      // Auto-fit columns (set reasonable widths)
      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }
      // Make email and name columns wider
      sheetObject.setColumnWidth(1, 25); // Name
      sheetObject.setColumnWidth(2, 30); // Email

      // Request storage permission
      if (Platform.isAndroid) {
        PermissionStatus status;

        // Check Android version
        if (await Permission.photos.status.isDenied) {
          // Android 13+ uses photos/videos permissions
          status = await Permission.photos.request();
        } else {
          // Android 12 and below use storage permission
          status = await Permission.storage.request();
        }

        // If still not granted, try manageExternalStorage
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      // Get directory to save file
      Directory? directory;
      String fileName = 'Attendance_${DateFormat('yyyy-MM-dd').format(selectedDate.value)}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
                  'Total Records: ${filteredRecords.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
          '${filteredRecords.length} attendance records exported successfully',
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
}