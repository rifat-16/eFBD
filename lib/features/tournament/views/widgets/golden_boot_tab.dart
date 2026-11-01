import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../models/tournament_model.dart';
import '../../../match_hub/models/match_model.dart';
import '../../../profile/models/player_profile_model.dart';

class GoldenBootTab extends StatelessWidget {
  final Tournament tournament;
  const GoldenBootTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentMatch>>(
      stream: DatabaseService().getMatches(tournament.id),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        
        final allMatches = matchSnapshot.data!;
        if (allMatches.isEmpty) return const Center(child: Text('No match data available yet.', style: TextStyle(color: AppTheme.textGrey)));

        // Calculate total goals for each player
        Map<String, int> goalStats = {};
        
        for (var match in allMatches) {
          if (!match.isVerified) continue;
          
          final s1 = match.player1Score ?? 0;
          final s2 = match.player2Score ?? 0;

          goalStats[match.player1Id] = (goalStats[match.player1Id] ?? 0) + s1;
          if (match.player2Id != 'BYE') {
            goalStats[match.player2Id] = (goalStats[match.player2Id] ?? 0) + s2;
          }
        }

        return StreamBuilder<List<Player>>(
          stream: DatabaseService().getPlayersStream(),
          builder: (context, playerSnapshot) {
            final players = playerSnapshot.data ?? [];
            List<String> sortedPlayerIds = goalStats.keys.toList();
            
            sortedPlayerIds.sort((a, b) => goalStats[b]!.compareTo(goalStats[a]!));

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sports_soccer_rounded, color: AppTheme.primaryGold, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'GOLDEN BOOT RACE', 
                              style: GoogleFonts.rajdhani(
                                fontSize: 20, 
                                color: AppTheme.primaryGold, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: AppTheme.primaryGold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE GOAL TALLY', 
                                style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ...sortedPlayerIds.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pid = entry.value;
                      final goals = goalStats[pid]!;
                      final player = players.firstWhere(
                        (p) => p.id == pid, 
                        orElse: () => Player(id: pid, name: 'Unknown', email: '', ign: 'Player', uid: ''),
                      );
                      
                      final isRank1 = index == 0;
                      final isRank2 = index == 1;
                      final isRank3 = index == 2;

                      final cardColor = isRank1 
                          ? AppTheme.primaryGold 
                          : (isRank2 ? const Color(0xFFC0C0C0) : (isRank3 ? const Color(0xFFCD7F32) : Colors.white24));

                      final cardBg = isRank1
                          ? const Color(0xFF321E0B)
                          : (isRank2 
                              ? const Color(0xFF1B2433) 
                              : (isRank3 ? const Color(0xFF2C190D) : const Color(0xFF0F131C)));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: HoverCard(
                          borderRadius: BorderRadius.circular(16),
                          borderColor: cardColor,
                          glowColor: cardColor,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRank1 
                                    ? AppTheme.primaryGold.withValues(alpha: 0.8) 
                                    : (isRank2 ? Colors.blueGrey.withValues(alpha: 0.5) : (isRank3 ? Colors.orangeAccent.withValues(alpha: 0.4) : Colors.white10)),
                                width: isRank1 ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                if (isRank1)
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isRank1) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const PulsingBadge(label: 'GOLDEN BOOT LEADER', color: AppTheme.primaryGold, icon: Icons.workspace_premium_rounded),
                                      Text(
                                        'RANK #1',
                                        style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    // Rank Circle Badge
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isRank1 || isRank2 || isRank3 
                                            ? cardColor.withValues(alpha: 0.2) 
                                            : Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        '${index + 1}', 
                                        style: GoogleFonts.rajdhani(
                                          color: isRank1 || isRank2 || isRank3 ? cardColor : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Avatar Frame
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardColor, width: isRank1 ? 2.0 : 1.2),
                                        boxShadow: [
                                          if (isRank1)
                                            BoxShadow(
                                              color: AppTheme.primaryGold.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                            ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                                            ? WebSafeImage(
                                                imageUrl: player.profileImageUrl!,
                                                fit: BoxFit.cover,
                                                fallbackWidget: Icon(Icons.person, color: cardColor, size: 22),
                                              )
                                            : Icon(Icons.person, color: cardColor, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Player IGN & Full Name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.ign, 
                                            style: GoogleFonts.rajdhani(
                                              fontWeight: FontWeight.bold, 
                                              fontSize: isRank1 ? 20 : 17, 
                                              color: isRank1 ? AppTheme.primaryGold : Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          if (player.name.isNotEmpty)
                                            Text(
                                              player.name, 
                                              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Goals Count Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isRank1
                                            ? AppTheme.primaryGold.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isRank1
                                              ? AppTheme.primaryGold.withValues(alpha: 0.6)
                                              : Colors.white10,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$goals', 
                                            style: GoogleFonts.rajdhani(
                                              fontSize: isRank1 ? 26 : 22, 
                                              fontWeight: FontWeight.bold,
                                              color: isRank1 ? AppTheme.primaryGold : Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          Text(
                                            'GOALS', 
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 9, 
                                              color: isRank1 ? AppTheme.primaryGold : AppTheme.textGrey, 
                                              fontWeight: FontWeight.bold, 
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
