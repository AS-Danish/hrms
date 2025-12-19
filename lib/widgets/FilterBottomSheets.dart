// lib/widgets/FilterBottomSheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/HRPerformanceController.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HRPerformanceController>();

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

          // Employee Filter
          const Text(
            'Employee',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedEmployeeId.value,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: 'all',
                child: Text('All Employees'),
              ),
              ...controller.employees.map((emp) => DropdownMenuItem<String>(
                value: emp['id'] as String,
                child: Text(
                  emp['name'] as String,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
            ],
            onChanged: (value) {
              if (value != null) {
                controller.selectedEmployeeId.value = value;
              }
            },
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
              _buildFilterChip(
                controller,
                'All',
                'all',
                true,
              ),
              _buildFilterChip(
                controller,
                'Pending',
                'pending',
                true,
              ),
              _buildFilterChip(
                controller,
                'In Progress',
                'in_progress',
                true,
              ),
              _buildFilterChip(
                controller,
                'Completed',
                'completed',
                true,
              ),
              _buildFilterChip(
                controller,
                'Overdue',
                'overdue',
                true,
              ),
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
              _buildFilterChip(
                controller,
                'All',
                'all',
                false,
              ),
              _buildFilterChip(
                controller,
                'Low',
                'low',
                false,
              ),
              _buildFilterChip(
                controller,
                'Medium',
                'medium',
                false,
              ),
              _buildFilterChip(
                controller,
                'High',
                'high',
                false,
              ),
              _buildFilterChip(
                controller,
                'Urgent',
                'urgent',
                false,
              ),
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
      HRPerformanceController controller,
      String label,
      String value,
      bool isStatus,
      ) {
    final isSelected = isStatus
        ? controller.statusFilter.value == value
        : controller.priorityFilter.value == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (isStatus) {
          controller.statusFilter.value = value;
        } else {
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