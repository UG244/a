import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_product_list_screen.dart';
import 'screens/admin/admin_product_form_screen.dart';
import 'screens/admin/admin_sales_report_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/user/user_cart_screen.dart';
import 'screens/user/user_checkout_screen.dart';
import 'screens/user/user_order_history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartService(),
      child: const BlueMartApp(),
    ),
  );
}

class BlueMartApp extends StatelessWidget {
  const BlueMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/admin-dashboard':
            return MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(),
            );
          case '/admin-products':
            return MaterialPageRoute(
              builder: (_) => const AdminProductListScreen(),
            );
          case '/admin-product-form':
            return MaterialPageRoute(
              builder: (_) => const AdminProductFormScreen(),
            );
          case '/admin-sales-report':
            return MaterialPageRoute(
              builder: (_) => const AdminSalesReportScreen(),
            );
          case '/user-home':
            return MaterialPageRoute(
              builder: (_) => const UserHomeScreen(),
            );
          case '/user-cart':
            return MaterialPageRoute(
              builder: (_) => const UserCartScreen(),
            );
          case '/user-checkout':
            return MaterialPageRoute(
              builder: (_) => const UserCheckoutScreen(),
            );
          case '/user-orders':
            return MaterialPageRoute(
              builder: (_) => const UserOrderHistoryScreen(),
            );
          case '/map':
            return MaterialPageRoute(
              builder: (_) => const MapScreen(),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Halaman tidak ditemukan')),
              ),
            );
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() {
    _timer = Timer(const Duration(milliseconds: 500), () async {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!mounted) return;

      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (!mounted) return;
        if (user != null) {
          if (user.role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/user-home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'BlueMart',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}