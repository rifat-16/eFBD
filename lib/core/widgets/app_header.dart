import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/web_safe_image.dart';
import '../../features/profile/models/player_profile_model.dart';
import '../../features/profile/views/widgets/profile_dialog.dart';
import '../../features/match_hub/models/match_model.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../utils/responsive_helper.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final bool isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      elevation: 0,
      leading: isMobile
          ? IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primaryGold),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : null,
      title: InkWell(
        onTap: () => context.go('/'),
        child: Text(
          'eFootballers Bangladesh',
          style: GoogleFonts.rajdhani(
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
            fontSize: isMobile ? 22 : 26,
          ),
        ),
      ),
      centerTitle: isMobile,
      actions: isMobile
          ? [
              if (user != null) _buildMyMatchesBadge(context, user.uid),
              const SizedBox(width: 8),
            ]
          : [
              _navLink(context, 'Tournaments', '/'),
              _navLink(context, 'Matches', '/matches'),
              _navLink(context, 'Leaderboard', '/leaderboard'),
              _navLink(context, 'Hall of Fame', '/hall-of-fame'),
              if (user != null) _buildMyMatchesBadge(context, user.uid),
              if (authProvider.isAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextButton.icon(
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryGold, size: 18),
                    label: Text(
                      'ADMIN',
                      style: GoogleFonts.rajdhani(
                        fontSize: 16,
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              const SizedBox(width: 20),
              if (user == null)
                ElevatedButton(
                  onPressed: () => _showJoinDialog(context, null),
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: const Text('JOIN / SIGN IN'),
                )
              else
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showJoinDialog(context, authProvider.playerProfile),
                      child: Row(
                        children: [
                          if (authProvider.playerProfile != null)
                            Text(
                              authProvider.playerProfile!.ign.toUpperCase(),
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.primaryGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            )
                          else
                            Text(
                              'COMPLETE PROFILE',
                              style: GoogleFonts.rajdhani(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: authProvider.playerProfile == null
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : AppTheme.primaryGold,
                            backgroundImage: (!kIsWeb && authProvider.playerProfile?.profileImageUrl != null &&
                                    authProvider.playerProfile!.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(authProvider.playerProfile!.profileImageUrl!)
                                : null,
                            child: ClipOval(
                              child: (authProvider.playerProfile?.profileImageUrl == null ||
                                      authProvider.playerProfile!.profileImageUrl!.isEmpty)
                                  ? Icon(
                                      authProvider.playerProfile == null ? Icons.warning : Icons.person,
                                      color: authProvider.playerProfile == null ? Colors.redAccent : Colors.black,
                                      size: 16,
                                    )
                                  : (kIsWeb 
                                      ? WebSafeImage(imageUrl: authProvider.playerProfile!.profileImageUrl!, width: 32, height: 32, fit: BoxFit.cover)
                                      : null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 24),
            ],
    );
  }

  Widget _navLink(BuildContext context, String title, String route) {
    final bool isActive = GoRouterState.of(context).uri.path == route;
    return TextButton(
      onPressed: () => context.go(route),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: isActive ? AppTheme.primaryGold : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, Player? player) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ProfileDialog(player: player),
        ),
      ),
    );
  }

  Widget _buildMyMatchesBadge(BuildContext context, String playerId) {
    return StreamBuilder<List<TournamentMatch>>(
      stream: DatabaseService().getMyMatches(playerId),
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        if (matches.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: InkWell(
            onTap: () => context.go('/matches'),
            child: Badge(
              label: Text(
                matches.length.toString(),
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              backgroundColor: AppTheme.primaryGold,
              child: const Icon(Icons.sports_esports, color: Colors.white70),
            ),
          ),
        );
      },
    );
  }
}
