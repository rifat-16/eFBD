import 'package:flutter/material.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../../match_hub/models/match_model.dart';
import '../../../profile/models/player_profile_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class KnockoutBracket extends StatelessWidget {
  final String? tournamentId;

  static const double matchCardHeight = 90.0;
  static const double matchCardWidth = 200.0;
  static const double verticalGap = 30.0;
  static const double columnSpacing = 60.0;
  static const double columnWidth = matchCardWidth + columnSpacing;

  const KnockoutBracket({super.key, this.tournamentId});

  @override
  Widget build(BuildContext context) {
    if (tournamentId == null || tournamentId!.isEmpty) {
      return const Center(
        child: Text('Tournament ID missing', style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<List<TournamentMatch>>(
      stream: DatabaseService().getMatches(tournamentId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold),
          );
        }

        final allMatches = snapshot.data ?? [];
        
        // Filter out Qualifying Round and Group Stage from the main bracket view
        final koMatches = allMatches.where((m) => 
          (m.groupId == null || m.groupId!.isEmpty) && 
          m.round != 'Group Stage' && 
          m.round != 'Qualifying Round'
        ).toList();

        final hasQualifying = allMatches.any((m) => m.round == 'Qualifying Round');
        final allQualifyingCompleted = hasQualifying && allMatches
            .where((m) => m.round == 'Qualifying Round')
            .every((m) => m.isVerified);
        
        final hasGroupStage = allMatches.any((m) => m.round == 'Group Stage');
        final allGroupsCompleted = hasGroupStage && allMatches
            .where((m) => m.round == 'Group Stage')
            .every((m) => m.isVerified);

        if (koMatches.isEmpty) {
          String mainMessage = 'KNOCKOUT FIXTURES NOT GENERATED';
          String subMessage = 'Generate matches from the Matches tab to see the bracket.';
          IconData icon = Icons.account_tree_outlined;

          if (hasQualifying && !allQualifyingCompleted) {
            mainMessage = 'QUALIFYING ROUND IN PROGRESS';
            subMessage = 'Knockout bracket will be available after qualifiers.';
            icon = Icons.timer_outlined;
          } else if (hasQualifying && allQualifyingCompleted && !hasGroupStage) {
            mainMessage = 'QUALIFIERS COMPLETED';
            subMessage = 'Waiting for Group Stage or Knockout generation.';
            icon = Icons.check_circle_outline;
          } else if (hasGroupStage && !allGroupsCompleted) {
            mainMessage = 'GROUP STAGE IN PROGRESS';
            subMessage = 'Knockout bracket will be generated after group stage.';
            icon = Icons.grid_view;
          } else if (hasGroupStage && allGroupsCompleted) {
            mainMessage = 'GROUP STAGE COMPLETED';
            subMessage = 'Waiting for knockout bracket generation.';
            icon = Icons.emoji_events_outlined;
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.primaryGold, size: 64),
                const SizedBox(height: 16),
                Text(
                  mainMessage,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subMessage,
                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final rounds = _groupMatchesByRound(koMatches);
        final activeRounds = _getActiveRounds(rounds);

        if (activeRounds.isEmpty) {
          return Center(child: Text('NO KNOCKOUT ROUNDS FOUND', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2)));
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: AppTheme.darkBackground,
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(800),
            minScale: 0.05,
            maxScale: 2.0,
            child: _buildDualSidedBracket(rounds, activeRounds),
          ),
        );
      },
    );
  }

  String _normalizeRoundName(String round) {
    final normalized = round.trim().toLowerCase();
    if (normalized == 'final' || normalized == 'grand final') return 'Final';
    if (normalized == 'semi finals' || normalized == 'semi final') return 'Semi Finals';
    if (normalized == 'quarter finals' || normalized == 'quarter final') return 'Quarter Finals';
    if (normalized == '3rd place' || normalized == 'third place' || normalized == '3rd place match') return '3rd Place';
    if (normalized.startsWith('round of ')) {
      final parts = normalized.split(' ');
      if (parts.length >= 3) {
        return "Round of ${parts.last}";
      }
    }
    return round;
  }

  Map<String, List<TournamentMatch>> _groupMatchesByRound(List<TournamentMatch> matches) {
    final Map<String, List<TournamentMatch>> rounds = {};
    for (var match in matches) {
      if (match.round.toLowerCase() == 'group stage') continue;
      final normalized = _normalizeRoundName(match.round);
      rounds.putIfAbsent(normalized, () => []).add(match);
    }
    rounds.forEach((key, list) => list.sort((a, b) => a.bracketIndex.compareTo(b.bracketIndex)));
    return rounds;
  }

  List<String> _getActiveRounds(Map<String, List<TournamentMatch>> rounds) {
    const sequence = [
      'Round of 512',
      'Round of 256',
      'Round of 128',
      'Round of 64',
      'Round of 32',
      'Round of 16',
      'Quarter Finals',
      'Semi Finals',
      'Final'
    ];
    
    // Find the first round that exists in the sequence
    int firstRoundIdx = -1;
    for (int i = 0; i < sequence.length; i++) {
      if (rounds.containsKey(sequence[i])) {
        firstRoundIdx = i;
        break;
      }
    }

    if (firstRoundIdx == -1) {
      final others = rounds.keys.where((r) => !sequence.contains(r)).toList()..sort();
      return others;
    }

    // Include all rounds from the first one onwards, even if they don't have matches yet
    // This ensures TBD rounds/cards show up if a previous round exists
    final List<String> active = [];
    for (int i = firstRoundIdx; i < sequence.length; i++) {
      active.add(sequence[i]);
    }

    // Add any unknown rounds that might be at the end (like 3rd place, though we filter it usually)
    final others = rounds.keys.where((r) => !sequence.contains(r) && r != '3rd Place').toList()..sort();
    active.addAll(others);
    return active;
  }

  Widget _buildDualSidedBracket(Map<String, List<TournamentMatch>> rounds, List<String> activeRounds) {
    final String finalRoundName = activeRounds.contains('Final') ? 'Final' : activeRounds.last;
    final List<String> bracketRounds = activeRounds.where((r) => r != finalRoundName && r != '3rd Place').toList();
    
    final Map<String, List<TournamentMatch>> leftMatches = {};
    final Map<String, List<TournamentMatch>> rightMatches = {};

    final String firstRound = bracketRounds.isNotEmpty ? bracketRounds.first : finalRoundName;
    final int firstRoundCount = rounds[firstRound]?.length ?? 0;
    
    for (int i = 0; i < bracketRounds.length; i++) {
      final round = bracketRounds[i];
      final matches = rounds[round] ?? [];
      
      final int expectedCount = (firstRoundCount / math.pow(2, i)).ceil();
      final mid = (expectedCount / 2).ceil();

      final List<TournamentMatch> fullRoundMatches = List.generate(expectedCount, (index) {
        return matches.firstWhere(
          (m) => m.bracketIndex == index,
          orElse: () => TournamentMatch(
            id: 'tbd_$round\_$index',
            tournamentId: '',
            player1Id: '',
            player2Id: '',
            player1Ign: 'TBD',
            player2Ign: 'TBD',
            timestamp: DateTime.now(),
            round: round,
            bracketIndex: index,
            isCompleted: false,
          ),
        );
      });

      leftMatches[round] = fullRoundMatches.sublist(0, mid);
      rightMatches[round] = fullRoundMatches.sublist(mid);
    }

    final int displayMatchCount = math.max(firstRoundCount, 8);
    final double totalHeight = (matchCardHeight + verticalGap) * (displayMatchCount / 2) + 350;

    return Padding(
      padding: const EdgeInsets.all(200.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Outermost -> Innermost
          ...List.generate(bracketRounds.length, (i) {
            final round = bracketRounds[i];
            return _buildRoundColumn(
              round, 
              leftMatches[round] ?? [], 
              i, 
              true, 
              true, 
              totalHeight,
              isLast: i == bracketRounds.length - 1,
            );
          }),

          // Center: Final & Champion
          _buildCenterColumn(rounds[finalRoundName]?.firstOrNull, rounds['3rd Place']?.firstOrNull, totalHeight),

          // Right side: Innermost -> Outermost
          ...List.generate(bracketRounds.length, (i) {
            final index = bracketRounds.length - 1 - i;
            final round = bracketRounds[index];
            return _buildRoundColumn(
              round, 
              rightMatches[round] ?? [], 
              index, 
              true, 
              false, 
              totalHeight,
              isLast: index == bracketRounds.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoundColumn(
    String title,
    List<TournamentMatch> matches,
    int roundIndex,
    bool hasNextRound,
    bool isLeft,
    double totalHeight, {
    bool isLast = false,
  }) {
    final double slotHeight = (matchCardHeight + verticalGap) * math.pow(2, roundIndex);
    final double firstCardTop = (totalHeight / 2) - (slotHeight * matches.length / 2) + (slotHeight / 2) - (matchCardHeight / 2);
    final double connectorWidth = isLast ? columnSpacing * 2 : columnSpacing;

    return SizedBox(
      width: columnWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: firstCardTop - 45,
            left: isLeft ? 0 : columnSpacing,
            width: matchCardWidth,
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: AppTheme.primaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ...List.generate(matches.length, (index) {
            final double top = firstCardTop + (index * slotHeight);
            return Positioned(
              top: top,
              left: isLeft ? 0 : columnSpacing,
              child: SizedBox(
                width: matchCardWidth,
                height: matchCardHeight,
                child: _BracketMatchCard(match: matches[index]),
              ),
            );
          }),
          if (hasNextRound && matches.isNotEmpty)
            ...List.generate(matches.length, (index) {
              final double top = firstCardTop + (index * slotHeight);
              return Positioned(
                top: top,
                left: isLeft ? matchCardWidth : (isLast ? -columnSpacing : 0),
                child: CustomPaint(
                  size: Size(connectorWidth, matchCardHeight),
                  painter: BracketConnectorPainter(
                    isEven: index % 2 == 0,
                    slotHeight: slotHeight,
                    columnSpacing: connectorWidth,
                    isLeft: isLeft,
                    isStraight: matches.length == 1,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCenterColumn(TournamentMatch? finalMatch, TournamentMatch? thirdPlaceMatch, double totalHeight) {
    return SizedBox(
      width: matchCardWidth + 120,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Final Match & Title
          Positioned(
            top: (totalHeight / 2) - (matchCardHeight / 2),
            left: 60,
            child: SizedBox(
              width: matchCardWidth,
              height: matchCardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -45,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'GRAND FINAL',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.primaryGold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: finalMatch != null ? _BracketMatchCard(match: finalMatch) : _buildTbdCard(),
                  ),
                ],
              ),
            ),
          ),

          // Champion Section
          if (finalMatch != null && finalMatch.isCompleted)
            Positioned(
              bottom: (totalHeight / 2) + 120,
              left: 0,
              right: 0,
              child: _buildChampionSection(finalMatch),
            ),

          // 3rd Place Match
          if (thirdPlaceMatch != null)
            Positioned(
              top: (totalHeight / 2) + (matchCardHeight / 2) + 120,
              left: 60,
              child: SizedBox(
                width: matchCardWidth,
                height: matchCardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '3RD PLACE MATCH',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.primaryGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _BracketMatchCard(match: thirdPlaceMatch),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTbdCard() {
    return Container(
      width: matchCardWidth,
      height: matchCardHeight,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          'TBD',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textGrey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChampionSection(TournamentMatch finalMatch) {
    final winnerName = (finalMatch.player1Score ?? 0) > (finalMatch.player2Score ?? 0) ? finalMatch.player1Ign : finalMatch.player2Ign;

    return Column(
      children: [
        const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 70),
        const SizedBox(height: 12),
        Text(
          'TOURNAMENT CHAMPION',
          style: GoogleFonts.rajdhani(
            color: AppTheme.primaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border.all(color: AppTheme.primaryGold, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Text(
            winnerName.toUpperCase(),
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final TournamentMatch match;
  const _BracketMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border.all(
          color: match.id.startsWith('tbd_') 
              ? AppTheme.primaryGold.withValues(alpha: 0.05)
              : (match.isCompleted ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.2)),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPlayerRow(match.player1Ign, match.player1Id, match.player1Score, match.player2Score, match.id.startsWith('tbd_')),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          _buildPlayerRow(match.player2Ign, match.player2Id, match.player2Score, match.player1Score, match.id.startsWith('tbd_')),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(String name, String? playerId, int? score, int? opponentScore, bool isTbd) {
    final String displayName = name.isEmpty ? (isTbd ? 'TBD' : 'BYE') : name;
    final bool isWinner = score != null && opponentScore != null && score > opponentScore;
    final color = isTbd ? AppTheme.textGrey.withValues(alpha: 0.3) : (isWinner ? Colors.white : AppTheme.textGrey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (playerId != null && playerId.isNotEmpty && playerId != 'BYE' && !isTbd) ...[
            StreamBuilder<Player?>(
              stream: DatabaseService().getPlayerStream(playerId),
              builder: (context, snapshot) {
                final player = snapshot.data;
                return Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: ClipOval(
                    child: player?.profileImageUrl != null
                        ? WebSafeImage(
                            imageUrl: player!.profileImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, size: 10, color: AppTheme.textGrey),
                  ),
                );
              },
            ),
          ] else if (!isTbd) ...[
            const Icon(Icons.person, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              displayName.toUpperCase(),
              style: GoogleFonts.rajdhani(
                color: color, 
                fontSize: 12, 
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isTbd)
            Text(
              score?.toString() ?? '-',
              style: GoogleFonts.rajdhani(color: isWinner ? AppTheme.primaryGold : AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
        ],
      ),
    );
  }
}

class BracketConnectorPainter extends CustomPainter {
  final bool isEven;
  final double slotHeight;
  final double columnSpacing;
  final bool isLeft;
  final bool isStraight;

  BracketConnectorPainter({
    required this.isEven,
    required this.slotHeight,
    required this.columnSpacing,
    required this.isLeft,
    required this.isStraight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double startX = isLeft ? 0 : columnSpacing;
    final double endX = isLeft ? columnSpacing : 0;
    final double midX = columnSpacing / 2;
    final double startY = size.height / 2;
    
    final path = Path();
    path.moveTo(startX, startY);
    
    if (isStraight) {
      path.lineTo(endX, startY);
    } else {
      final double verticalOffset = slotHeight / 2;
      final double targetY = startY + (isEven ? verticalOffset : -verticalOffset);
      final double cornerSize = math.min(20.0, (verticalOffset.abs() / 2));
      
      // Horizontal to start of curve
      path.lineTo(midX + (isLeft ? -cornerSize : cornerSize), startY);
      
      // Curve to vertical
      path.quadraticBezierTo(
        midX, startY, 
        midX, startY + (isEven ? cornerSize : -cornerSize)
      );
      
      // Vertical line
      path.lineTo(midX, targetY + (isEven ? -cornerSize : cornerSize));
      
      // Curve to horizontal
      path.quadraticBezierTo(
        midX, targetY, 
        midX + (isLeft ? cornerSize : -cornerSize), targetY
      );
      
      // Horizontal to end
      path.lineTo(endX, targetY);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
