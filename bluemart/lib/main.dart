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
import 'screens/admin/admin_coupon_screen.dart';
import 'screens/admin/admin_payment_screen.dart';
import 'screens/admin/admin_qris_screen.dart';
import 'screens/user/user_main_screen.dart';
import 'screens/user/user_cart_screen.dart';
import 'screens/user/user_checkout_screen.dart';
import 'screens/user/user_order_history_screen.dart';
import 'screens/user/user_notification_screen.dart';
import 'screens/user/user_favorite_screen.dart';
import 'screens/user/user_product_detail_screen.dart';
import 'screens/user/barcode_scanner_screen.dart';
import 'screens/user/user_address_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/admin/admin_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartService())],
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
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF3B82F6),
          tertiary: const Color(0xFF0EA5E9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A8A),
            side: const BorderSide(color: Color(0xFF1E3A8A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIconColor: const Color(0xFF94A3B8),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1E3A8A),
          unselectedItemColor: Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFF1F5F9),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFF1E3A8A),
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
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
            return MaterialPageRoute(builder: (_) => const UserMainScreen());
          case '/user-detail':
            final productId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) =>
                  UserProductDetailScreen(productId: productId ?? 0),
            );
          case '/user-cart':
            return MaterialPageRoute(builder: (_) => const UserCartScreen());
          case '/user-orders':
            return MaterialPageRoute(
              builder: (_) => const UserOrderHistoryScreen(),
            );
          case '/user-address':
            return MaterialPageRoute(builder: (_) => const UserAddressScreen());
          case '/user-notifications':
            return MaterialPageRoute(
              builder: (_) => const UserNotificationScreen(),
            );
          case '/user-favorites':
            return MaterialPageRoute(
              builder: (_) => const UserFavoriteScreen(),
            );
          case '/user-checkout':
            return MaterialPageRoute(
              builder: (_) => const UserCheckoutScreen(),
            );
          case '/barcode-scanner':
            return MaterialPageRoute(
              builder: (_) => const BarcodeScannerScreen(),
            );
          case '/admin-coupon':
            return MaterialPageRoute(builder: (_) => const AdminCouponScreen());
          case '/admin-payment':
            return MaterialPageRoute(
              builder: (_) => const AdminPaymentScreen(),
            );
          case '/admin-qris':
            return MaterialPageRoute(builder: (_) => const AdminQrisScreen());
          case '/map':
            return MaterialPageRoute(builder: (_) => const MapScreen());
          case '/user-profile':
            return MaterialPageRoute(builder: (_) => const UserProfileScreen());
          case '/admin-profile':
            return MaterialPageRoute(builder: (_) => const AdminProfileScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _checkSession();
  }

  void _checkSession() {
    _timer = Timer(const Duration(milliseconds: 1500), () async {
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF0EA5E9)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'BlueMart',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belanja Gadget & Elektronik',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
