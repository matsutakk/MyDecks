import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_voice_tutor/screens/deck_detail_screen.dart';
import 'package:my_voice_tutor/screens/decks_screen.dart';
import 'package:my_voice_tutor/screens/settings_screen.dart';
import 'package:my_voice_tutor/screens/wrapper_home_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../screens/signin_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/import_data_screen.dart';
import '../providers/user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    refreshListenable: RouterNotifier(ref),
    // initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return WrapperHomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/decks',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const DeckListScreen(),
                ),
              ),
            ],
          ),
        ],
      ),


      GoRoute(
        path: '/deck-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeckDetailScreen(deckId: id);
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/import_data',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ImportDataScreen(
            path: extra?['path'] as String? ?? '',
            type: extra?['type'] as SharedMediaType? ?? SharedMediaType.file
          );
        },
      ),
      
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('404'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'ページが見つかりません',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) {
        return '/';
      }
      
      final isInitializing = state.uri.path == '/';
      final isLoggingIn = state.uri.path == '/signin';
      
      if (!isLoggedIn) {
        return isInitializing ? '/signin' : null;
      }
      
      if (isLoggingIn || isInitializing) {
        return '/home';
      }
      
      // stay current path
      return null;
    },
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
}