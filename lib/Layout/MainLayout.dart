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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
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
        ),
        actions: widget.actions ??
            [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
      ),
      drawer: isDesktop ? null : NavBar(currentRoute: _currentRoute),
      body: Row(
        children: [
          // Persistent Sidebar for Desktop
          if (isDesktop)
            SizedBox(
              width: 280,
              child: NavBar(currentRoute: _currentRoute),
            ),
          // Main Content Area
          Expanded(
            child: _currentChild,
          ),
        ],
      ),
    );
  }
}