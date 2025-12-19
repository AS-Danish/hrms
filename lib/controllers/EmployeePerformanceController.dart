// lib/controllers/EmployeePerformanceController.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/TaskModel.dart';

class EmployeePerformanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user info
  late String currentUserId;
  late String currentUserName;
  late String currentUserEmail;

  // Observable lists
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final RxList<TaskModel> hrAssignedTasks = <TaskModel>[].obs;
  final RxList<TaskModel> selfCreatedTasks = <TaskModel>[].obs;
  final RxList<TaskModel> filteredTasks = <TaskModel>[].obs;

  // Filter states
  final RxString taskTypeFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString priorityFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Tab index
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    // Get current user from FirebaseAuth
    final user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      currentUserEmail = user.email ?? '';
      print('🔍 DEBUG: Firebase Auth User ID: $currentUserId');
      print('🔍 DEBUG: Firebase Auth Email: $currentUserEmail');

      // Load user name from Firestore
      loadUserData();
    } else {
      // Fallback to arguments if no auth user
      currentUserId = Get.arguments?['userId'] ?? 'employee_001';
      currentUserName = Get.arguments?['userName'] ?? 'Employee Name';
      currentUserEmail = Get.arguments?['userEmail'] ?? 'employee@example.com';
      print('⚠️ DEBUG: Using fallback user data');
      print('🔍 DEBUG: User ID: $currentUserId');
      loadTasks();
    }

    // Set up listeners for filter changes
    ever(taskTypeFilter, (_) => applyFilters());
    ever(statusFilter, (_) => applyFilters());
    ever(priorityFilter, (_) => applyFilters());
    ever(searchQuery, (_) => applyFilters());
  }

  // Load user data from Firestore
  Future<void> loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        currentUserName = data['name'] ?? 'Employee Name';
        print('✅ DEBUG: User name loaded: $currentUserName');
      }
    } catch (e) {
      print('❌ DEBUG: Error loading user data: $e');
      currentUserName = 'Employee Name';
    }

    // Now load tasks
    loadTasks();
  }

  // Load all tasks for current employee
  void loadTasks() {
    print('🔄 DEBUG: Loading tasks for user: $currentUserId');
    isLoading.value = true;

    _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      print('📊 DEBUG: Received ${snapshot.docs.length} tasks from Firestore');

      if (snapshot.docs.isEmpty) {
        print('⚠️ DEBUG: No tasks found for this user');
        print('🔍 DEBUG: Make sure tasks are created with assignedTo: $currentUserId');
      }

      allTasks.value = snapshot.docs
          .map((doc) {
        final task = TaskModel.fromFirestore(doc.data(), doc.id);
        print('📝 DEBUG: Task loaded - Title: ${task.taskTitle}, AssignedTo: ${task.assignedTo}, AssignedBy: ${task.assignedBy}');
        return task;
      })
          .toList();

      // Sort by date in memory (to avoid composite index requirement)
      allTasks.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

      // Separate HR-assigned and self-created tasks
      hrAssignedTasks.value = allTasks
          .where((task) => task.assignedBy != currentUserId)
          .toList();

      selfCreatedTasks.value = allTasks
          .where((task) => task.assignedBy == currentUserId)
          .toList();

      print('✅ DEBUG: Total tasks: ${allTasks.length}');
      print('✅ DEBUG: HR assigned: ${hrAssignedTasks.length}');
      print('✅ DEBUG: Self created: ${selfCreatedTasks.length}');

      applyFilters();
      isLoading.value = false;
    }, onError: (e) {
      print('❌ DEBUG: Error loading tasks: $e');
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
    List<TaskModel> filtered = [];

    // Filter by task type
    switch (taskTypeFilter.value) {
      case 'hr_assigned':
        filtered = List.from(hrAssignedTasks);
        break;
      case 'self_created':
        filtered = List.from(selfCreatedTasks);
        break;
      default:
        filtered = List.from(allTasks);
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
            task.assignedByName.toLowerCase().contains(query);
      }).toList();
    }

    filteredTasks.value = filtered;
    print('🔍 DEBUG: Filtered tasks: ${filteredTasks.length} (filter type: ${taskTypeFilter.value})');
  }

  // Create a self-assigned task
  Future<void> createSelfTask({
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
  }) async {
    try {
      final task = TaskModel(
        id: '',
        taskTitle: title,
        taskDescription: description,
        assignedTo: currentUserId,
        assignedToName: currentUserName,
        assignedToEmail: currentUserEmail,
        assignedBy: currentUserId,
        assignedByName: currentUserName,
        priority: priority,
        status: 'pending',
        assignedDate: DateTime.now(),
        dueDate: dueDate,
      );

      print('📤 DEBUG: Creating self task: ${task.toFirestore()}');
      await _firestore.collection('tasks').add(task.toFirestore());

      Get.back();
      Get.snackbar(
        'Success',
        'Task created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      print('❌ DEBUG: Error creating task: $e');
      Get.snackbar(
        'Error',
        'Failed to create task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus, {String? notes}) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'completed') {
        updateData['completedDate'] = Timestamp.fromDate(DateTime.now());
        if (notes != null && notes.isNotEmpty) {
          updateData['completionNotes'] = notes;
        }
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

  // Update self-created task
  Future<void> updateSelfTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
  }) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'taskTitle': title,
        'taskDescription': description,
        'priority': priority,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.back();
      Get.snackbar(
        'Success',
        'Task updated successfully',
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

  // Delete self-created task
  Future<void> deleteSelfTask(String taskId) async {
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
    final total = allTasks.length;
    final completed = allTasks.where((t) => t.status == 'completed').length;
    final inProgress = allTasks.where((t) => t.status == 'in_progress').length;
    final pending = allTasks.where((t) => t.status == 'pending').length;
    final overdue = allTasks.where((t) => t.isOverdue).length;
    final hrAssigned = hrAssignedTasks.length;
    final selfCreated = selfCreatedTasks.length;

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'pending': pending,
      'overdue': overdue,
      'hrAssigned': hrAssigned,
      'selfCreated': selfCreated,
    };
  }

  // Get completion rate
  double getCompletionRate() {
    if (allTasks.isEmpty) return 0.0;
    final completed = allTasks.where((t) => t.status == 'completed').length;
    return (completed / allTasks.length) * 100;
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
    Get.snackbar(
      'Refreshed',
      'Data refreshed successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}