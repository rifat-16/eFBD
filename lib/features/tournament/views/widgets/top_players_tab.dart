import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../models/tournament_model.dart';
import '../../models/group_model.dart';
import '../../../match_hub/models/match_model.dart';
import '../../../profile/models/player_profile_model.dart';

class TopPlayersTab extends StatelessWidget {
  final Tournament tournament;
  const TopPlayersTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.rajdhani(
      fontWeight: FontWeight.bold, 
      fontSize: AppTheme.responsiveFontSize(context, 12), 
      color: AppTheme.primaryGold,
      letterSpacing: 1,
    );

    return StreamBuilder<List<TournamentMatch>>(
      stream: DatabaseService().getMatches(tournament.id),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        
        final allMatches = matchSnapshot.data!;
        if (allMatches.isEmpty) return const Center(child: Text('No match data available yet.', style: TextStyle(color: AppTheme.textGrey)));

        // Aggregate stats across all matches (Group + Knockout)
        Map<String, GroupStats> aggregateStats = {};
        
        for (var match in allMatches) {
          if (!match.isVerified) continue;
          
          final s1 = match.player1Score ?? 0;
          final s2 = match.player2Score ?? 0;

          // Player 1
          if (match.player1Id != 'BYE') {
            final cur1 = aggregateStats[match.player1Id] ?? GroupStats();
            aggregateStats[match.player1Id] = GroupStats(
              played: cur1.played + 1,
              won: cur1.won + (s1 > s2 ? 1 : 0),
              drawn: cur1.drawn + (s1 == s2 ? 1 : 0),
              lost: cur1.lost + (s1 < s2 ? 1 : 0),
              goalsFor: cur1.goalsFor + s1,
              goalsAgainst: cur1.goalsAgainst + s2,
              points: cur1.points + (s1 > s2 ? 3 : (s1 == s2 ? 1 : 0)),
            );
          }

          // Player 2 (if not BYE)
          if (match.player2Id != 'BYE') {
            final cur2 = aggregateStats[match.player2Id] ?? GroupStats();
            aggregateStats[match.player2Id] = GroupStats(
              played: cur2.played + 1,
              won: cur2.won + (s2 > s1 ? 1 : 0),
              drawn: cur2.drawn + (s2 == s1 ? 1 : 0),
              lost: cur2.lost + (s2 < s1 ? 1 : 0),
              goalsFor: cur2.goalsFor + s2,
              goalsAgainst: cur2.goalsAgainst + s1,
              points: cur2.points + (s2 > s1 ? 3 : (s2 == s1 ? 1 : 0)),
            );
          }
        }

        return StreamBuilder<List<Player>>(
          stream: DatabaseService().getPlayersStream(),
          builder: (context, playerSnapshot) {
            final players = playerSnapshot.data ?? [];
            List<String> sortedPlayerIds = aggregateStats.keys.toList();
            
            sortedPlayerIds.sort((a, b) {
              final statsA = aggregateStats[a]!;
              final statsB = aggregateStats[b]!;
              if (statsB.points != statsA.points) return statsB.points.compareTo(statsA.points);
              if (statsB.goalDifference != statsA.goalDifference) return statsB.goalDifference.compareTo(statsA.goalDifference);
              return statsB.goalsFor.compareTo(statsA.goalsFor);
            });

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.leaderboard_rounded, color: AppTheme.primaryGold, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'TOURNAMENT LEADERBOARD', 
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '${sortedPlayerIds.length} ACTIVE PLAYERS', 
                        style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 100% Full-Width Container Card
                HoverCard(
                  borderRadius: BorderRadius.circular(16),
                  borderColor: AppTheme.primaryGold.withValues(alpha: 0.3),
                  glowColor: AppTheme.primaryGold,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F131C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.25), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        // Header Row (100% Full Width)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161C28),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            border: Border(bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.25))),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 32, child: Text('#', style: headerStyle)),
                              Expanded(child: Text('PLAYER (IGN)', style: headerStyle)),
                              SizedBox(width: 32, child: Text('P', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 32, child: Text('W', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 32, child: Text('D', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 32, child: Text('L', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 36, child: Text('GF', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 36, child: Text('GA', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 44, child: Text('GD', style: headerStyle, textAlign: TextAlign.center)),
                              SizedBox(width: 50, child: Text('PTS', style: headerStyle, textAlign: TextAlign.center)),
                            ],
                          ),
                        ),

                        // Player Data Rows (100% Full-Width)
                        ...sortedPlayerIds.asMap().entries.map((entry) {
                          final index = entry.key;
                          final pid = entry.value;
                          final stats = aggregateStats[pid]!;
                          final player = players.firstWhere(
                            (p) => p.id == pid, 
                            orElse: () => Player(id: pid, name: 'Unknown', email: '', ign: 'Player', uid: ''),
                          );

                          final isRank1 = index == 0;
                          final isRank2 = index == 1;
                          final isRank3 = index == 2;

                          final rankColor = isRank1 
                              ? AppTheme.primaryGold 
                              : (isRank2 ? const Color(0xFFC0C0C0) : (isRank3 ? const Color(0xFFCD7F32) : Colors.white70));

                          final rowBg = isRank1
                              ? AppTheme.primaryGold.withValues(alpha: 0.10)
                              : (isRank2 
                                  ? const Color(0xFFC0C0C0).withValues(alpha: 0.08) 
                                  : (isRank3 ? const Color(0xFFCD7F32).withValues(alpha: 0.06) : Colors.transparent));

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: rowBg,
                              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
                            ),
                            child: Row(
                              children: [
                                // Rank #
                                SizedBox(
                                  width: 32,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: index < 3
                                          ? BoxDecoration(color: rankColor, shape: BoxShape.circle)
                                          : null,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: index < 3 ? Colors.black : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Player IGN & Avatar (EXPANDED TO STRETCH FULL WIDTH)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: index < 3 ? rankColor : Colors.white24,
                                            width: index < 3 ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                                              ? WebSafeImage(
                                                  imageUrl: player.profileImageUrl!,
                                                  fit: BoxFit.cover,
                                                  fallbackWidget: Icon(Icons.person, size: 14, color: rankColor),
                                                )
                                              : Icon(Icons.person, size: 14, color: rankColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          player.ign, 
                                          style: GoogleFonts.rajdhani(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 15,
                                            color: index < 3 ? rankColor : Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isRank1) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 16),
                                      ],
                                    ],
                                  ),
                                ),

                                // P, W, D, L
                                SizedBox(width: 32, child: Text('${stats.played}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                                SizedBox(width: 32, child: Text('${stats.won}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                                SizedBox(width: 32, child: Text('${stats.drawn}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                                SizedBox(width: 32, child: Text('${stats.lost}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),

                                // GF, GA, GD
                                SizedBox(width: 36, child: Text('${stats.goalsFor}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                                SizedBox(width: 36, child: Text('${stats.goalsAgainst}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${stats.goalDifference > 0 ? '+' : ''}${stats.goalDifference}', 
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: stats.goalDifference > 0 ? AppTheme.accentGreen : (stats.goalDifference < 0 ? Colors.redAccent : Colors.white),
                                    ),
                                  ),
                                ),

                                // PTS Badge Cell
                                SizedBox(
                                  width: 50,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: index < 3
                                            ? rankColor.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: index < 3
                                              ? rankColor.withValues(alpha: 0.5)
                                              : Colors.white10,
                                        ),
                                      ),
                                      child: Text(
                                        '${stats.points}', 
                                        style: GoogleFonts.rajdhani(
                                          color: index < 3 ? rankColor : AppTheme.primaryGold, 
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
