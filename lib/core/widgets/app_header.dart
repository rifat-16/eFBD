import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/web_safe_image.dart';
import '../../features/profile/models/player_profile_model.dart';
import '../../features/profile/views/widgets/profile_dialog.dart';
import '../../features/match_hub/models/match_model.dart';
import '../services/database_service.dart';
import '../utils/responsive_helper.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final bool isMobile = ResponsiveHelper.isMobile(context);

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E14).withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryGold.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.primaryGold),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  )
                : null,
            title: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_soccer_rounded, color: AppTheme.primaryGold, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'eFootballers BD',
                        style: GoogleFonts.rajdhani(
                          letterSpacing: isMobile ? 1.0 : 2.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                          fontSize: isMobile ? 18 : 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                          icon: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryGold, size: 18),
                          label: Text(
                            'ADMIN',
                            style: GoogleFonts.rajdhani(
                              fontSize: 15,
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    if (user == null)
                      ElevatedButton.icon(
                        onPressed: () => _showJoinDialog(context, null),
                        icon: const Icon(Icons.login_rounded, size: 16, color: Colors.black),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          textStyle: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
                        ),
                        label: const Text('JOIN / SIGN IN'),
                      )
                    else
                      InkWell(
                        onTap: () => _showJoinDialog(context, authProvider.playerProfile),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: authProvider.playerProfile == null
                                        ? Colors.redAccent
                                        : AppTheme.primaryGold,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGold.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (authProvider.playerProfile?.profileImageUrl == null ||
                                          authProvider.playerProfile!.profileImageUrl!.trim().isEmpty)
                                      ? Icon(
                                          authProvider.playerProfile == null ? Icons.warning_amber_rounded : Icons.person,
                                          color: authProvider.playerProfile == null ? Colors.redAccent : AppTheme.primaryGold,
                                          size: 18,
                                        )
                                      : (kIsWeb 
                                          ? WebSafeImage(
                                              imageUrl: authProvider.playerProfile!.profileImageUrl!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              fallbackWidget: const Icon(
                                                Icons.person,
                                                color: AppTheme.primaryGold,
                                                size: 18,
                                              ),
                                            )
                                          : Image.network(
                                              authProvider.playerProfile!.profileImageUrl!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                            )),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (authProvider.playerProfile != null)
                                Text(
                                  authProvider.playerProfile!.ign.toUpperCase(),
                                  style: GoogleFonts.rajdhani(
                                    color: AppTheme.primaryGold,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                )
                              else
                                Text(
                                  'COMPLETE PROFILE',
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 20),
                  ],
          ),
        ),
      ),
    ),
  );
}

  Widget _navLink(BuildContext context, String title, String route) {
    final bool isActive = GoRouterState.of(context).uri.path == route;
    final bool isNarrow = MediaQuery.of(context).size.width < 950;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          TextButton(
            onPressed: () => context.go(route),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 12, vertical: 12),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.rajdhani(
                fontSize: isNarrow ? 13 : 15,
                color: isActive ? AppTheme.primaryGold : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (isActive)
            Container(
              height: 2.5,
              width: isNarrow ? 22 : 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        ],
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
            borderRadius: BorderRadius.circular(20),
            child: Badge(
              label: Text(
                matches.length.toString(),
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
              backgroundColor: AppTheme.primaryGold,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_esports_rounded, color: AppTheme.primaryGold, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}
