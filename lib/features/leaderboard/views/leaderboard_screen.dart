import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../profile/models/player_profile_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/leaderboard_provider.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryGold,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: [
              Tab(
                child: Text(
                  'ALL-TIME RANKING',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              Tab(
                child: Text(
                  'MONTHLY / SEASON',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
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
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEADERBOARD',
                style: GoogleFonts.rajdhani(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The elite tier of eFootballers in Bangladesh.',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: isMobile ? 14 : 16),
              ),
            ],
          ),
          IconButton(
            onPressed: () => GoRouter.of(context).push('/season-archive'),
            icon: const Icon(Icons.history_toggle_off, color: AppTheme.primaryGold, size: 28),
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        final isLoading = widget.isAllTime ? provider.isLoading : provider.isMonthlyLoading;
        
        if (isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
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
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                          child: _buildPodium(players.take(3).toList()),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTableHeaderDelegate(
                          minHeight: 50,
                          maxHeight: 50,
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
            height: isMobile ? 120 : 160, 
            color: Colors.white70,
            isMonthly: !widget.isAllTime,
          ),
        if (topPlayers.length >= 2) SizedBox(width: isMobile ? 10 : 20),
        
        _PodiumSpot(
          player: topPlayers[0], 
          rank: 1, 
          height: isMobile ? 150 : 200, 
          color: AppTheme.primaryGold,
          isMonthly: !widget.isAllTime,
        ),
        
        if (topPlayers.length >= 3) ...[
          SizedBox(width: isMobile ? 10 : 20),
          _PodiumSpot(
            player: topPlayers[2], 
            rank: 3, 
            height: isMobile ? 100 : 140, 
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
  final double height;
  final Color color;
  final bool isMonthly;

  const _PodiumSpot({
    required this.player, 
    required this.rank, 
    required this.height, 
    required this.color,
    this.isMonthly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final avatarRadius = rank == 1 ? (isMobile ? 45.0 : 55.0) : (isMobile ? 35.0 : 42.0);
    final innerRadius = avatarRadius - (rank == 1 ? 4 : 3);

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: color,
                child: CircleAvatar(
                  radius: innerRadius,
                  backgroundColor: AppTheme.darkBackground,
                  child: ClipOval(
                    child: player.profileImageUrl != null
                        ? WebSafeImage(
                            imageUrl: player.profileImageUrl!,
                            fit: BoxFit.cover,
                            width: innerRadius * 2,
                            height: innerRadius * 2,
                          )
                        : Text(
                            player.ign.isNotEmpty ? player.ign[0].toUpperCase() : '?',
                            style: GoogleFonts.rajdhani(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: avatarRadius * 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -18, // Adjusted for better visibility
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 30),
                  ),
                  onEnd: () {}, // Not needed but requires a callback for loop if manually handled, here we just use TweenAnimationBuilder for simple effect
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          player.ign,
          style: GoogleFonts.rajdhani(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          width: isMobile ? 70 : 100,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.rajdhani(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                Text(
                  '${isMonthly ? player.monthlyPoints : player.totalPoints} PTS',
                  style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ],
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
      color: Colors.white.withValues(alpha: 0.05),
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
    final rankColor = rank == 1 ? AppTheme.primaryGold : (rank == 2 ? Colors.white70 : const Color(0xFFCD7F32));
    
    return InkWell(
      onTap: () => _showTrophyCabinet(context, player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.white10)),
          gradient: rank <= 3 
            ? LinearGradient(
                colors: [rankColor.withValues(alpha: 0.05), Colors.transparent],
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
                    Icon(Icons.emoji_events, size: 16, color: rankColor)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$rank', 
                    style: GoogleFonts.rajdhani(
                      fontSize: AppTheme.responsiveFontSize(context, rank <= 3 ? 16 : 14), 
                      color: rank <= 3 ? AppTheme.primaryGold : AppTheme.textGrey,
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
                      border: rank <= 3 ? Border.all(color: rankColor.withValues(alpha: 0.5), width: 1) : null,
                    ),
                    child: ClipOval(
                      child: player.profileImageUrl != null
                          ? WebSafeImage(
                              imageUrl: player.profileImageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                player.ign.isNotEmpty ? player.ign[0].toUpperCase() : '?',
                                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: AppTheme.responsiveFontSize(context, 12)),
                              ),
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
                  fontSize: AppTheme.responsiveFontSize(context, 14),
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
            final rank = rankIndex != -1 ? rankIndex + 1 : 'N/A';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUR RANK: ',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          '#$rank',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'POINTS: ',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          '${isAllTime ? player.totalPoints : player.monthlyPoints}',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
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
    return true;
  }
}
