// lib/widgets/EmployeeFilterBottomSheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/EmployeePerformanceController.dart';

class EmployeeFilterBottomSheet extends StatelessWidget {
  const EmployeeFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeePerformanceController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF3B82F6), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Filter Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Task Type Filter
          const Text(
            'Task Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                controller,
                'All Tasks',
                'all',
                controller.allTasks.length,
                isTaskType: true,
              ),
              _buildFilterChip(
                controller,
                'HR Assigned',
                'hr_assigned',
                controller.hrAssignedTasks.length,
                isTaskType: true,
              ),
              _buildFilterChip(
                controller,
                'My Tasks',
                'self_created',
                controller.selfCreatedTasks.length,
                isTaskType: true,
              ),
            ],
          )),
          const SizedBox(height: 20),

          // Status Filter
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(controller, 'All', 'all', 0, isStatus: true),
              _buildFilterChip(controller, 'Pending', 'pending', 0, isStatus: true),
              _buildFilterChip(controller, 'In Progress', 'in_progress', 0, isStatus: true),
              _buildFilterChip(controller, 'Completed', 'completed', 0, isStatus: true),
              _buildFilterChip(controller, 'Overdue', 'overdue', 0, isStatus: true),
            ],
          )),
          const SizedBox(height: 20),

          // Priority Filter
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(controller, 'All', 'all', 0, isPriority: true),
              _buildFilterChip(controller, 'Low', 'low', 0, isPriority: true),
              _buildFilterChip(controller, 'Medium', 'medium', 0, isPriority: true),
              _buildFilterChip(controller, 'High', 'high', 0, isPriority: true),
              _buildFilterChip(controller, 'Urgent', 'urgent', 0, isPriority: true),
            ],
          )),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.resetFilters();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Reset Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      EmployeePerformanceController controller,
      String label,
      String value,
      int count, {
        bool isTaskType = false,
        bool isStatus = false,
        bool isPriority = false,
      }) {
    bool isSelected = false;

    if (isTaskType) {
      isSelected = controller.taskTypeFilter.value == value;
    } else if (isStatus) {
      isSelected = controller.statusFilter.value == value;
    } else if (isPriority) {
      isSelected = controller.priorityFilter.value == value;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isTaskType && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (isTaskType) {
          controller.taskTypeFilter.value = value;
        } else if (isStatus) {
          controller.statusFilter.value = value;
        } else if (isPriority) {
          controller.priorityFilter.value = value;
        }
      },
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
      checkmarkColor: const Color(0xFF3B82F6),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}