import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/leaderboard_provider.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../profile/models/player_profile_model.dart';
import '../../profile/views/widgets/profile_dialog.dart';
import '../../tournament/views/widgets/news_section.dart';
import '../../tournament/views/widgets/player_hub_features.dart';
import '../../leaderboard/views/leaderboard_screen.dart';
import '../../admin/views/widgets/admin_tech_stack.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'widgets/tournament_lifecycle.dart';

class EFBDLandingPage extends StatelessWidget {
  const EFBDLandingPage({super.key});

  void _showProfileDialog(BuildContext context, {Player? player}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final size = MediaQuery.of(context).size;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? size.width * 0.9 : 600,
            maxHeight: isMobile ? size.height * 0.85 : size.height * 0.9,
          ),
          child: ProfileDialog(player: player),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('eFootballers Bangladesh', style: GoogleFonts.rajdhani(letterSpacing: 2.5, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (!isAuthenticated)
            ElevatedButton(
              onPressed: () => _showProfileDialog(context),
              child: const Text('JOIN NOW'),
            )
          else
            TextButton.icon(
              onPressed: () => _showProfileDialog(context, player: authProvider.playerProfile),
              icon: CircleAvatar(
                radius: 12,
                backgroundImage: !kIsWeb && authProvider.playerProfile?.profileImageUrl != null && authProvider.playerProfile!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(authProvider.playerProfile!.profileImageUrl!)
                    : null,
                child: ClipOval(
                  child: authProvider.playerProfile?.profileImageUrl == null || authProvider.playerProfile!.profileImageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 12)
                      : (kIsWeb 
                          ? WebSafeImage(imageUrl: authProvider.playerProfile!.profileImageUrl!, width: 24, height: 24, fit: BoxFit.cover)
                          : null),
                ),
              ),
              label: Text(authProvider.playerProfile?.ign ?? 'Profile', style: const TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSection(
                  number: '১',
                  title: 'প্ল্যাটফর্ম সারসংক্ষেপ ও টুর্নামেন্ট লাইফসাইকেল',
                  child: const TournamentLifecycle(),
                ),
                _buildSection(
                  number: '২',
                  title: 'প্লেয়ার হাব ও টুর্নামেন্ট মেকানিক্স',
                  child: const PlayerHubFeatures(),
                ),
                _buildSection(
                  number: '৩',
                  title: 'গোল ও পয়েন্ট ভিত্তিক র‍্যাঙ্কিং সিস্টেম (GOAL & POINT RANKING)',
                  child: const LeaderboardScreen(),
                ),
                _buildSection(
                  number: '৪',
                  title: 'ট্রফি কেবিনেট ও গোল্ডেন বুট (TROPHY SHOWCASE & GOLDEN BOOT)',
                  child: _buildTrophyContent(context),
                ),
                _buildSection(
                  number: '৫',
                  title: 'টুর্নামেন্ট নিউজ ও আপডেট (LATEST UPDATES)',
                  child: const NewsSection(),
                ),
                _buildSection(
                  number: '৬',
                  title: 'সিকিউর অ্যাডমিন প্যানেল (/ADMIN) ও টেক স্ট্যাক',
                  child: const AdminTechStack(),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 20,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGold, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'eFootballers BD',
                  style: GoogleFonts.rajdhani(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    'EFOOTBALLERS BANGLADESH',
                    textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.rajdhani(
                      fontSize: isMobile ? 26 : 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.8,
                    ),
                  ),
                  Text(
                    'Complete Tournament Engine & Rankings',
                    textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'eFootballers Bangladesh is a community platform of eFootball players from Bangladesh, united by passion, driven by competition, and committed to grow together.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: isMobile ? 14 : 16),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBadge('FLUTTER', AppTheme.primaryGold, Colors.black),
              _buildBadge('FIREBASE', AppTheme.accentBlue, Colors.white),
              _buildBadge('RANKING', AppTheme.accentGreen, Colors.white),
              _buildBadge('TROPHIES', AppTheme.primaryGold, Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSection({required String number, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                color: AppTheme.primaryGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTrophyContent(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'লিডারবোর্ডে প্রতিটি প্লেয়ারের নামের পাশে তাদের অর্জিত ট্রফি ও গোল্ডেন বুটের সংখ্যা দেখা যাবে।',
          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Consumer<LeaderboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final players = provider.players;

            if (players.isEmpty) {
              return const Center(child: Text('No players found.', style: TextStyle(color: Colors.white70)));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isMobile ? 700 : 1000),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FlexColumnWidth(2),
                    2: FixedColumnWidth(180),
                  },
                  border: TableBorder.all(color: Colors.white10, width: 1),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
                      children: [
                        _buildTableHeader('RANK'),
                        _buildTableHeader('PLAYER'),
                        _buildTableHeader('TROPHIES'),
                        _buildTableHeader('P'),
                        _buildTableHeader('W'),
                        _buildTableHeader('D'),
                        _buildTableHeader('L'),
                        _buildTableHeader('GD'),
                        _buildTableHeader('PTS'),
                      ],
                    ),
                    ...players.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Player player = entry.value;
                      String rankPrefix = '';
                      if (idx == 0) rankPrefix = '🥇 ';
                      if (idx == 1) rankPrefix = '🥈 ';
                      if (idx == 2) rankPrefix = '🥉 ';

                      return TableRow(
                        children: [
                          _buildTableCell('$rankPrefix${idx + 1}'),
                          _buildTableCell(player.ign, isLeft: true),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTrophyIcon(context, '🏆', player.champions, player, 'Champion'),
                                const SizedBox(width: 8),
                                _buildTrophyIcon(context, '🥈', player.runnersUp, player, 'Runner-Up'),
                                const SizedBox(width: 8),
                                _buildTrophyIcon(context, '👟', player.goldenBoots, player, 'Golden Boot'),
                              ],
                            ),
                          ),
                          _buildTableCell(player.matchesPlayed.toString()),
                          _buildTableCell(player.wins.toString()),
                          _buildTableCell(player.draws.toString()),
                          _buildTableCell(player.losses.toString()),
                          _buildTableCell(player.goalDifference.toString()),
                          _buildTableCell(player.totalPoints.toString(), isBold: true, color: AppTheme.primaryGold),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        _buildModalPreview(),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isLeft = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 15,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildTrophyIcon(BuildContext context, String icon, int count, Player player, String type) {
    return InkWell(
      onTap: count > 0 ? () => _showTrophyDetails(context, player, type, count) : null,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showTrophyDetails(BuildContext context, Player player, String type, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '${player.ign}\'s $type Cabinet',
          style: GoogleFonts.rajdhani(
            color: AppTheme.primaryGold, 
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total $type: $count', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            const Text(
              'Tournament History:',
              style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (player.achievements.isEmpty)
              const Text('No detailed history available yet.', style: TextStyle(color: Colors.white70))
            else
              ...player.achievements.where((a) => a.contains(type)).map((a) => Text('• $a', style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[Trophy Cabinet Modal Preview - Player: RT6TEEN]',
            style: GoogleFonts.rajdhani(
              color: AppTheme.primaryGold, 
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _buildModalPoint('Total Accolades: 2x Champion | 1x Runner-Up | 2x Golden Boot'),
          _buildModalPoint('🏆 Champion: eFootballers Bangladesh Independence Cup 2026 (Aug 2026), Dhaka Super Clash (Jul 2026)'),
          _buildModalPoint('🥈 Runner-Up: Monsoon Showdown (Jun 2026)'),
          _buildModalPoint('👟 Golden Boot: eFootballers Bangladesh Independence Cup (11 Goals), Dhaka Super Clash (9 Goals)'),
          _buildModalPoint('Lifetime Stats: 128 Goals Scored | 19 Clean Sheets'),
        ],
      ),
    );
  }

  Widget _buildModalPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primaryGold, fontSize: 18)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Text(
            '© 2026 eFootballers Bangladesh (eFootballers Bangladesh) • Competitive Esports Management System',
            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/admin'),
            child: Text(
              'Admin Portal',
              style: GoogleFonts.poppins(color: AppTheme.primaryGold.withValues(alpha: 0.5), fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Built with passion for the eFootball Community',
            style: GoogleFonts.poppins(color: Colors.white10, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
