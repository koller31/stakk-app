import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/lock_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/theme/screens/theme_store_screen.dart';
import '../../features/business/screens/add_business_connection_screen.dart';
import '../../features/business/screens/manage_connections_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/lock',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final authStatus = authProvider.authStatus;
      final isLoading = authStatus == AuthStatus.loading ||
                        authStatus == AuthStatus.initial;
      final isOnLockScreen = state.matchedLocation == '/lock';

      // If loading/initial and not on lock screen, redirect to lock
      if (isLoading && !isOnLockScreen) {
        return '/lock';
      }

      // If not authenticated and not on lock screen, redirect to lock
      if (!isAuthenticated && !isOnLockScreen) {
        return '/lock';
      }

      // If authenticated and on lock screen, redirect to home
      if (isAuthenticated && isOnLockScreen) {
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/theme-store',
        builder: (context, state) => const ThemeStoreScreen(),
      ),
      GoRoute(
        path: '/business/add',
        builder: (context, state) => const AddBusinessConnectionScreen(),
      ),
      GoRoute(
        path: '/business/connections',
        builder: (context, state) => const ManageConnectionsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
