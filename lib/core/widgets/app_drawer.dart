import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../features/profile/models/player_profile_model.dart';
import '../../features/profile/views/widgets/profile_dialog.dart';
import '../services/database_service.dart';
import '../models/community_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Drawer(
      backgroundColor: AppTheme.darkBackground,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Center(
              child: Text(
                'eFootballers Bangladesh',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(context, 'Tournaments', '/', Icons.emoji_events),
                _drawerItem(context, 'Matches', '/matches', Icons.sports_esports),
                _drawerItem(context, 'Leaderboard', '/leaderboard', Icons.leaderboard),
                _drawerItem(context, 'Hall of Fame', '/hall-of-fame', Icons.military_tech),
                _drawerItem(context, 'Season Archive', '/season-archive', Icons.archive),
                if (authProvider.isAdmin)
                  _drawerItem(context, 'Admin Dashboard', '/admin', Icons.admin_panel_settings, color: AppTheme.primaryGold),
                
                const Divider(color: Colors.white10, height: 32, indent: 16, endIndent: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'JOIN OUR COMMUNITY',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                StreamBuilder<CommunityConfig>(
                  stream: DatabaseService().getCommunityConfigStream(),
                  builder: (context, snapshot) {
                    final config = snapshot.data;
                    if (config == null) return const SizedBox.shrink();
                    
                    return Column(
                      children: [
                        if (config.facebookGroup.isNotEmpty)
                          _communityItem(
                            context, 
                            'Facebook Group', 
                            config.facebookGroup, 
                            Icons.groups_outlined
                          ),
                        if (config.facebookPage.isNotEmpty)
                          _communityItem(
                            context, 
                            'Facebook Page', 
                            config.facebookPage, 
                            Icons.facebook_outlined
                          ),
                        if (config.whatsappGroup.isNotEmpty)
                          _communityItem(
                            context, 
                            'WhatsApp Group', 
                            config.whatsappGroup, 
                            Icons.chat_outlined,
                            color: const Color(0xFF25D366)
                          ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: user == null
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showJoinDialog(context, null);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('JOIN / SIGN IN'),
                  )
                : Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showJoinDialog(context, authProvider.playerProfile);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: AppTheme.primaryGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authProvider.playerProfile?.ign.toUpperCase() ?? 'COMPLETE PROFILE',
                                  style: GoogleFonts.rajdhani(
                                    color: authProvider.playerProfile == null ? Colors.redAccent : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => authProvider.signOut(),
                        child: Text(
                          'SIGN OUT',
                          style: GoogleFonts.rajdhani(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, String route, IconData icon, {Color? color}) {
    final bool isActive = GoRouterState.of(context).uri.path == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primaryGold : (color ?? Colors.white70)),
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: isActive ? AppTheme.primaryGold : (color ?? Colors.white70),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      selected: isActive,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  Widget _communityItem(BuildContext context, String title, String url, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 20),
      visualDensity: VisualDensity.compact,
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          color: color ?? Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
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
}
