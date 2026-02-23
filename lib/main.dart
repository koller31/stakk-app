import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/services/migration_service.dart';
import 'core/services/demo_card_seeder.dart';
import 'core/services/device_security_service.dart';
import 'core/services/auto_lock_service.dart';

// Data - Models
import 'data/models/wallet_card_model.dart';
import 'data/models/business_connection_model.dart';
// Features - Providers
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/lock_mode_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/theme/providers/theme_provider.dart';
import 'features/business/providers/business_connection_provider.dart';

// Router
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation + system UI (instant, no I/O)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive (required before any box can open)
  await Hive.initFlutter();
  Hive.registerAdapter(WalletCardModelAdapter());
  Hive.registerAdapter(BusinessConnectionModelAdapter());

  // Run data migrations (must complete before boxes open)
  await MigrationService().runMigrations();

  // Launch UI immediately - remaining init runs in background
  runApp(const IDswipeApp());
}

/// Clean up stale .jpg temp files from cancelled card scans.
Future<void> _cleanupTempFiles() async {
  try {
    final tempDir = await getTemporaryDirectory();
    final files = tempDir.listSync();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final stat = await entity.stat();
        if (DateTime.now().difference(stat.modified).inHours >= 1) {
          await entity.delete();
        }
      }
    }
  } catch (_) {}
}

class IDswipeApp extends StatefulWidget {
  const IDswipeApp({super.key});

  @override
  State<IDswipeApp> createState() => _IDswipeAppState();
}

class _IDswipeAppState extends State<IDswipeApp> with WidgetsBindingObserver {
  final AutoLockService _autoLockService = AutoLockService();
  bool _deviceSecurityChecked = false;

  // Created here so lifecycle callbacks can access them directly
  // (the widget's own context is above the MultiProvider, so Provider.of fails)
  late final AuthProvider _authProvider;
  late final HomeProvider _homeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoLockService.init();
    _authProvider = AuthProvider()..init();
    _homeProvider = HomeProvider();

    // Run deferred init: seed demo cards, pre-warm SharedPreferences,
    // then load card data - all after the first frame renders
    _deferredInit();
  }

  Future<void> _deferredInit() async {
    await DemoCardSeeder().seedIfEmpty();
    await SharedPreferences.getInstance();
    _homeProvider.loadData();
    _cleanupTempFiles(); // fire-and-forget
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.dispose();
    _homeProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoLockService.recordPause();
    } else if (state == AppLifecycleState.resumed) {
      // Lock synchronously BEFORE the next frame renders,
      // so the router never briefly shows /home
      final shouldLock = _autoLockService.shouldLockOnResume();
      if (shouldLock) {
        _authProvider.lock();
      }
      _homeProvider.reWarmImageCache();
    }
  }

  void _checkDeviceSecurity(BuildContext context) {
    if (_deviceSecurityChecked) return;
    _deviceSecurityChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceSecurityService().checkAndWarn(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider (must be first for routing)
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),

        // Home Provider (card management) - loads after deferred init
        ChangeNotifierProvider<HomeProvider>.value(value: _homeProvider),

        // Lock Mode Provider (traffic document lock)
        ChangeNotifierProvider<LockModeProvider>(
          create: (context) => LockModeProvider()..initialize(),
        ),

        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),

        // Business Connection Provider
        ChangeNotifierProvider<BusinessConnectionProvider>(
          create: (context) => BusinessConnectionProvider()..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Reactively apply theme when provider changes
          AppColors.applyTheme(themeProvider.currentTheme);

          // Update system UI to match theme brightness
          final isDark = themeProvider.currentTheme.isDark;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: AppColors.primaryBackground,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );

          final appRouter = AppRouter(_authProvider);

          // Check device security after auth is ready
          final authStatus =
              context.select<AuthProvider, AuthStatus>((p) => p.authStatus);
          if (authStatus == AuthStatus.authenticated) {
            _checkDeviceSecurity(context);
          }

          return MaterialApp.router(
            title: 'Stakk',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.currentThemeData,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
