// lib/views/EmployeePerformancePage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/EmployeePerformanceController.dart';
import '../models/TaskModel.dart';
import '../widgets/EmployeeFilterBottomSheet.dart';

class EmployeePerformancePage extends GetView<EmployeePerformanceController> {
  const EmployeePerformancePage({super.key});

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
                    context,
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

  // --- UI Components ---

  Widget _buildHeader(bool isMobile) {
    return Obx(() => Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF3B82F6),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                controller.currentUserName.value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildStatistics(bool isMobile) {
    return Obx(() {
      final stats = controller.getStatistics();
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildStatCard('Total', stats['total']!, Icons.task_alt, Colors.blue, isMobile),
          _buildStatCard('Completed', stats['completed']!, Icons.check_circle, Colors.green, isMobile),
          _buildStatCard('In Progress', stats['inProgress']!, Icons.pending, Colors.blue, isMobile),
          _buildStatCard('Pending', stats['pending']!, Icons.schedule, Colors.orange, isMobile),
          _buildStatCard('Overdue', stats['overdue']!, Icons.warning, Colors.red, isMobile),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? (Get.width - 44) / 2 : 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
            maxLines: 2,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                builder: (context) => const EmployeeFilterBottomSheet(),
              );
            },
            icon: const Icon(Icons.filter_list, size: 20),
            label: const Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (activeFiltersCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  activeFiltersCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

      if (controller.taskTypeFilter.value != 'all') {
        final label = controller.taskTypeFilter.value == 'hr_assigned' ? 'HR Assigned' : 'My Tasks';
        activeFilters.add(_buildFilterChipDisplay('Type: $label', () => controller.taskTypeFilter.value = 'all'));
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

      if (activeFilters.isEmpty) return const SizedBox.shrink();

      return Wrap(spacing: 8, runSpacing: 8, children: activeFilters);
    });
  }

  Widget _buildFilterChipDisplay(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500),
      deleteIconColor: const Color(0xFF3B82F6),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No Tasks Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Create a new task or adjust your filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, bool isMobile) {
    final statusColor = controller.getStatusColor(task.status);
    final priorityColor = controller.getPriorityColor(task.priority);
    final isOverdue = task.isOverdue;
    final isSelfCreated = task.assignedBy == controller.currentUserId;
    final canUpdateStatus = task.status != 'completed' && !isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isOverdue ? Colors.red.shade200 : const Color(0xFFE2E8F0), width: isOverdue ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetailsDialog(task, isSelfCreated, context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.taskTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text(task.taskDescription, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTag(task.priority.toUpperCase(), priorityColor),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(child: Text(isSelfCreated ? 'Self-assigned' : 'Assigned by ${task.assignedByName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                  _buildTag(task.status.toUpperCase().replaceAll('_', ' '), statusColor, icon: controller.getStatusIcon(task.status)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: isOverdue ? Colors.red.shade700 : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Due: ${controller.formatDate(task.dueDate)}', style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red.shade700 : Colors.grey.shade700)),
                  const Spacer(),
                  if (canUpdateStatus)
                    TextButton.icon(
                      onPressed: () => _showStatusUpdateDialog(task),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Update'),
                    ),
                  if (isSelfCreated)
                    IconButton(onPressed: () => _confirmDeleteTask(task), icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showTaskDetailsDialog(TaskModel task, bool isSelfCreated, BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Task Details', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _detailLabel('Title'),
              Text(task.taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _detailLabel('Description'),
              Text(task.taskDescription),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Close')),
                  if (isSelfCreated && task.status != 'completed') ...[
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () { Get.back(); _showEditTaskDialog(task, context); }, child: const Text('Edit')),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
  );

  void _showStatusUpdateDialog(TaskModel task) {
    if (task.isOverdue) return;
    String selectedStatus = task.status;
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (v) { if (v != null) selectedStatus = v; },
            ),
            const SizedBox(height: 16),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateTaskStatus(task.id, selectedStatus, notes: notesController.text);
              Get.back();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selPriority = 'medium';
    Rx<DateTime> selDueDate = DateTime.now().add(const Duration(days: 7)).obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Personal Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  controller.createSelfTask(
                    title: titleController.text,
                    description: descController.text,
                    priority: selPriority,
                    dueDate: selDueDate.value,
                  );
                  Get.back();
                },
                child: const Text('Create Task'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(TaskModel task, BuildContext context) {
    final titleController = TextEditingController(text: task.taskTitle);
    final descController = TextEditingController(text: task.taskDescription);
    String selPriority = task.priority;
    Rx<DateTime> selDueDate = task.dueDate.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateSelfTask(
                taskId: task.id,
                title: titleController.text,
                description: descController.text,
                priority: selPriority,
                dueDate: selDueDate.value,
              );
              Get.back();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(TaskModel task) {
    Get.defaultDialog(
      title: 'Delete Task?',
      middleText: 'This will permanently remove "${task.taskTitle}".',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteSelfTask(task.id);
        Get.back();
      },
    );
  }
}