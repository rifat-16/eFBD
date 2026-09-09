import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../models/group_model.dart';
import '../../../profile/models/player_profile_model.dart';

class GroupStandingsTable extends StatelessWidget {
  final TournamentGroup group;

  const GroupStandingsTable({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.name.toUpperCase(), 
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.primaryGold, 
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.responsiveFontSize(context, 16),
                    letterSpacing: 1,
                  )),
                Icon(Icons.leaderboard, color: AppTheme.primaryGold, size: AppTheme.responsiveFontSize(context, 20)),
              ],
            ),
          ),
          StreamBuilder<List<Player>>(
            stream: DatabaseService().getPlayersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              
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

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 48,
                  columnSpacing: AppTheme.responsiveFontSize(context, 20),
                  horizontalMargin: 16,
                  columns: [
                    _buildColumn(context, '#'),
                    _buildColumn(context, 'PLAYER'),
                    _buildColumn(context, 'P'),
                    _buildColumn(context, 'W'),
                    _buildColumn(context, 'D'),
                    _buildColumn(context, 'L'),
                    _buildColumn(context, 'GD'),
                    _buildColumn(context, 'PTS'),
                  ],
                  rows: List.generate(groupPlayers.length, (index) {
                    final player = groupPlayers[index];
                    final stats = group.playerStats[player.id] ?? GroupStats();
                    final isTopTwo = index < 2;

                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: isTopTwo ? BoxDecoration(
                              color: index == 0 ? AppTheme.primaryGold : Colors.white24,
                              shape: BoxShape.circle,
                            ) : null,
                            child: Text('${index + 1}', 
                              style: TextStyle(
                                color: isTopTwo && index == 0 ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.responsiveFontSize(context, 12),
                              )),
                          ),
                        ),
                        DataCell(
                          Row(
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
                                      : Icon(Icons.person, size: AppTheme.responsiveFontSize(context, 12), color: AppTheme.textGrey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(player.ign, style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, 
                                fontSize: AppTheme.responsiveFontSize(context, 14),
                                letterSpacing: 0.5,
                              )),
                            ],
                          ),
                        ),
                        DataCell(Text('${stats.played}', style: GoogleFonts.poppins(fontSize: AppTheme.responsiveFontSize(context, 13)))),
                        DataCell(Text('${stats.won}', style: GoogleFonts.poppins(fontSize: AppTheme.responsiveFontSize(context, 13)))),
                        DataCell(Text('${stats.drawn}', style: GoogleFonts.poppins(fontSize: AppTheme.responsiveFontSize(context, 13)))),
                        DataCell(Text('${stats.lost}', style: GoogleFonts.poppins(fontSize: AppTheme.responsiveFontSize(context, 13)))),
                        DataCell(Text('${stats.goalDifference}', style: GoogleFonts.poppins(
                          fontSize: AppTheme.responsiveFontSize(context, 13),
                          color: stats.goalDifference > 0 ? AppTheme.accentGreen : (stats.goalDifference < 0 ? Colors.redAccent : Colors.white),
                        ))),
                        DataCell(Text('${stats.points}', style: GoogleFonts.rajdhani(
                          color: AppTheme.primaryGold, 
                          fontWeight: FontWeight.bold, 
                          fontSize: AppTheme.responsiveFontSize(context, 15),
                          letterSpacing: 0.5,
                        ))),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DataColumn _buildColumn(BuildContext context, String label) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.rajdhani(
        color: AppTheme.textGrey, 
        fontSize: AppTheme.responsiveFontSize(context, 12), 
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      )),
    );
  }
}
