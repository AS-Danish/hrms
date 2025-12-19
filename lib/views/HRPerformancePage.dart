// lib/views/HRPerformancePage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/HRPerformanceController.dart';
import '../models/TaskModel.dart';
import '../widgets/FilterBottomSheets.dart';

class HRPerformancePage extends GetView<HRPerformanceController> {
  const HRPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 20),
                  _buildStatistics(isMobile),
                ],
              ),
            ),
          ),

          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                16,
                isMobile ? 16 : 24,
                0,
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 12),
                  _buildFilterButton(context),
                ],
              ),
            ),
          ),

          // Active Filters Display
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 12,
              ),
              child: _buildActiveFilters(),
            ),
          ),

          // Task List
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.filteredTasks.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                0,
                isMobile ? 16 : 24,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTaskCard(
                    controller.filteredTasks[index],
                    isMobile,
                  ),
                  childCount: controller.filteredTasks.length,
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return const Row(
      children: [
        Icon(Icons.assessment, color: Color(0xFF3B82F6), size: 28),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Performance Tracking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(bool isMobile) {
    return Obx(() {
      final stats = controller.getStatistics();
      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: isMobile
            ? Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    stats['total']!,
                    Icons.task_alt,
                    Colors.blue,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Done',
                    stats['completed']!,
                    Icons.check_circle,
                    Colors.green,
                    isMobile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    stats['pending']!,
                    Icons.schedule,
                    Colors.orange,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Overdue',
                    stats['overdue']!,
                    Icons.warning,
                    Colors.red,
                    isMobile,
                  ),
                ),
              ],
            ),
          ],
        )
            : Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              'Total Tasks',
              stats['total']!,
              Icons.task_alt,
              Colors.blue,
              isMobile,
            ),
            _buildStatCard(
              'Completed',
              stats['completed']!,
              Icons.check_circle,
              Colors.green,
              isMobile,
            ),
            _buildStatCard(
              'In Progress',
              stats['inProgress']!,
              Icons.pending,
              Colors.blue,
              isMobile,
            ),
            _buildStatCard(
              'Pending',
              stats['pending']!,
              Icons.schedule,
              Colors.orange,
              isMobile,
            ),
            _buildStatCard(
              'Overdue',
              stats['overdue']!,
              Icons.warning,
              Colors.red,
              isMobile,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
      String label,
      int value,
      IconData icon,
      Color color,
      bool isMobile,
      ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => controller.searchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Obx(() {
      final activeFiltersCount = controller.getActiveFiltersCount();

      return Stack(
        clipBehavior: Clip.none,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
            icon: const Icon(Icons.filter_list, size: 20),
            label: const Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (activeFiltersCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  activeFiltersCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildActiveFilters() {
    return Obx(() {
      final activeFilters = <Widget>[];

      if (controller.selectedEmployeeId.value != 'all') {
        final emp = controller.employees.firstWhere(
              (e) => e['id'] == controller.selectedEmployeeId.value,
          orElse: () => {'name': 'Unknown'},
        );
        activeFilters.add(_buildFilterChipDisplay(
          'Employee: ${emp['name']}',
              () => controller.selectedEmployeeId.value = 'all',
        ));
      }

      if (controller.statusFilter.value != 'all') {
        activeFilters.add(_buildFilterChipDisplay(
          'Status: ${controller.statusFilter.value.replaceAll('_', ' ').capitalizeFirst}',
              () => controller.statusFilter.value = 'all',
        ));
      }

      if (controller.priorityFilter.value != 'all') {
        activeFilters.add(_buildFilterChipDisplay(
          'Priority: ${controller.priorityFilter.value.capitalizeFirst}',
              () => controller.priorityFilter.value = 'all',
        ));
      }

      if (activeFilters.isEmpty) {
        return const SizedBox.shrink();
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activeFilters,
      );
    });
  }

  Widget _buildFilterChipDisplay(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF3B82F6),
        fontWeight: FontWeight.w500,
      ),
      deleteIconColor: const Color(0xFF3B82F6),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Tasks Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new task to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isMobile) {
    final statusColor = controller.getStatusColor(task.status);
    final priorityColor = controller.getPriorityColor(task.priority);
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.red.shade200 : const Color(0xFFE2E8F0),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetailsDialog(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title and Priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.taskTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: priorityColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Employee Info and Status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 16,
                    child: Text(
                      task.assignedToName.isNotEmpty
                          ? task.assignedToName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.assignedToName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          task.assignedToEmail,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.getStatusIcon(task.status),
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.status
                              .toUpperCase()
                              .replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due Date
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${controller.formatDate(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                      fontWeight:
                      isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (task.daysUntilDue >= 0 && task.status != 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: task.daysUntilDue <= 2
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.daysUntilDue} days left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.daysUntilDue <= 2
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (task.status != 'completed')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusUpdateDialog(task),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Update Status'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (task.status != 'completed') const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDeleteTask(task),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                    ),
                    tooltip: 'Delete Task',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selEmp = '';
    String selPriority = 'medium';
    DateTime selDueDate = DateTime.now().add(const Duration(days: 7));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_task, color: Color(0xFF3B82F6), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Create New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Assign To *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: controller.employees
                      .map((emp) => DropdownMenuItem<String>(
                    value: emp['id'] as String,
                    child: Text(emp['name'] as String),
                  ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) selEmp = v;
                  },
                )),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (v) {
                    if (v != null) selPriority = v;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selDueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) selDueDate = picked;
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(selDueDate)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            descController.text.isEmpty ||
                            selEmp.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please fill all required fields',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        final emp = controller.employees
                            .firstWhere((e) => e['id'] == selEmp);
                        controller.createTask(
                          title: titleController.text,
                          description: descController.text,
                          assignedTo: selEmp,
                          assignedToName: emp['name'] as String,
                          assignedToEmail: emp['email'] as String,
                          priority: selPriority,
                          dueDate: selDueDate,
                          assignedBy: 'hr_id',
                          assignedByName: 'HR Manager',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Create Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(TaskModel task) {
    Get.dialog(AlertDialog(
      title: const Text('Update Task Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.orange),
            title: const Text('Pending'),
            onTap: () {
              controller.updateTaskStatus(task.id, 'pending');
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending, color: Colors.blue),
            title: const Text('In Progress'),
            onTap: () {
              controller.updateTaskStatus(task.id, 'in_progress');
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Completed'),
            onTap: () {
              controller.updateTaskStatus(task.id, 'completed');
              Get.back();
            },
          ),
        ],
      ),
    ));
  }

  void _showTaskDetailsDialog(TaskModel task) {
    Widget buildDetailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    }

    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    controller.getStatusIcon(task.status),
                    color: controller.getStatusColor(task.status),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Task Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildDetailRow('Title', task.taskTitle),
              const Divider(height: 24),
              buildDetailRow('Description', task.taskDescription),
              const Divider(height: 24),
              buildDetailRow('Assigned To', task.assignedToName),
              buildDetailRow('Email', task.assignedToEmail),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: buildDetailRow(
                      'Priority',
                      task.priority.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildDetailRow(
                      'Status',
                      task.status.toUpperCase().replaceAll('_', ' '),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              buildDetailRow('Due Date', controller.formatDate(task.dueDate)),
              buildDetailRow(
                'Assigned Date',
                controller.formatDate(task.assignedDate),
              ),
              if (task.completedDate != null)
                buildDetailRow(
                  'Completed Date',
                  controller.formatDate(task.completedDate!),
                ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _confirmDeleteTask(TaskModel task) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Task'),
      content: Text('Are you sure you want to delete "${task.taskTitle}"?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            controller.deleteTask(task.id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}