// lib/widgets/LeaveFilterBottomSheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/HRLeaveManagementController.dart';

class LeaveFilterBottomSheet extends StatelessWidget {
  const LeaveFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HRLeaveManagementController>();

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
                    'Filter Leave Requests',
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
              _buildFilterChip(controller, 'All', 'all', true),
              _buildFilterChip(controller, 'Pending', 'pending', true),
              _buildFilterChip(controller, 'Approved', 'approved', true),
              _buildFilterChip(controller, 'Rejected', 'rejected', true),
            ],
          )),
          const SizedBox(height: 20),

          // Month Filter
          const Text(
            'Month',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: controller.selectedMonth.value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: controller.monthOptions.map((month) {
                return DropdownMenuItem(
                  value: month['value'],
                  child: Text(
                    month['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedMonth.value = value;
                }
              },
            ),
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
      HRLeaveManagementController controller,
      String label,
      String value,
      bool isStatus,
      ) {
    final isSelected = controller.statusFilter.value == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.statusFilter.value = value;
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