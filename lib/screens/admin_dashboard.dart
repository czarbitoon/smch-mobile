import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'device_management_screen.dart';
import 'office_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Offices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficeManagementScreen(),
                  ),
                );
              },
            ),
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Offices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficeManagementScreen(),
                  ),
                );
              },
            ),
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?['name'] ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    authProvider.user?['email'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Devices'),
              onTap: () {
                // TODO: Navigate to devices screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Offices'),
              onTap: () {
                // TODO: Navigate to offices screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Reports'),
              onTap: () {
                // TODO: Navigate to reports screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register User'),
              onTap: () {
                // TODO: Navigate to register screen
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: GridView.count(
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
            'Offices',
            Icons.business,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfficeManagementScreen(),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            'Reports',
            Icons.description,
            () {
              // TODO: Navigate to reports screen
            },
          ),
          _buildDashboardCard(
            context,
            'Register User',
            Icons.person_add,
            () {
              // TODO: Navigate to register screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Offices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficeManagementScreen(),
                  ),
                );
              },
            ),
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}