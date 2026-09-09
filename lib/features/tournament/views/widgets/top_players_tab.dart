import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../models/tournament_model.dart';
import '../../models/group_model.dart';
import '../../../match_hub/models/match_model.dart';
import '../../../profile/models/player_profile_model.dart';

class TopPlayersTab extends StatelessWidget {
  final Tournament tournament;
  const TopPlayersTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentMatch>>(
      stream: DatabaseService().getMatches(tournament.id),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
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
                    Text('TOURNAMENT LEADERBOARD', style: GoogleFonts.rajdhani(fontSize: 20, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text('${sortedPlayerIds.length} ACTIVE PLAYERS', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowHeight: 56,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 56,
                      columns: [
                        DataColumn(label: Text('#', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('PLAYER', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('P', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('W', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('D', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('L', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('GF', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('GA', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('GD', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
                        DataColumn(label: Text('PTS', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1))),
                      ],
                      rows: sortedPlayerIds.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final pid = entry.value;
                        final stats = aggregateStats[pid]!;
                        final player = players.firstWhere((p) => p.id == pid, orElse: () => Player(id: pid, name: 'Unknown', email: '', ign: 'Player', uid: ''));

                        final isTop3 = index < 3;
                        return DataRow(cells: [
                          DataCell(Text('${index + 1}', style: GoogleFonts.rajdhani(color: isTop3 ? AppTheme.primaryGold : Colors.white70, fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                child: ClipOval(
                                  child: player.profileImageUrl != null
                                      ? WebSafeImage(
                                          imageUrl: player.profileImageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.person, size: 12, color: AppTheme.textGrey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(player.ign, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                              if (index == 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 16),
                              ],
                            ],
                          )),
                          DataCell(Text('${stats.played}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.won}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.drawn}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.lost}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.goalsFor}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.goalsAgainst}', style: GoogleFonts.poppins(fontSize: 14))),
                          DataCell(Text('${stats.goalDifference > 0 ? '+' : ''}${stats.goalDifference}', style: GoogleFonts.poppins(fontSize: 14, color: stats.goalDifference > 0 ? AppTheme.accentGreen : (stats.goalDifference < 0 ? Colors.redAccent : Colors.white)))),
                          DataCell(Text('${stats.points}', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))),
                        ]);
                      }).toList(),
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
