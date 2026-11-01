import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MobileBottomNavbar extends StatelessWidget {
  const MobileBottomNavbar({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/matches')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/hall-of-fame')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/matches');
        break;
      case 2:
        context.go('/leaderboard');
        break;
      case 3:
        context.go('/hall-of-fame');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        backgroundColor: Colors.transparent,
        indicatorColor: AppTheme.primaryGold.withValues(alpha: 0.2),
        elevation: 0,
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined, color: AppTheme.textGrey, size: 22),
            selectedIcon: Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 22),
            label: 'Tournaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined, color: AppTheme.textGrey, size: 22),
            selectedIcon: Icon(Icons.sports_esports, color: AppTheme.primaryGold, size: 22),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined, color: AppTheme.textGrey, size: 22),
            selectedIcon: Icon(Icons.leaderboard, color: AppTheme.primaryGold, size: 22),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.military_tech_outlined, color: AppTheme.textGrey, size: 22),
            selectedIcon: Icon(Icons.military_tech, color: AppTheme.primaryGold, size: 22),
            label: 'Hall of Fame',
          ),
        ],
      ),
    );
  }
}
