import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Theme
import 'theme/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';

// Services
import 'services/auth_service.dart';
import 'services/cart_service.dart';

// Screens
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initSession()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
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
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final auth = context.read<AuthProvider>();

        // ---- PUBLIC ROUTES ----
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          // ---- USER ROUTES (guard: must be logged in) ----
          case '/user-home':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const UserMainScreen());
          case '/user-detail':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            final productId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) =>
                  UserProductDetailScreen(productId: productId ?? 0),
            );
          case '/user-cart':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const UserCartScreen());
          case '/user-orders':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const UserOrderHistoryScreen(),
            );
          case '/user-notifications':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const UserNotificationScreen(),
            );
          case '/user-favorites':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const UserFavoriteScreen(),
            );
          case '/user-checkout':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const UserCheckoutScreen(),
            );
          case '/barcode-scanner':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const BarcodeScannerScreen(),
            );
          case '/profile':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/map':
            if (!auth.guardUser()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const MapScreen());

          // ---- ADMIN ROUTES (guard: must be admin) ----
          case '/admin-dashboard':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(),
            );
          case '/admin-products':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const AdminProductListScreen(),
            );
          case '/admin-product-form':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const AdminProductFormScreen(),
            );
          case '/admin-sales-report':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const AdminSalesReportScreen(),
            );
          case '/admin-coupon':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const AdminCouponScreen());
          case '/admin-payment':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(
              builder: (_) => const AdminPaymentScreen(),
            );
          case '/admin-qris':
            if (!auth.guardAdmin()) {
              return _redirectLogin();
            }
            return MaterialPageRoute(builder: (_) => const AdminQrisScreen());

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

  /// Redirect to /login, clearing the navigation stack.
  MaterialPageRoute _redirectLogin() {
    return MaterialPageRoute(
      builder: (ctx) {
        // Schedule a push to /login after the current frame to avoid
        // navigation during build. The guard itself already redirects.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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
      if (!mounted) return;
      try {
        final authService = AuthService();
        final isLoggedIn = await authService.isLoggedIn();
        if (!mounted) return;

        if (isLoggedIn) {
          final user = await authService.getCurrentUser();
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
      } catch (_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
