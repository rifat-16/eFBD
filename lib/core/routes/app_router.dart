import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../../features/leaderboard/views/hall_of_fame_screen.dart';
import '../../features/leaderboard/views/season_history_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/admin/views/admin_dashboard_screen.dart';
import '../../features/admin/views/admin_tournament_detail_screen.dart';
import '../../features/tournament/views/tournament_list_screen.dart';
import '../../features/tournament/views/tournament_detail_screen.dart';
import '../../features/leaderboard/views/leaderboard_screen.dart';
import '../../features/match_hub/views/match_hub_screen.dart';
import '../../features/auth/views/complete_profile_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter getRouter(app_auth.AuthProvider authProvider) {
    _router ??= GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              appBar: const AppHeader(),
              drawer: const AppDrawer(),
              body: child,
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TournamentListScreen(),
              redirect: (context, state) {
                if (authProvider.isAuthenticated) {
                  if (!authProvider.isInitialized) return null;
                  if (!authProvider.isProfileComplete && !authProvider.isAdmin) return '/complete-profile';
                  if (authProvider.isAdmin) return '/admin';
                }
                return null;
              },
            ),
            GoRoute(
              path: '/tournaments/:id',
              builder: (context, state) => TournamentDetailScreen(
                tournamentId: state.pathParameters['id']!,
              ),
              redirect: (context, state) {
                if (authProvider.isAuthenticated && !authProvider.isInitialized) return null;
                if (authProvider.isAuthenticated && !authProvider.isProfileComplete && !authProvider.isAdmin) return '/complete-profile';
                return null;
              },
            ),
            GoRoute(
              path: '/matches',
              builder: (context, state) => const MatchHubScreen(),
              redirect: (context, state) {
                if (authProvider.isAuthenticated && !authProvider.isInitialized) return null;
                if (authProvider.isAuthenticated && !authProvider.isProfileComplete && !authProvider.isAdmin) return '/complete-profile';
                return null;
              },
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
            ),
            GoRoute(
              path: '/hall-of-fame',
              builder: (context, state) => const HallOfFameScreen(),
            ),
            GoRoute(
              path: '/season-archive',
              builder: (context, state) => const SeasonHistoryScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return '/login';
            if (authProvider.isInitialized && authProvider.isProfileComplete) return '/';
            return null;
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
          redirect: (context, state) {
            if (authProvider.isAuthenticated) {
              // Wait for initialization to ensure profile (and role) is loaded
              if (!authProvider.isInitialized) return null;
              
              if (authProvider.isAdmin) return '/admin';
              return '/';
            }
            return null;
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
          redirect: (context, state) {
            if (authProvider.isAuthenticated) {
              if (!authProvider.isInitialized) return null;
              
              if (authProvider.isAdmin) return '/admin';
              return '/';
            }
            return null;
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return '/login';
            if (!authProvider.isInitialized) return null;

            if (!authProvider.isAdmin) return '/';
            return null;
          },
          routes: [
            GoRoute(
              path: 'tournaments/:id',
              builder: (context, state) => AdminTournamentDetailScreen(
                tournamentId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
