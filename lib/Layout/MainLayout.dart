import 'package:flutter/material.dart';
import '../components/NavBar.dart';

class MainLayout extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          title,
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
        actions: actions ??
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
      drawer: isDesktop ? null : NavBar(currentRoute: currentRoute),
      body: Row(
        children: [
          // Persistent Sidebar for Desktop
          if (isDesktop)
            SizedBox(
              width: 280,
              child: NavBar(currentRoute: currentRoute),
            ),
          // Main Content Area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}