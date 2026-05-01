import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'services/menu_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/review_service.dart';
import 'services/search_history_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/seed_service.dart';
import 'services/notification_service.dart';
import 'services/coupon_service.dart';

// ─── IKAS Brand Colors ───────────────────────────────────────────────────────
class IKASColors {
  static const Color primary      = Color(0xFF27AE60);
  static const Color primaryDark  = Color(0xFF1E8449);
  static const Color primaryLight = Color(0xFF52BE80);
  static const Color accent       = Color(0xFF2ECC71);
  static const Color background   = Color(0xFFF6FEF9);
  static const Color surface      = Colors.white;
  static const Color onPrimary    = Colors.white;
  static const Color textDark     = Color(0xFF1A2E22);
  static const Color textMid      = Color(0xFF4A6B54);
  static const Color textLight    = Color(0xFF8DB39A);
  static const Color border       = Color(0xFFB7DEC5);
  static const Color chipBg       = Color(0xFFE8F8EE);

  // Dark‑mode surfaces
  static const Color darkBg       = Color(0xFF121A15);
  static const Color darkSurface  = Color(0xFF1C2B21);
  static const Color darkCard     = Color(0xFF243328);
}

// ─── Global Key for Notifications ─────────────────────────────────────────────
final GlobalKey<ScaffoldMessengerState> globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle (API anahtarları burada)
  await dotenv.load(fileName: '.env');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();

    // Seed database only if empty (production-safe)
    await SeedService.seedIfEmpty();
  } catch (e) {
    debugPrint('Firebase error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => SearchHistoryService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) {
          final menuService = MenuService();
          menuService.initMealsListener();
          return menuService;
        }),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProxyProvider<MenuService, CartService>(
          create: (_) => CartService(Provider.of<MenuService>(_, listen: false)),
          update: (_, menuService, previous) =>
              previous ?? CartService(menuService),
        ),
        ChangeNotifierProxyProvider<MenuService, OrderService>(
          create: (_) => OrderService(Provider.of<MenuService>(_, listen: false)),
          update: (_, menuService, previous) => previous ?? OrderService(menuService),
        ),
        ChangeNotifierProvider(create: (_) => CouponService()),
      ],
      child: Consumer2<ThemeService, LanguageService>(
        builder: (context, themeService, langService, _) {
          return MaterialApp(
            title: 'IKAS Super Market',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: globalMessengerKey,
            themeMode: themeService.mode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = GoogleFonts.poppinsTextTheme();

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary:    IKASColors.primary,
            secondary:  IKASColors.accent,
            tertiary:   IKASColors.primaryLight,
            surface:    IKASColors.darkSurface,
            onPrimary:  Colors.white,
            onSecondary: Colors.white,
            onSurface:  Colors.white,
            outline:    Color(0xFF2E4A38),
            surfaceContainerHighest: IKASColors.darkCard,
          )
        : const ColorScheme.light(
            primary:    IKASColors.primary,
            secondary:  IKASColors.accent,
            tertiary:   IKASColors.primaryLight,
            surface:    IKASColors.surface,
            onPrimary:  IKASColors.onPrimary,
            onSecondary: Colors.white,
            onSurface:  IKASColors.textDark,
            outline:    IKASColors.border,
            surfaceContainerHighest: IKASColors.chipBg,
          );

    final textColor = isDark ? Colors.white : IKASColors.textDark;
    final mutedColor = isDark ? const Color(0xFF9EC3AA) : IKASColors.textMid;

    final textTheme = base.copyWith(
      displayLarge:   GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: textColor),
      displayMedium:  GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: textColor),
      headlineLarge:  GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge:     GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
      titleMedium:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge:      GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium:     GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: mutedColor),
      labelLarge:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? IKASColors.darkBg : IKASColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: textColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? IKASColors.darkCard : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IKASColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IKASColors.primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? IKASColors.darkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2E4A38) : IKASColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2E4A38) : IKASColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: IKASColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: IKASColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: mutedColor, fontSize: 14),
        prefixIconColor: IKASColors.primary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? IKASColors.darkCard : IKASColors.chipBg,
        selectedColor: IKASColors.primary,
        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: IKASColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF2E4A38) : IKASColors.border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2E4A38) : IKASColors.textDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: textColor,
        ),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: mutedColor),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: IKASColors.primary,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? IKASColors.primary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? IKASColors.primary.withOpacity(0.5)
              : const Color(0xFFCFD8DC),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        selectedItemColor: IKASColors.primary,
        unselectedItemColor: isDark ? const Color(0xFF6B9A78) : IKASColors.textLight,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _wasAuthenticated;
  bool? _wasAdmin;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final orderService = Provider.of<OrderService>(context, listen: false);

    final isAuth = authService.isAuthenticated;
    final isAdmin = authService.isAdmin;

    // React to auth or role changes
    if (_wasAuthenticated != isAuth || _wasAdmin != isAdmin) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isAuth && isAdmin) {
          // Admin: listen to ALL orders in real-time
          orderService.listenToAllOrders();
          NotificationService.saveTokenToFirestore(authService.currentUserId);
        } else if (isAuth && !isAdmin) {
          // Regular user: listen to their own orders
          final uid = authService.currentUserId;
          if (uid.isNotEmpty) {
            orderService.listenToUserOrders(uid);
            NotificationService.saveTokenToFirestore(uid);
          }
        } else {
          // Logged out: stop all listeners and clear data
          orderService.stopListening();
        }
      });
      _wasAuthenticated = isAuth;
      _wasAdmin = isAdmin;
    }

    return isAuth ? const MainNavScreen() : const LoginScreen();
  }
}
