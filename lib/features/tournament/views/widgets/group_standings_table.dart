import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../models/group_model.dart';
import '../../../profile/models/player_profile_model.dart';

class GroupStandingsTable extends StatelessWidget {
  final TournamentGroup group;

  const GroupStandingsTable({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.rajdhani(
      color: AppTheme.textGrey,
      fontSize: AppTheme.responsiveFontSize(context, 11),
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    );

    return HoverCard(
      borderRadius: BorderRadius.circular(16),
      borderColor: AppTheme.primaryGold.withValues(alpha: 0.4),
      glowColor: AppTheme.primaryGold,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F131C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fancy Header Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161C28),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(
                  bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.25)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        group.name.toUpperCase(), 
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.primaryGold, 
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.responsiveFontSize(context, 16),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'TOP 2 QUALIFY',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.accentGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            StreamBuilder<List<Player>>(
              stream: DatabaseService().getPlayersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primaryGold)));
                }
                
                final allPlayers = snapshot.data ?? [];
                final groupPlayers = allPlayers.where((p) => group.playerIds.contains(p.id)).toList();
                
                // Sort players by points, then GD, then Goals For
                groupPlayers.sort((a, b) {
                  final statsA = group.playerStats[a.id] ?? GroupStats();
                  final statsB = group.playerStats[b.id] ?? GroupStats();
                  if (statsB.points != statsA.points) {
                    return statsB.points.compareTo(statsA.points);
                  }
                  if (statsB.goalDifference != statsA.goalDifference) {
                    return statsB.goalDifference.compareTo(statsA.goalDifference);
                  }
                  return statsB.goalsFor.compareTo(statsA.goalsFor);
                });

                return Column(
                  children: [
                    // Table Column Headers Row (100% Full Width)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 28, child: Text('#', style: headerStyle)),
                          Expanded(child: Text('PLAYER', style: headerStyle)),
                          SizedBox(width: 28, child: Text('P', style: headerStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('W', style: headerStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('D', style: headerStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('L', style: headerStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 38, child: Text('GD', style: headerStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 44, child: Text('PTS', style: headerStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // Player Rows (100% Full Width Edge-to-Edge)
                    ...List.generate(groupPlayers.length, (index) {
                      final player = groupPlayers[index];
                      final stats = group.playerStats[player.id] ?? GroupStats();
                      final isRank1 = index == 0;
                      final isRank2 = index == 1;

                      final rowColor = isRank1
                          ? AppTheme.primaryGold.withValues(alpha: 0.12)
                          : (isRank2 ? AppTheme.accentGreen.withValues(alpha: 0.08) : Colors.transparent);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: rowColor,
                          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
                        ),
                        child: Row(
                          children: [
                            // # Rank Cell
                            SizedBox(
                              width: 28,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: isRank1
                                      ? const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle)
                                      : (isRank2 ? const BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle) : null),
                                  child: Text(
                                    '${index + 1}', 
                                    style: TextStyle(
                                      color: isRank1 ? Colors.black : (isRank2 ? Colors.black : Colors.white70),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Player Avatar + IGN Cell (EXPANDED TO STRETCH 100% WIDTH)
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isRank1 
                                            ? AppTheme.primaryGold 
                                            : (isRank2 ? AppTheme.accentGreen : Colors.white24),
                                        width: isRank1 || isRank2 ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                                          ? WebSafeImage(
                                              imageUrl: player.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              fallbackWidget: Icon(
                                                Icons.person, 
                                                size: 12, 
                                                color: isRank1 ? AppTheme.primaryGold : AppTheme.textGrey,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person, 
                                              size: 12, 
                                              color: isRank1 ? AppTheme.primaryGold : AppTheme.textGrey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      player.ign, 
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: AppTheme.responsiveFontSize(context, 14),
                                        color: isRank1 ? AppTheme.primaryGold : Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // P, W, D, L Cells
                            SizedBox(width: 28, child: Text('${stats.played}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white))),
                            SizedBox(width: 28, child: Text('${stats.won}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white))),
                            SizedBox(width: 28, child: Text('${stats.drawn}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white))),
                            SizedBox(width: 28, child: Text('${stats.lost}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white))),

                            // GD Cell
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${stats.goalDifference > 0 ? '+' : ''}${stats.goalDifference}', 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: stats.goalDifference > 0 ? AppTheme.accentGreen : (stats.goalDifference < 0 ? Colors.redAccent : Colors.white),
                                ),
                              ),
                            ),

                            // PTS Badge Cell
                            SizedBox(
                              width: 44,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isRank1 || isRank2
                                        ? AppTheme.primaryGold.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isRank1 || isRank2
                                          ? AppTheme.primaryGold.withValues(alpha: 0.5)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Text(
                                    '${stats.points}', 
                                    style: GoogleFonts.rajdhani(
                                      color: AppTheme.primaryGold, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 13,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
