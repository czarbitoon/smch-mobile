import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/office_provider.dart';
import 'providers/device_provider.dart';
import 'providers/device_report_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/user_dashboard.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // Pre-load theme preference before rendering the app
  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();

  // Initialize office provider and fetch offices
  final officeProvider = OfficeProvider();
  await officeProvider.loadOffices();
  
  runApp(MyApp(themeProvider: themeProvider, officeProvider: officeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final OfficeProvider officeProvider;
  
  const MyApp({super.key, required this.themeProvider, required this.officeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: officeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => DeviceReportProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider(ApiService())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'SMCH Mobile',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              secondary: Color(0xFF2196F3),
              onSecondary: Colors.white,
              tertiary: Color(0xFF64B5F6),
              onTertiary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              background: Colors.grey[50]!,
              onBackground: Colors.black87,
            ),
            brightness: Brightness.light,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF90CAF9),
              onPrimary: Colors.black,
              secondary: Color(0xFF64B5F6),
              onSecondary: Colors.black,
              tertiary: Color(0xFF42A5F5),
              onTertiary: Colors.black,
              surface: Color(0xFF121212),
              onSurface: Colors.white,
              background: Color(0xFF121212),
              onBackground: Colors.white,
            ),
            brightness: Brightness.dark,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),
          initialRoute: '/login',
          routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/admin': (context) => AdminDashboard(),
          '/staff': (context) => StaffDashboard(),
          '/user': (context) => UserDashboard(),
          '/home': (context) => AuthWrapper(),
          '/profile': (context) => ProfileScreen(),
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
    ));
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
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
      },
    );
  }
}