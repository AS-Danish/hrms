import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms/controllers/LoginController.dart';

import '../Layout/MainLayout.dart';
import '../auth/login_page.dart';
import '../binding/HRLeaveManagementBinding.dart';
import '../binding/HRManagementBinding.dart';
import '../binding/LeaveRequestBinding.dart';
import '../controllers/RegisterController.dart';
import '../controllers/LeaveRequestController.dart';
import '../views/HRLeaveManagementPage.dart';
import '../views/HRManagementPage.dart';
import '../views/LeaveRequestPage.dart';
import '../views/MyLeaves.dart';
import '../views/DashboardPage.dart';

class NavBar extends StatefulWidget {
  final String? currentRoute;

  const NavBar({super.key, this.currentRoute});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with SingleTickerProviderStateMixin {
  String _selectedRoute = '/dashboard';
  String _userRole = '';
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute ?? '/dashboard';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserRole();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? '';
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(NavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRoute != null && widget.currentRoute != _selectedRoute) {
      setState(() {
        _selectedRoute = widget.currentRoute!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDesktop),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
              )
                  : FadeTransition(
                opacity: _animationController,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: _buildMenuItems(context),
                ),
              ),
            ),
            _buildBottomSection(context, isDesktop),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    List<Widget> menuItems = [];

    menuItems.add(_buildSectionHeader("MAIN MENU"));

    menuItems.add(
      _buildDrawerItem(
        context,
        icon: Icons.dashboard_rounded,
        title: "Dashboard",
        route: '/dashboard',
        onTap: () => _navigateToPage(
          context,
          '/dashboard',
          'Dashboard',
          const Dashboard(),
        ),
      ),
    );

    switch (_userRole.toLowerCase()) {
      case 'admin':
        menuItems.add(_buildSectionHeader("ADMINISTRATION"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "Employee Management",
            route: '/employee',
            onTap: () => _navigateToPage(
              context,
              '/employee',
              'Employee Management',
              const HRManagementPage(),
              binding: HRManagementBinding(),
            ),
          ),
        ]);
        break;

      case 'hr':
        menuItems.add(_buildSectionHeader("HUMAN RESOURCES"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.work_rounded,
            title: "Job Management",
            route: '/jobs',
            onTap: () => _navigateToPage(
              context,
              '/jobs',
              'Job Management',
              const Center(child: Text('Job Management - Coming Soon')),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event_available_rounded,
            title: "Leave Management",
            route: '/leave-management',
            onTap: () => _navigateToPage(
              context,
              '/leave-management',
              'Leave Management',
              const HRLeaveManagementPage(),
              binding: HRLeaveManagementBinding(),
            ),
          ),
        ]);
        break;

      case 'manager':
        menuItems.add(_buildSectionHeader("MANAGEMENT"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "Employee Management",
            route: '/employee',
            onTap: () => _navigateToPage(
              context,
              '/employee',
              'Employee Management',
              const HRManagementPage(),
              binding: HRManagementBinding(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.monetization_on_rounded,
            title: "Payroll Management",
            route: '/payroll',
            onTap: () => _navigateToPage(
              context,
              '/payroll',
              'Payroll Management',
              const Center(child: Text('Payroll Management - Coming Soon')),
            ),
          ),
        ]);
        break;

      case 'employee':
        menuItems.add(_buildSectionHeader("MY WORKSPACE"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today_rounded,
            title: "My Attendance",
            route: '/attendance',
            onTap: () => _navigateToPage(
              context,
              '/attendance',
              'My Attendance',
              const Center(child: Text('My Attendance - Coming Soon')),
            ),
          ),
        ]);

        // LEAVE SECTION FOR EMPLOYEES
        menuItems.add(_buildSectionHeader("LEAVE MANAGEMENT"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: "Request Leave",
            route: '/request-leave',
            onTap: () => _navigateToPage(
              context,
              '/request-leave',
              'Request Leave',
              const LeaveRequestPage(),
              binding: LeaveRequestBinding(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history_rounded,
            title: "My Leaves",
            route: '/my-leaves',
            onTap: () => _navigateToPage(
              context,
              '/my-leaves',
              'My Leaves',
              const MyLeavesPage(),
              binding: LeaveRequestBinding(),
            ),
          ),
        ]);
        break;

      default:
        menuItems.add(
          _buildDrawerItem(
            context,
            icon: Icons.settings_rounded,
            title: "Settings",
            route: '/settings',
            onTap: () => _navigateToPage(
              context,
              '/settings',
              'Settings',
              const Center(child: Text('Settings - Coming Soon')),
            ),
          ),
        );
    }

    return menuItems;
  }

  // NEW UNIFIED NAVIGATION METHOD
  void _navigateToPage(
      BuildContext context,
      String route,
      String title,
      Widget child, {
        Bindings? binding,
      }) {
    // Update selected route
    setState(() {
      _selectedRoute = route;
    });

    // Close drawer on mobile
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (!isDesktop) {
      Get.back();
    }

    // Navigate to the new page
    Get.offAll(
          () => MainLayout(
        currentRoute: route,
        title: title,
        child: child,
      ),
      binding: binding,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "User";
    final email = user?.email ?? "user@example.com";
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 24,
        24,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF2196F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_userRole.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoleIcon(_userRole),
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
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

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'hr':
        return Icons.people_alt_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'employee':
        return Icons.badge_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
        required VoidCallback onTap,
        Color? iconColor,
      }) {
    final isSelected = _selectedRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF2196F3).withOpacity(0.1),
          highlightColor: const Color(0xFF2196F3).withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1.5,
              )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2196F3).withOpacity(0.15)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF1976D2)
                        : (iconColor ?? Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleLogout(context, isDesktop),
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.red.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, bool isDesktop) {
    if (!isDesktop) {
      Navigator.pop(context);
    }
    _showLogoutDialog(context);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1976D2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              Get.delete<LoginController>();
              Get.delete<RegisterController>();

              await FirebaseAuth.instance.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}