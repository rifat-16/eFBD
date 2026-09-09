import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
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
        if (!matchSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
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

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GOLDEN BOOT RACE', style: GoogleFonts.rajdhani(fontSize: 20, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Icon(Icons.bolt, color: AppTheme.primaryGold),
                  ],
                ),
                const SizedBox(height: 24),
                ...sortedPlayerIds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pid = entry.value;
                  final goals = goalStats[pid]!;
                  final player = players.firstWhere((p) => p.id == pid, orElse: () => Player(id: pid, name: 'Unknown', email: '', ign: 'Player', uid: ''));
                  
                  final isTop = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTop ? AppTheme.primaryGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isTop ? AppTheme.primaryGold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${index + 1}', 
                            style: GoogleFonts.rajdhani(
                              color: isTop ? AppTheme.primaryGold : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            )
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 40,
                          height: 40,
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
                                : const Icon(Icons.person, color: AppTheme.textGrey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.ign, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                              Text(player.name, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$goals', style: GoogleFonts.rajdhani(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold,
                              color: isTop ? AppTheme.primaryGold : Colors.white,
                              letterSpacing: 1,
                            )),
                            Text('GOALS', style: GoogleFonts.rajdhani(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                        if (isTop) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.workspace_premium, color: AppTheme.primaryGold, size: 28),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
