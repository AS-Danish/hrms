import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms/controllers/LoginController.dart';

import '../auth/login_page.dart';
import '../controllers/RegisterController.dart';

class NavBar extends StatefulWidget {
  final String? currentRoute;

  const NavBar({super.key, this.currentRoute});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  String _selectedRoute = '/dashboard';
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute ?? '/dashboard';
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? '';
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
        color: Colors.white,
        child: Column(
          children: [
            // Enhanced Header with Blue Theme
            _buildHeader(isDesktop),

            // Menu Items
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: EdgeInsets.zero,
                children: _buildMenuItems(context),
              ),
            ),

            // Logout at Bottom
            const Divider(height: 1),
            _buildDrawerItem(
              context,
              icon: Icons.logout_rounded,
              title: "Logout",
              route: '/logout',
              iconColor: Colors.red.shade600,
              onTap: () => _handleLogout(context, isDesktop),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    List<Widget> menuItems = [];

    // Common Dashboard for all roles
    menuItems.add(
      _buildDrawerItem(
        context,
        icon: Icons.dashboard_rounded,
        title: "Dashboard",
        route: '/dashboard',
        onTap: () => _navigateTo(context, '/dashboard'),
      ),
    );

    // Role-based menu items
    switch (_userRole.toLowerCase()) {
      case 'admin':
      // Admin sees Employee Management and Settings
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "Employee Management",
            route: '/employee',
            onTap: () => _navigateTo(context, '/employee'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings_rounded,
            title: "Settings",
            route: '/settings',
            onTap: () => _navigateTo(context, '/settings'),
          ),
        ]);
        break;

      case 'hr':
      // HR sees Job Management and Application Tracking
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.work_rounded,
            title: "Job Management",
            route: '/jobs',
            onTap: () => _navigateTo(context, '/jobs'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.track_changes_rounded,
            title: "Application Tracking",
            route: '/tracking',
            onTap: () => _navigateTo(context, '/tracking'),
          ),
        ]);
        break;

      case 'manager':
      // Manager sees Payroll Management and Employee Management
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people_rounded,
            title: "Employee Management",
            route: '/employee',
            onTap: () => _navigateTo(context, '/employee'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.monetization_on_rounded,
            title: "Payroll Management",
            route: '/payroll',
            onTap: () => _navigateTo(context, '/payroll'),
          ),
        ]);
        break;

      case 'employee':
      // Employee sees limited options
        menuItems.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.person_rounded,
            title: "My Profile",
            route: '/profile',
            onTap: () => _navigateTo(context, '/profile'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today_rounded,
            title: "My Attendance",
            route: '/attendance',
            onTap: () => _navigateTo(context, '/attendance'),
          ),
        ]);
        break;

      default:
      // If role is not set or unknown, show minimal options
        menuItems.add(
          _buildDrawerItem(
            context,
            icon: Icons.settings_rounded,
            title: "Settings",
            route: '/settings',
            onTap: () => _navigateTo(context, '/settings'),
          ),
        );
    }

    return menuItems;
  }

  Widget _buildHeader(bool isDesktop) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "User";
    final email = user?.email ?? "user@example.com";
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF2196F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      currentAccountPicture: CircleAvatar(
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
      accountName: Text(
        displayName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email),
          if (_userRole.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userRole.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2196F3).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.3),
          width: 1,
        )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF1976D2)
              : (iconColor ?? Colors.grey.shade700),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade800,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(2),
          ),
        )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    setState(() {
      _selectedRoute = route;
    });

    // Close drawer on mobile
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (!isDesktop) {
      Navigator.pop(context);
    }

    // Navigate to the route
    Navigator.pushReplacementNamed(context, route);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF1976D2)),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Delete the controller before logout to prevent disposed controller issues
              Get.delete<LoginController>();
              Get.delete<RegisterController>(); // Also delete RegisterController if it exists

              // Now perform logout
              await FirebaseAuth.instance.signOut();

              // Clear login state
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Navigate to login page
              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}