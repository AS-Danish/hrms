// lib/views/EmployeePerformancePage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/EmployeePerformanceController.dart';
import '../models/TaskModel.dart';

class EmployeePerformancePage extends GetView<EmployeePerformanceController> {
  const EmployeePerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 24),
                  _buildStatistics(isMobile),
                  const SizedBox(height: 24),
                  _buildTabBar(isMobile),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilters(isMobile),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.filteredTasks.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No Tasks Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Try adjusting your filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTaskCard(context, controller.filteredTasks[index], isMobile),
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
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Obx(() => Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Performance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(controller.currentUserName, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
          _buildStatCard('Total Tasks', stats['total']!, Icons.task_alt, Colors.blue, isMobile),
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
          Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('All Tasks', 'all', controller.allTasks.length),
          ),
          Expanded(
            child: _buildTabButton('HR Assigned', 'hr_assigned', controller.hrAssignedTasks.length),
          ),
          Expanded(
            child: _buildTabButton('My Tasks', 'self_created', controller.selfCreatedTasks.length),
          ),
        ],
      ),
    ));
  }

  Widget _buildTabButton(String label, String value, int count) {
    final isSelected = controller.taskTypeFilter.value == value;
    return InkWell(
      onTap: () => controller.taskTypeFilter.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => controller.searchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search tasks by title, description...',
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

  Widget _buildFilters(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('All', 'all', true),
            _buildFilterChip('Pending', 'pending', true),
            _buildFilterChip('In Progress', 'in_progress', true),
            _buildFilterChip('Completed', 'completed', true),
            _buildFilterChip('Overdue', 'overdue', true),
          ],
        )),
        const SizedBox(height: 16),
        const Text('Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('All', 'all', false),
            _buildFilterChip('Low', 'low', false),
            _buildFilterChip('Medium', 'medium', false),
            _buildFilterChip('High', 'high', false),
            _buildFilterChip('Urgent', 'urgent', false),
          ],
        )),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isStatus) {
    final isSelected = isStatus ? controller.statusFilter.value == value : controller.priorityFilter.value == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => isStatus ? controller.statusFilter.value = value : controller.priorityFilter.value = value,
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.15),
      checkmarkColor: const Color(0xFF3B82F6),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
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
        side: BorderSide(
          color: isOverdue ? Colors.red.shade200 : const Color(0xFFE2E8F0),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetailsDialog(task, isSelfCreated, context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Priority Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.taskTitle,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelfCreated)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person, size: 12, color: Colors.purple.shade700),
                                    const SizedBox(width: 4),
                                    Text('Self', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.taskDescription,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(task.priority.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Assigned By and Status Row
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isSelfCreated ? 'Self-assigned' : 'Assigned by ${task.assignedByName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(controller.getStatusIcon(task.status), size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(task.status.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Due Date and Days Left Row
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${controller.formatDate(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red.shade700 : Colors.grey.shade700,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (task.daysUntilDue >= 0 && task.status != 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.daysUntilDue <= 2 ? Colors.red.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.daysUntilDue} days left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.daysUntilDue <= 2 ? Colors.red.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (isOverdue && task.status != 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 12, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Overdue',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions Row
              Row(
                children: [
                  if (canUpdateStatus)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusUpdateDialog(task),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Update Status'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  if (isOverdue && task.status != 'completed')
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Cannot Update (Overdue)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (canUpdateStatus && isSelfCreated) const SizedBox(width: 8),
                  if (isSelfCreated)
                    IconButton(
                      onPressed: () => _showEditTaskDialog(task, context),
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                      tooltip: 'Edit Task',
                    ),
                  if (isSelfCreated)
                    IconButton(
                      onPressed: () => _confirmDeleteTask(task),
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
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
    String selPriority = 'medium';
    Rx<DateTime> selDueDate = DateTime.now().add(const Duration(days: 7)).obs;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_task, color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Create Personal Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                Obx(() => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selDueDate.value,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) selDueDate.value = picked;
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(selDueDate.value)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                )),
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
                        if (titleController.text.isEmpty || descController.text.isEmpty) {
                          Get.snackbar('Error', 'Please fill all required fields', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        // **********************************************
                        // CORRECTED CALL: Create new task
                        // **********************************************
                        controller.createSelfTask(
                          title: titleController.text,
                          description: descController.text,
                          priority: selPriority,
                          dueDate: selDueDate.value,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Create Task', style: TextStyle(color: Colors.white)),
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
    if (task.isOverdue) {
      Get.snackbar(
        'Cannot Update',
        'This task is overdue and cannot be updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    String selectedStatus = task.status;
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Update Task Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(task.taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              const Text('New Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (v) {
                  if (v != null) selectedStatus = v;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes about the status update...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      controller.updateTaskStatus(
                        task.id,
                        selectedStatus,
                        notes: notesController.text,
                      );
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsDialog(TaskModel task, bool isSelfCreated, BuildContext context) {
    final canUpdateStatus = task.status != 'completed' && !task.isOverdue;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: controller.getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.task, color: controller.getPriorityColor(task.priority), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Task Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(task.taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(task.taskDescription, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.getPriorityColor(task.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: controller.getPriorityColor(task.priority).withOpacity(0.3)),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: controller.getPriorityColor(task.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.getStatusColor(task.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: controller.getStatusColor(task.status).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(controller.getStatusIcon(task.status), size: 14, color: controller.getStatusColor(task.status)),
                                const SizedBox(width: 4),
                                Text(
                                  task.status.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: controller.getStatusColor(task.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assigned By', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(
                            isSelfCreated ? 'Self-assigned' : task.assignedByName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              const Text('Assigned Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(controller.formatDate(task.assignedDate), style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event, size: 18, color: task.isOverdue ? Colors.red.shade600 : Colors.grey.shade600),
                              const SizedBox(width: 8),
                              const Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.formatDate(task.dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: task.isOverdue ? Colors.red.shade700 : Colors.black,
                              fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (task.daysUntilDue >= 0 && task.status != 'completed')
                            Text(
                              '${task.daysUntilDue} days left',
                              style: TextStyle(
                                fontSize: 12,
                                color: task.daysUntilDue <= 2 ? Colors.red.shade700 : Colors.grey.shade600,
                                fontWeight: task.daysUntilDue <= 2 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          if (task.isOverdue && task.status != 'completed')
                            Text(
                              'Overdue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.status == 'completed' && task.completedDate != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      const Text('Completed On', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(controller.formatDate(task.completedDate!), style: const TextStyle(fontSize: 14)),
                  if (task.completionNotes != null && task.completionNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Completion Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(task.completionNotes!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                    if (canUpdateStatus) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showStatusUpdateDialog(task);
                        },
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text('Update Status', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                    if (isSelfCreated && task.status != 'completed') ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showEditTaskDialog(task, context);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        label: const Text('Edit Task', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade500,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(TaskModel task) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Task?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this task?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.taskTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSelfTask(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(TaskModel task, BuildContext context) {
    final titleController = TextEditingController(text: task.taskTitle);
    final descController = TextEditingController(text: task.taskDescription);
    String selPriority = task.priority;
    Rx<DateTime> selDueDate = task.dueDate.obs;

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
                    Icon(Icons.edit, color: Color(0xFF3B82F6), size: 28),
                    SizedBox(width: 12),
                    Text('Edit Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                Obx(() => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selDueDate.value,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) selDueDate.value = picked;
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(selDueDate.value)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                )),
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
                        if (titleController.text.isEmpty || descController.text.isEmpty) {
                          Get.snackbar('Error', 'Please fill all required fields', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        // **********************************************
                        // CORRECTED CALL: Update existing task
                        // **********************************************
                        controller.updateSelfTask(
                          taskId: task.id,
                          title: titleController.text,
                          description: descController.text,
                          priority: selPriority,
                          dueDate: selDueDate.value,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Update Task', style: TextStyle(color: Colors.white)),
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
}