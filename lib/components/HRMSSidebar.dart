import 'package:flutter/material.dart';

class HRMSSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool)? onCollapsedChanged;

  const HRMSSidebar({
    Key? key,
    this.isCollapsed = false,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  State<HRMSSidebar> createState() => _HRMSSidebarState();
}

class _HRMSSidebarState extends State<HRMSSidebar> {
  String selectedItem = 'Dashboard';

  final List<SidebarItem> menuItems = [
    SidebarItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      title: 'Dashboard',
    ),
    SidebarItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      title: 'Employees',
    ),
    SidebarItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      title: 'Attendance',
    ),
    SidebarItem(
      icon: Icons.access_time_outlined,
      selectedIcon: Icons.access_time,
      title: 'Leave Management',
    ),
    SidebarItem(
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      title: 'Payroll',
    ),
    SidebarItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      title: 'Reports',
    ),
    SidebarItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      title: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 768;
    final sidebarWidth = widget.isCollapsed ? 70.0 : 250.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(isWeb),

          const SizedBox(height: 20),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedItem == item.title;

                return _buildMenuItem(item, isSelected);
              },
            ),
          ),

          // User Profile Section
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCollapsed) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HRMS Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
          if (isWeb)
            IconButton(
              icon: Icon(
                widget.isCollapsed ? Icons.menu : Icons.menu_open,
                color: Colors.white70,
              ),
              onPressed: () {
                widget.onCollapsedChanged?.call(!widget.isCollapsed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarItem item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              selectedItem = item.title;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF3B82F6), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.white70,
                  size: 22,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF3B82F6),
            child: const Text(
              'JD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'HR Manager',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.logout,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;

  SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
  });
}

// Example usage in a dashboard layout:
class DashboardLayout extends StatefulWidget {
  const DashboardLayout({Key? key}) : super(key: key);

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 768;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: isMobile
          ? Drawer(
        child: HRMSSidebar(
          isCollapsed: false,
          onCollapsedChanged: (collapsed) {
            setState(() {
              isSidebarCollapsed = collapsed;
            });
          },
        ),
      )
          : null,
      appBar: isMobile
          ? AppBar(
        title: const Text('HRMS Dashboard'),
        backgroundColor: const Color(0xFF1E293B),
      )
          : null,
      body: Row(
        children: [
          if (isWeb)
            HRMSSidebar(
              isCollapsed: isSidebarCollapsed,
              onCollapsedChanged: (collapsed) {
                setState(() {
                  isSidebarCollapsed = collapsed;
                });
              },
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back, John! Here\'s what\'s happening today.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Add your dashboard content here
                  Expanded(
                    child: Center(
                      child: Text(
                        'Dashboard Content Goes Here',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}