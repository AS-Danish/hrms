import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/NavBar.dart';

// Global key to access MainLayout state from anywhere
final GlobalKey<_MainLayoutState> mainLayoutKey = GlobalKey<_MainLayoutState>();

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final List<Widget>? actions;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
    this.actions,
  });

  // Static method to update the layout without navigation
  static void updateContent({
    required String route,
    required String title,
    required Widget child,
  }) {
    if (mainLayoutKey.currentState != null) {
      mainLayoutKey.currentState!.updatePage(route, title, child);
    }
  }

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late String _currentRoute;
  late String _currentTitle;
  late Widget _currentChild;
  bool _isDrawerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.currentRoute;
    _currentTitle = widget.title;
    _currentChild = widget.child;
  }

  void updatePage(String route, String title, Widget child) {
    setState(() {
      _currentRoute = route;
      _currentTitle = title;
      _currentChild = child;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerCollapsed = !_isDrawerCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: isDesktop ? null : _buildMobileAppBar(),
      drawer: !isDesktop ? NavBar(currentRoute: _currentRoute) : null,
      body: isDesktop
          ? Row(
        children: [
          // Collapsible Sidebar for Desktop
          NavBar(
            currentRoute: _currentRoute,
            isCollapsed: _isDrawerCollapsed,
            onToggleCollapse: _toggleDrawer,
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _currentChild,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : _currentChild,
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(
        _currentTitle,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
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
        ),
      ),
      actions: widget.actions ??
          [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {},
              tooltip: 'Profile',
            ),
            const SizedBox(width: 8),
          ],
    );
  }

  Widget _buildDesktopAppBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Page Title
          Text(
            _currentTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool badge = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: Colors.grey.shade700,
            tooltip: tooltip,
            iconSize: 22,
          ),
        ),
        if (badge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF2196F3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}