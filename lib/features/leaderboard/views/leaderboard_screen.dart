import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../profile/models/player_profile_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/leaderboard_provider.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../../core/utils/responsive_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          _buildTopSection(context),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGold,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryGold,
              unselectedLabelColor: AppTheme.textGrey,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ALL-TIME RANKING',
                        style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'MONTHLY / SEASON',
                        style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                LeaderboardTabContent(isAllTime: true),
                LeaderboardTabContent(isAllTime: false),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyUserRankBar(controller: _tabController),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.military_tech_rounded, color: AppTheme.primaryGold, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEADERBOARD',
                    style: GoogleFonts.rajdhani(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'The elite tier of eFootballers in Bangladesh.',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: isMobile ? 12 : 14),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => GoRouter.of(context).push('/season-archive'),
            icon: const Icon(Icons.history_toggle_off_rounded, color: AppTheme.primaryGold, size: 28),
            tooltip: 'Season Archive',
          ),
        ],
      ),
    );
  }
}

class LeaderboardTabContent extends StatefulWidget {
  final bool isAllTime;
  const LeaderboardTabContent({super.key, required this.isAllTime});

  @override
  State<LeaderboardTabContent> createState() => _LeaderboardTabContentState();
}

class _LeaderboardTabContentState extends State<LeaderboardTabContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        final isLoading = widget.isAllTime ? provider.isLoading : provider.isMonthlyLoading;
        
        if (isLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryGold)));
        }
        
        final players = widget.isAllTime ? provider.players : provider.monthlyPlayers;
        
        if (players.isEmpty) {
          return const Center(
            child: Text(
              'No players found.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        final minTableWidth = isMobile ? 800.0 : 1000.0;

        return RefreshIndicator(
          onRefresh: () async => widget.isAllTime ? provider.fetchLeaderboard() : provider.fetchMonthlyLeaderboard(),
          color: AppTheme.primaryGold,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                          child: _buildPodium(players.take(3).toList()),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTableHeaderDelegate(
                          minHeight: 48,
                          maxHeight: 48,
                          child: Container(
                            color: AppTheme.darkBackground,
                            child: const _TableHeader(),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _PlayerRow(
                            rank: index + 1,
                            player: players[index],
                            isMonthly: !widget.isAllTime,
                          ),
                          childCount: players.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<Player> topPlayers) {
    if (topPlayers.isEmpty) return const SizedBox.shrink();
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (topPlayers.length >= 2)
          _PodiumSpot(
            player: topPlayers[1], 
            rank: 2, 
            color: const Color(0xFFC0C0C0),
            isMonthly: !widget.isAllTime,
          ),
        if (topPlayers.length >= 2) SizedBox(width: isMobile ? 12 : 24),
        
        _PodiumSpot(
          player: topPlayers[0], 
          rank: 1, 
          color: AppTheme.primaryGold,
          isMonthly: !widget.isAllTime,
        ),
        
        if (topPlayers.length >= 3) ...[
          SizedBox(width: isMobile ? 12 : 24),
          _PodiumSpot(
            player: topPlayers[2], 
            rank: 3, 
            color: const Color(0xFFCD7F32),
            isMonthly: !widget.isAllTime,
          ),
        ],
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final Player player;
  final int rank;
  final Color color;
  final bool isMonthly;

  const _PodiumSpot({
    required this.player, 
    required this.rank, 
    required this.color,
    this.isMonthly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final cardWidth = isMobile ? 110.0 : 150.0;
    final points = isMonthly ? player.monthlyPoints : player.totalPoints;
    final rating = (85 + points.clamp(0, 14)).toInt();

    String title = rank == 1 ? '👑 CHAMP' : (rank == 2 ? '🥈 RUNNER' : '🥉 3RD');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rank == 1
                ? [const Color(0xFF38290A), const Color(0xFF161004)]
                : (rank == 2
                    ? [const Color(0xFF1D2838), const Color(0xFF0E141E)]
                    : [const Color(0xFF362013), const Color(0xFF170E08)]),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.8), width: rank == 1 ? 2.0 : 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: rank == 1 ? 0.35 : 0.2),
              blurRadius: rank == 1 ? 20 : 12,
              spreadRadius: rank == 1 ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$rating',
                    style: GoogleFonts.rajdhani(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.rajdhani(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Avatar Frame with Glow
            Container(
              width: isMobile ? 54 : 68,
              height: isMobile ? 54 : 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: rank == 1 ? 2.5 : 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: ClipOval(
                child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                    ? WebSafeImage(
                        imageUrl: player.profileImageUrl!,
                        fit: BoxFit.cover,
                        fallbackWidget: Icon(
                          Icons.person,
                          color: color,
                          size: isMobile ? 28 : 36,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: color,
                        size: isMobile ? 28 : 36,
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // IGN Name
            Text(
              player.ign,
              style: GoogleFonts.rajdhani(
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Points Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$points PTS',
                style: GoogleFonts.rajdhani(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.rajdhani(
      fontWeight: FontWeight.bold, 
      fontSize: AppTheme.responsiveFontSize(context, 12), 
      color: AppTheme.primaryGold,
      letterSpacing: 1,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        border: Border(bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text('RANK', style: textStyle)),
          Expanded(child: Text('PLAYER (IGN)', style: textStyle)),
          SizedBox(width: 160, child: Text('TROPHY SHOWCASE', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('P', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('W', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('D', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('L', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('GF', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('GA', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 50, child: Text('GD', style: textStyle, textAlign: TextAlign.center)),
          SizedBox(width: 60, child: Text('PTS', style: textStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int rank;
  final Player player;
  final bool isMonthly;

  const _PlayerRow({
    required this.rank, 
    required this.player,
    this.isMonthly = false,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1 ? AppTheme.primaryGold : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    
    return InkWell(
      onTap: () => _showTrophyCabinet(context, player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.white10)),
          gradient: rank <= 3 
            ? LinearGradient(
                colors: [rankColor.withValues(alpha: 0.08), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Row(
                children: [
                  if (rank <= 3)
                    Icon(Icons.emoji_events_rounded, size: 16, color: rankColor)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$rank', 
                    style: GoogleFonts.rajdhani(
                      fontSize: AppTheme.responsiveFontSize(context, rank <= 3 ? 16 : 14), 
                      color: rank <= 3 ? rankColor : AppTheme.textGrey,
                      fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: rank <= 3 ? Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5) : null,
                    ),
                    child: ClipOval(
                      child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                          ? WebSafeImage(
                              imageUrl: player.profileImageUrl!,
                              fit: BoxFit.cover,
                              fallbackWidget: Icon(
                                Icons.person,
                                size: 16,
                                color: rankColor,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 16,
                              color: rankColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    player.ign,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.responsiveFontSize(context, 14),
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _trophyIcon(context, '🏆', player.champions, 'Champions'),
                  _trophyIcon(context, '🥈', player.runnersUp, 'Runners-up'),
                  _trophyIcon(context, '👟', player.goldenBoots, 'Golden Boots'),
                ],
              ),
            ),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyMatchesPlayed : player.matchesPlayed}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyWins : player.wins}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyDraws : player.draws}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyLosses : player.losses}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyGoalsFor : player.goalsFor}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 40, child: Text('${isMonthly ? player.monthlyGoalsAgainst : player.goalsAgainst}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white))),
            SizedBox(width: 50, child: Text('${(isMonthly ? player.monthlyGoalDifference : player.goalDifference) > 0 ? '+' : ''}${isMonthly ? player.monthlyGoalDifference : player.goalDifference}', textAlign: TextAlign.center, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 13), color: Colors.white70))),
            SizedBox(
              width: 60,
              child: Text(
                '${isMonthly ? player.monthlyPoints : player.totalPoints}',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: AppTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.responsiveFontSize(context, 16),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trophyIcon(BuildContext context, String icon, int count, String label) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: AppTheme.responsiveFontSize(context, 14))),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.responsiveFontSize(context, 11),
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrophyCabinet(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('${player.ign.toUpperCase()}\'S CABINET', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cabinetItem('🏆 Champions', player.champions),
            _cabinetItem('🥈 Runners-up', player.runnersUp),
            _cabinetItem('👟 Golden Boots', player.goldenBoots),
          ],
        ),
      ),
    );
  }

  Widget _cabinetItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          Text(
            '$count',
            style: GoogleFonts.rajdhani(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class StickyUserRankBar extends StatelessWidget {
  final TabController controller;
  const StickyUserRankBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isAllTime = controller.index == 0;
        
        return Consumer2<AuthProvider, LeaderboardProvider>(
          builder: (context, auth, lb, child) {
            if (!auth.isAuthenticated || auth.playerProfile == null) return const SizedBox.shrink();

            final player = auth.playerProfile!;
            final players = isAllTime ? lb.players : lb.monthlyPlayers;
            final rankIndex = players.indexWhere((p) => p.id == player.id);
            final rank = rankIndex != -1 ? '#${rankIndex + 1}' : 'N/A';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131C),
                border: Border(top: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppTheme.primaryGold, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          player.ign.toUpperCase(),
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'YOUR RANK: ',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                rank,
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'PTS: ',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '${isAllTime ? player.totalPoints : player.monthlyPoints}',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
            );
          },
        );
      },
    );
  }
}

class _SliverTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverTableHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverTableHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
