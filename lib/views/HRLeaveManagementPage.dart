// lib/views/HRLeaveManagementPage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/HRLeaveManagementController.dart';
import '../widgets/LeaveFilterBottomSheet.dart';

class HRLeaveManagementPage extends GetView<HRLeaveManagementController> {
  const HRLeaveManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: controller.scrollController,
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

          // Search, Filter, and Export Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                16,
                isMobile ? 16 : 24,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 12),
                      _buildFilterButton(context),
                      const SizedBox(width: 8),
                      _buildExportButton(isMobile),
                    ],
                  ),
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

          // Leave Requests List
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          Obx(() {
            if (controller.isLoading.value &&
                controller.filteredRequests.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.filteredRequests.isEmpty) {
              return SliverFillRemaining(
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
                      (context, index) => _buildLeaveRequestCard(
                    controller.filteredRequests[index],
                    isMobile,
                  ),
                  childCount: controller.filteredRequests.length,
                ),
              ),
            );
          }),

          // Loading More Indicator
          Obx(() {
            if (controller.isLoadingMore.value) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Leave Management',
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        IconButton(
          onPressed: controller.refreshLeaveRequests,
          icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildStatistics(bool isMobile) {
    return Obx(() => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard(
          'Total',
          controller.totalRequests.toString(),
          Icons.inbox,
          Colors.blue,
          isMobile,
        ),
        _buildStatCard(
          'Pending',
          controller.pendingRequests.toString(),
          Icons.schedule,
          Colors.orange,
          isMobile,
        ),
        _buildStatCard(
          'Approved',
          controller.approvedRequests.toString(),
          Icons.check_circle,
          Colors.green,
          isMobile,
        ),
        _buildStatCard(
          'Rejected',
          controller.rejectedRequests.toString(),
          Icons.cancel,
          Colors.red,
          isMobile,
        ),
      ],
    ));
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      bool isMobile,
      ) {
    return Container(
      width: isMobile ? (Get.width - 44) / 2 : 140,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => controller.searchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search employees...',
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
                builder: (context) => const LeaveFilterBottomSheet(),
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

  Widget _buildExportButton(bool isMobile) {
    return Obx(() => ElevatedButton.icon(
      onPressed: controller.filteredRequests.isEmpty
          ? null
          : controller.exportToExcel,
      icon: const Icon(Icons.download, size: 18),
      label: Text(isMobile ? '' : 'Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 12,
        ),
      ),
    ));
  }

  Widget _buildActiveFilters() {
    return Obx(() {
      final activeFilters = <Widget>[];

      if (controller.statusFilter.value != 'all') {
        activeFilters.add(_buildFilterChipDisplay(
          'Status: ${controller.statusFilter.value.capitalizeFirst}',
              () => controller.statusFilter.value = 'all',
        ));
      }

      if (controller.selectedMonth.value != 'all') {
        final monthLabel = controller.monthOptions.firstWhere(
              (m) => m['value'] == controller.selectedMonth.value,
        )['label']!;
        activeFilters.add(_buildFilterChipDisplay(
          'Month: $monthLabel',
              () => controller.selectedMonth.value = 'all',
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
            Icon(
              controller.leaveRequests.isEmpty
                  ? Icons.inbox
                  : Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              controller.leaveRequests.isEmpty
                  ? 'No leave requests yet'
                  : 'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.leaveRequests.isEmpty
                  ? 'Leave requests will appear here'
                  : 'Try a different search term or filter',
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

  Widget _buildLeaveRequestCard(dynamic request, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Employee Info
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6),
                  radius: 20,
                  child: Text(
                    request.employeeEmail[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName ?? request.employeeEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.employeeId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: controller
                        .getStatusColor(request.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.getStatusIcon(request.status),
                        size: 14,
                        color: controller.getStatusColor(request.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: controller.getStatusColor(request.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Leave Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      request.leaveType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${controller.formatDate(request.startDate)} - ${controller.formatDate(request.endDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timelapse,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${request.numberOfDays} day${request.numberOfDays > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (request.documentUrl != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => controller.viewDocument(request.documentUrl!),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file,
                              size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            request.documentName ?? 'View Document',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons (Only for pending requests)
          if (request.status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(request.id),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          controller.approveLeaveRequest(request.id),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rejection Reason (if rejected)
          if (request.status == 'rejected' &&
              request.rejectionReason != null) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.rejectionReason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please provide a reason',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade400,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              controller.rejectLeaveRequest(
                  requestId, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}