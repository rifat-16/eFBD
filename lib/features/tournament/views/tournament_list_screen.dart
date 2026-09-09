import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../profile/views/widgets/profile_dialog.dart';
import '../models/tournament_model.dart';
import '../models/registration_model.dart';
import 'registration_dialog.dart';

import '../../../core/utils/responsive_helper.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournaments(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TournamentProvider>().fetchTournaments();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveHelper.isMobile(context);
    final bool isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: RefreshIndicator(
        onRefresh: () => context.read<TournamentProvider>().fetchTournaments(refresh: true),
        color: AppTheme.primaryGold,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24, 
                  vertical: isMobile ? 24 : 40
                ),
                child: Consumer<TournamentProvider>(
                  builder: (context, provider, child) {
                    final allTournaments = provider.tournaments;
                    final activeTournaments = allTournaments.where((t) => t.status != TournamentStatus.completed).toList();
                    final pastTournaments = allTournaments.where((t) => t.status == TournamentStatus.completed).toList();

                    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(context),
                        SizedBox(height: isMobile ? 32 : 60),
                        Text(
                          'ACTIVE TOURNAMENTS',
                          style: GoogleFonts.rajdhani(
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (provider.isLoading && activeTournaments.isEmpty)
                          const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                        else if (activeTournaments.isEmpty)
                          _buildEmptyState()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: isMobile ? 1.1 : 1.2,
                            ),
                            itemCount: activeTournaments.length,
                            itemBuilder: (context, index) => _buildTournamentCard(context, activeTournaments[index]),
                          ),
                        if (pastTournaments.isNotEmpty) ...[
                          const SizedBox(height: 48),
                          Text(
                            'PAST TOURNAMENTS',
                            style: GoogleFonts.rajdhani(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textGrey,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: isMobile ? 1.1 : 1.2,
                            ),
                            itemCount: pastTournaments.length,
                            itemBuilder: (context, index) => _buildTournamentCard(context, pastTournaments[index]),
                          ),
                        ],
                        if (provider.isLoading && allTournaments.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
                          ),
                        if (!provider.hasMore && allTournaments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No more tournaments to load',
                                style: GoogleFonts.poppins(color: AppTheme.textGrey),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGold.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EFOOTBALLERS BANGLADESH',
            style: GoogleFonts.rajdhani(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: isMobile ? 2.5 : 5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isMobile ? 'THE ULTIMATE ARENA\nFOR PROS' : 'THE ULTIMATE ARENA\nFOR BENGALI PROS',
            style: GoogleFonts.rajdhani(
              fontSize: isMobile ? 32 : 58,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Join the largest eFootball community in Bangladesh. Participate in daily tournaments and win exciting prizes.',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 18,
              color: AppTheme.textGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    return InkWell(
      onTap: () => context.go('/tournaments/${tournament.id}'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(tournament.status),
                Text(
                  tournament.isFree ? 'FREE' : '${tournament.entryFee} BDT',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              tournament.title,
              style: GoogleFonts.rajdhani(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white, 
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tournament.description,
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            StreamBuilder<List<Registration>>(
              stream: DatabaseService().getRegistrations(tournament.id),
              builder: (context, snapshot) {
                final regs = snapshot.data ?? [];
                final verifiedCount = regs.where((r) => r.status == RegistrationStatus.verified).length;
                final pendingCount = regs.where((r) => r.status == RegistrationStatus.pending).length;
                
                final auth = context.read<AuthProvider>();
                final userRegs = regs.where((r) => r.playerId == auth.user?.uid);
                final userReg = userRegs.isNotEmpty ? userRegs.first : null;
                final isFull = verifiedCount >= tournament.maxPlayers;

                return Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 8),
                        Text(
                          '$verifiedCount / ${tournament.maxPlayers} Slots',
                          style: GoogleFonts.rajdhani(
                            color: isFull ? Colors.redAccent : AppTheme.textGrey,
                            fontSize: 14,
                            fontWeight: isFull ? FontWeight.bold : FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$pendingCount PENDING',
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (userReg?.status == RegistrationStatus.pending || 
                           userReg?.status == RegistrationStatus.verified ||
                           (userReg == null && isFull)) 
                  ? null 
                  : () => _showRegistration(context, tournament),
                style: userReg?.status == RegistrationStatus.verified 
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen, 
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.accentGreen.withValues(alpha: 0.8),
                      disabledForegroundColor: Colors.white,
                    ) 
                  : ((userReg?.status == RegistrationStatus.pending || (userReg == null && isFull))
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.white10) 
                      : null),
                child: Text(
                  userReg == null 
                    ? (isFull ? 'SLOTS FULL' : 'REGISTER NOW') 
                    : (userReg.status == RegistrationStatus.pending ? 'PENDING VERIFICATION' :
                  (userReg.status == RegistrationStatus.verified ? 'JOINED' : 'RE-REGISTER')),
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color = status == TournamentStatus.upcoming ? AppTheme.primaryGold : (status == TournamentStatus.ongoing ? AppTheme.accentBlue : AppTheme.accentGreen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.rajdhani(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.sports_esports, size: 64, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          Text('No tournaments found.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  void _showRegistration(BuildContext context, Tournament tournament) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.user != null;

    if (isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TournamentRegistrationDialog(tournament: tournament),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: const ProfileDialog(player: null),
          ),
        ),
      );
    }
  }
}
