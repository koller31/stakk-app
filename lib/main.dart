import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/services/migration_service.dart';
import 'core/services/device_security_service.dart';
import 'core/services/auto_lock_service.dart';

// Data - Models
import 'data/models/wallet_card_model.dart';
// Features - Providers
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/lock_mode_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/theme/providers/theme_provider.dart';

// Router
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for wallet cards storage
  await Hive.initFlutter();

  // Register Hive type adapters
  Hive.registerAdapter(WalletCardModelAdapter());

  // Run data migrations (encrypts DB + images for existing users)
  await MigrationService().runMigrations();

  // Clean up stale temp files from cancelled scans
  _cleanupTempFiles();

  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const IDswipeApp());
}

/// Clean up stale .jpg temp files from cancelled card scans.
Future<void> _cleanupTempFiles() async {
  try {
    final tempDir = await getTemporaryDirectory();
    final files = tempDir.listSync();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        // Only delete files older than 1 hour to avoid deleting active scans
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoLockService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoLockService.recordPause();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    final shouldLock = await _autoLockService.shouldLockOnResume();
    if (shouldLock && mounted) {
      // Get the auth provider and lock the app
      try {
        final authProvider =
            Provider.of<AuthProvider>(context, listen: false);
        authProvider.lock();
      } catch (_) {}
    }
  }

  void _checkDeviceSecurity(BuildContext context) {
    if (_deviceSecurityChecked) return;
    _deviceSecurityChecked = true;
    // Run device security check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceSecurityService().checkAndWarn(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider (must be first for routing)
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider()..init(),
        ),

        // Home Provider (card management)
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(),
        ),

        // Lock Mode Provider (traffic document lock)
        ChangeNotifierProvider<LockModeProvider>(
          create: (context) => LockModeProvider()..initialize(),
        ),

        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Reactively apply theme when provider changes
          AppColors.applyTheme(themeProvider.currentTheme);

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final appRouter = AppRouter(authProvider);

          // Check device security after auth is ready
          final authStatus =
              context.select<AuthProvider, AuthStatus>((p) => p.authStatus);
          if (authStatus == AuthStatus.authenticated) {
            _checkDeviceSecurity(context);
          }

          return MaterialApp.router(
            title: 'IDswipe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
