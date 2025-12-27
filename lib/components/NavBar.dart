import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hrms/binding/EmployeePerformanceBinding.dart';
import 'package:hrms/binding/HRPerformanceBinding.dart';
import 'package:hrms/binding/UserManagementBinding.dart';
import 'package:hrms/views/EmployeePerformancePage.dart';
import 'package:hrms/views/HRPerformancePage.dart';
import 'package:hrms/views/HRUserManagementPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms/controllers/LoginController.dart';
import '../Layout/MainLayout.dart';
import '../auth/login_page.dart';
import '../binding/HRAttendanceBinding.dart';
import '../binding/HRLeaveManagementBinding.dart';
import '../binding/HRManagementBinding.dart';
import '../binding/LeaveRequestBinding.dart';
import '../views/HRAttendancePage.dart';
import '../views/HRLeaveManagementPage.dart';
import '../views/HRManagementPage.dart';
import '../views/LeaveRequestPage.dart';
import '../views/MyLeaves.dart';
import '../views/DashboardPage.dart';

class NavBar extends StatefulWidget {
  final String? currentRoute;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const NavBar({
    super.key,
    this.currentRoute,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with SingleTickerProviderStateMixin {
  String _selectedRoute = '/dashboard';
  String _userRole = '';
  bool _isLoading = true;
  late AnimationController _animationController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute ?? '/dashboard';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserRole();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole') ?? '';

      // Debug print to check if role is loaded
      print('NavBar - Loaded user role: $role');

      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
        // Animate after loading is complete
        _animationController.forward();
      }

      // If role is still empty, try again after a short delay
      if (role.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        final retryRole = prefs.getString('userRole') ?? '';
        print('NavBar - Retry loaded role: $retryRole');
        if (mounted && retryRole.isNotEmpty) {
          setState(() {
            _userRole = retryRole;
          });
        }
      }
    } catch (e) {
      print('NavBar - Error loading user role: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final effectiveCollapsed = isDesktop && widget.isCollapsed;

    // On desktop, return a Container (sidebar). On mobile, return a Drawer
    if (isDesktop) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: effectiveCollapsed ? 80 : 280,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isDesktop, effectiveCollapsed),
                if (isDesktop && !effectiveCollapsed)
                  _buildCollapseButton(effectiveCollapsed),
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
                      children: _buildMenuItems(context, effectiveCollapsed),
                    ),
                  ),
                ),
                _buildBottomSection(context, isDesktop, effectiveCollapsed),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile: Return standard Drawer
      return Drawer(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isDesktop, effectiveCollapsed),
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
                    children: _buildMenuItems(context, effectiveCollapsed),
                  ),
                ),
              ),
              _buildBottomSection(context, isDesktop, effectiveCollapsed),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCollapseButton(bool isCollapsed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleCollapse,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Collapse Menu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_right_rounded
                      : Icons.keyboard_arrow_left_rounded,
                  color: const Color(0xFF1976D2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, bool isCollapsed) {
    List<Widget> menuItems = [];

    // Always show Dashboard
    if (!isCollapsed) {
      menuItems.add(_buildSectionHeader("MAIN MENU"));
    }

    menuItems.add(
      _buildDrawerItem(
        context,
        icon: Icons.dashboard_rounded,
        title: "Dashboard",
        route: '/dashboard',
        isCollapsed: isCollapsed,
        onTap: () => _navigateToPage(
          context,
          '/dashboard',
          'Dashboard',
          const Dashboard(),
        ),
      ),
    );

    // Debug: Print current role
    print('NavBar - Building menu for role: $_userRole');

    // Build menu items based on user role
    switch (_userRole.toLowerCase()) {
      case 'admin':
        if (!isCollapsed) menuItems.add(_buildSectionHeader("ADMINISTRATION"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "User Management",
            route: '/user',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/user',
              'User Management',
              const UserManagementPage(),
              binding: UsermanagementBinding(),
            ),
          ),
        ]);
        break;

      case 'hr':
        if (!isCollapsed) menuItems.add(_buildSectionHeader("HUMAN RESOURCES"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.calendar_month,
            title: "Attendance Management",
            route: '/hr-attendance',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/hr-attendance',
              'Attendance Management',
              const HRAttendancePage(),
              binding: HRAttendanceBinding(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event_available_rounded,
            title: "Leave Management",
            route: '/leave-management',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/leave-management',
              'Leave Management',
              const HRLeaveManagementPage(),
              binding: HRLeaveManagementBinding(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.track_changes_rounded,
            title: "Performance Tracking",
            route: '/performance-tracking',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/performance-tracking',
              'Performance Tracking',
              const HRPerformancePage(),
              binding: HRPerformanceBinding(),
            ),
          ),
        ]);
        break;

      case 'manager':
        if (!isCollapsed) menuItems.add(_buildSectionHeader("MANAGEMENT"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "Employee Management",
            route: '/employee',
            isCollapsed: isCollapsed,
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
            isCollapsed: isCollapsed,
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
        if (!isCollapsed) menuItems.add(_buildSectionHeader("MY WORKSPACE"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today_rounded,
            title: "My Attendance",
            route: '/attendance',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/attendance',
              'My Attendance',
              const Center(child: Text('My Attendance - Coming Soon')),
            ),
          ),
        ]);

        if (!isCollapsed) menuItems.add(_buildSectionHeader("LEAVE MANAGEMENT"));
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: "Request Leave",
            route: '/request-leave',
            isCollapsed: isCollapsed,
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
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/my-leaves',
              'My Leaves',
              const MyLeavesPage(),
              binding: LeaveRequestBinding(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.work_rounded,
            title: "Performance Tracking",
            route: '/performance-tracking-emp',
            isCollapsed: isCollapsed,
            onTap: () => _navigateToPage(
              context,
              '/performance-tracking-emp',
              'Performance Tracking',
              const EmployeePerformancePage(),
              binding: EmployeePerformanceBinding()
            ),
          ),
        ]);
        break;

      default:
      // If role is empty or unknown, show a message
        if (!isCollapsed && _userRole.isEmpty && !_isLoading) {
          menuItems.add(
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your menu...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        break;
    }

    return menuItems;
  }

  void _navigateToPage(
      BuildContext context,
      String route,
      String title,
      Widget child, {
        Bindings? binding,
      }) {
    setState(() {
      _selectedRoute = route;
    });

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (!isDesktop) {
      Get.back();
    }

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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isCollapsed) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "User";
    final email = user?.email ?? "user@example.com";
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 16 : 24,
        MediaQuery.of(context).padding.top + 24,
        isCollapsed ? 16 : 24,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isCollapsed ? 24 : 36,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: isCollapsed ? 20 : 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ),
          ),
          if (!isCollapsed) ...[
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
          if (isCollapsed && isDesktop) ...[
            const SizedBox(height: 12),
            IconButton(
              onPressed: widget.onToggleCollapse,
              icon: const Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Colors.white,
              ),
              tooltip: 'Expand Menu',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
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
        required bool isCollapsed,
        Color? iconColor,
      }) {
    final isSelected = _selectedRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Tooltip(
        message: isCollapsed ? title : '',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: const Color(0xFF2196F3).withOpacity(0.15),
            highlightColor: const Color(0xFF2196F3).withOpacity(0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.15),
                    const Color(0xFF2196F3).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.4),
                  width: 2,
                )
                    : null,
              ),
              child: Row(
                mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF2196F3),
                        ],
                      )
                          : null,
                      color: isSelected ? null : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : (iconColor ?? Colors.grey.shade700),
                    ),
                  ),
                  if (!isCollapsed) ...[
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
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 5,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1976D2),
                              Color(0xFF2196F3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isDesktop, bool isCollapsed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: isCollapsed ? 'Logout' : '',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleLogout(context, isDesktop),
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.red.withOpacity(0.15),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 8 : 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            size: 22,
                            color: Colors.red.shade700,
                          ),
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              Get.delete<LoginController>();

              await FirebaseAuth.instance.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}