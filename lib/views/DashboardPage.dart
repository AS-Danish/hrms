import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // REMOVED MainLayout wrapper - Dashboard is just the content now!
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(context),
            const SizedBox(height: 28),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 14),
            _buildQuickActions(context),
            const SizedBox(height: 28),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 14),
            _buildRecentActivity(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final cardWidth = isSmallScreen
        ? screenWidth - 32
        : (screenWidth - 48) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 120,
          ),
          child: _buildStatCard(
            icon: Icons.people,
            title: 'Employees',
            value: '248',
            color: const Color(0xFF1976D2),
            trend: '+12 this month',
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 120,
          ),
          child: _buildStatCard(
            icon: Icons.work_outline,
            title: 'Open Positions',
            value: '34',
            color: const Color(0xFF388E3C),
            trend: '+5 new',
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 120,
          ),
          child: _buildStatCard(
            icon: Icons.assignment_outlined,
            title: 'Applications',
            value: '156',
            color: const Color(0xFFF57C00),
            trend: '+23 today',
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 120,
          ),
          child: _buildStatCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payroll',
            value: '\$45K',
            color: const Color(0xFF7B1FA2),
            trend: '+8% vs last',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final cardWidth = isSmallScreen
        ? (screenWidth - 56) / 2
        : (screenWidth - 64) / 3;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.person_add_alt,
            label: 'Add Employee',
            color: const Color(0xFF1976D2),
            onTap: () {},
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.article_outlined,
            label: 'Post Job',
            color: const Color(0xFF388E3C),
            onTap: () {},
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.receipt_long,
            label: 'Payroll',
            color: const Color(0xFF7B1FA2),
            onTap: () {},
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.bar_chart,
            label: 'Reports',
            color: const Color(0xFFF57C00),
            onTap: () {},
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.calendar_month,
            label: 'Schedule',
            color: const Color(0xFF0097A7),
            onTap: () {},
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: 100,
          ),
          child: _buildQuickActionCard(
            icon: Icons.more_horiz,
            label: 'More',
            color: const Color(0xFF616161),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.person_add_alt,
            title: 'New employee added',
            subtitle: 'John Doe joined the team',
            time: '2h ago',
            color: const Color(0xFF1976D2),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildActivityItem(
            icon: Icons.work_outline,
            title: 'Job posted',
            subtitle: 'Senior Flutter Developer',
            time: '5h ago',
            color: const Color(0xFF388E3C),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildActivityItem(
            icon: Icons.receipt_long,
            title: 'Payroll processed',
            subtitle: 'Monthly payroll completed',
            time: '1d ago',
            color: const Color(0xFF7B1FA2),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildActivityItem(
            icon: Icons.assignment_outlined,
            title: 'New applications',
            subtitle: '15 applications received',
            time: '2d ago',
            color: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}