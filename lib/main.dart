import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/office_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/user_dashboard.dart';

void main() {
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
        darkTheme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF1976D2),
            secondary: Color(0xFF2196F3),
            tertiary: Color(0xFF64B5F6),
            background: Color(0xFF242424),
            surface: Color(0xFF2C2C2C),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onTertiary: Colors.white,
            onBackground: Colors.white,
            onSurface: Colors.white,
          ),
          brightness: Brightness.dark,
          useMaterial3: true,
          textTheme: GoogleFonts.robotoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: const AuthWrapper(),
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