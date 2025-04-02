import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'reports_screen.dart';
import 'device_management_screen.dart';


class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.secondary,
                    child: Icon(Icons.person, size: 30, color: theme.colorScheme.onSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?.name ?? 'User',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.description, color: theme.colorScheme.primary),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.colorScheme.primary),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context,
              'Devices',
              Icons.devices,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceManagementScreen(),
                  ),
                );
              },
            ),
            
            _buildDashboardCard(
              context,
              'Reports',
              Icons.description,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              'Profile',
              Icons.person,
              () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}