// lib/controllers/HRPerformanceController.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/TaskModel.dart';

class HRPerformanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable lists and filters
  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  final RxList<TaskModel> filteredTasks = <TaskModel>[].obs;
  final RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;

  // Filter states
  final RxString statusFilter = 'all'.obs;
  final RxString priorityFilter = 'all'.obs;
  final RxString selectedEmployeeId = 'all'.obs;
  final RxString searchQuery = ''.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
    loadTasks();

    // Set up listeners for filter changes
    ever(statusFilter, (_) => applyFilters());
    ever(priorityFilter, (_) => applyFilters());
    ever(selectedEmployeeId, (_) => applyFilters());
    ever(searchQuery, (_) => applyFilters());
  }

  // Load all employees from Firestore
  Future<void> loadEmployees() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();

      employees.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'department': data['department'] ?? '',
        };
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load employees: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Load all tasks from Firestore with real-time updates
  void loadTasks() {
    isLoading.value = true;

    _firestore
        .collection('tasks')
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      tasks.value = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList();

      applyFilters();
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to load tasks: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    });
  }

  // Apply all filters to tasks
  void applyFilters() {
    List<TaskModel> filtered = List.from(tasks);

    // Filter by employee
    if (selectedEmployeeId.value != 'all') {
      filtered = filtered
          .where((task) => task.assignedTo == selectedEmployeeId.value)
          .toList();
    }

    // Filter by status
    if (statusFilter.value != 'all') {
      if (statusFilter.value == 'overdue') {
        filtered = filtered.where((task) => task.isOverdue).toList();
      } else {
        filtered = filtered
            .where((task) => task.status == statusFilter.value)
            .toList();
      }
    }

    // Filter by priority
    if (priorityFilter.value != 'all') {
      filtered = filtered
          .where((task) => task.priority == priorityFilter.value)
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((task) {
        return task.taskTitle.toLowerCase().contains(query) ||
            task.taskDescription.toLowerCase().contains(query) ||
            task.assignedToName.toLowerCase().contains(query) ||
            task.assignedToEmail.toLowerCase().contains(query);
      }).toList();
    }

    filteredTasks.value = filtered;
  }

  // Create a new task
  Future<void> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String priority,
    required DateTime dueDate,
    required String assignedBy,
    required String assignedByName,
  }) async {
    try {
      final task = TaskModel(
        id: '', // Firestore will generate
        taskTitle: title,
        taskDescription: description,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        assignedToEmail: assignedToEmail,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        priority: priority,
        status: 'pending',
        assignedDate: DateTime.now(),
        dueDate: dueDate,
      );

      await _firestore.collection('tasks').add(task.toFirestore());

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Task created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'completed') {
        updateData['completedDate'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore.collection('tasks').doc(taskId).update(updateData);

      Get.snackbar(
        'Success',
        'Task status updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();

      Get.snackbar(
        'Success',
        'Task deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Get statistics for dashboard
  Map<String, int> getStatistics() {
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == 'completed').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final pending = tasks.where((t) => t.status == 'pending').length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'pending': pending,
      'overdue': overdue,
    };
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'not_completed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      case 'pending':
        return Icons.schedule;
      case 'not_completed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Get priority color
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.blue.shade700;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Format date
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadEmployees();
    Get.snackbar(
      'Refreshed',
      'Data refreshed successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  // Export to Excel (Platform-agnostic version)
  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Performance Report'];

      // Add headers
      final headers = [
        'Task Title',
        'Description',
        'Assigned To',
        'Email',
        'Priority',
        'Status',
        'Assigned Date',
        'Due Date',
        'Completed Date',
        'Days Until Due',
        'Is Overdue',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.blue,
            fontColorHex: ExcelColor.white,
          );
      }

      // Add data rows
      for (var i = 0; i < filteredTasks.length; i++) {
        final task = filteredTasks[i];
        final rowIndex = i + 1;

        final rowData = [
          task.taskTitle,
          task.taskDescription,
          task.assignedToName,
          task.assignedToEmail,
          task.priority.toUpperCase(),
          task.status.toUpperCase().replaceAll('_', ' '),
          formatDate(task.assignedDate),
          formatDate(task.dueDate),
          task.completedDate != null ? formatDate(task.completedDate!) : 'N/A',
          task.daysUntilDue.toString(),
          task.isOverdue ? 'Yes' : 'No',
        ];

        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex))
            ..value = TextCellValue(rowData[j]);
        }
      }

      // Save and share file
      final bytes = excel.encode();
      if (bytes != null) {
        final fileName = 'performance_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';

        // Write file
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Share file using share_plus
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Performance Report',
          text: 'Performance report exported successfully',
        );

        Get.snackbar(
          'Success',
          'Excel file ready to share',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}