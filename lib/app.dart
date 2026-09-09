import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/tournament_provider.dart';
import 'core/providers/leaderboard_provider.dart';
import 'core/config/flavor_config.dart';

class EFBDApp extends StatelessWidget {
  const EFBDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: FlavorConfig.instance.appTitle,
            debugShowCheckedModeBanner: FlavorConfig.isDevelopment(),
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.getRouter(authProvider),
            builder: (context, child) {
              if (!authProvider.isInitialized) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('asset/logo.jpg', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.sports_esports, size: 80, color: AppTheme.primaryGold)),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(color: AppTheme.primaryGold),
                      ],
                    ),
                  ),
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}
