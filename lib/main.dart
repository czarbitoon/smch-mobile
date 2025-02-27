import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/office_provider.dart';
import 'providers/device_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'SMCH Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF1976D2),
            secondary: Color(0xFF2196F3),
            tertiary: Color(0xFF64B5F6),
            background: Colors.white,
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onTertiary: Colors.white,
            onBackground: Colors.black,
            onSurface: Colors.black,
          ),
          brightness: Brightness.light,
          useMaterial3: true,
          textTheme: GoogleFonts.robotoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/admin': (context) => AdminDashboard(),
          '/staff': (context) => StaffDashboard(),
          '/user': (context) => UserDashboard(),
          '/home': (context) => AuthWrapper(),
        },
        onGenerateRoute: (settings) {
          // Handle dynamic routes here if needed
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Route ${settings.name} not found'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Role-based navigation
    if (authProvider.isAdmin) {
      return const AdminDashboard();
    } else if (authProvider.isStaff) {
      return const StaffDashboard();
    } else {
      return const UserDashboard();
    }
  }
}