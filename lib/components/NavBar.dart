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
            // Enhanced Header
            _buildHeader(isDesktop),

            // Menu Items with Animation
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

            // Bottom Section
            _buildBottomSection(context, isDesktop),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    List<Widget> menuItems = [];

    // Section Header
    menuItems.add(_buildSectionHeader("MAIN MENU"));

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
        menuItems.add(_buildSectionHeader("ADMINISTRATION"));
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
        menuItems.add(_buildSectionHeader("HUMAN RESOURCES"));
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
        menuItems.add(_buildSectionHeader("MANAGEMENT"));
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
        menuItems.add(_buildSectionHeader("MY WORKSPACE"));
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
          // Avatar with shadow
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

          // Name
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

          // Email
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

          // Role Badge
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
                // Icon
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

                // Title
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

                // Selected Indicator
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

              // Delete controllers
              Get.delete<LoginController>();
              Get.delete<RegisterController>();

              // Perform logout
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