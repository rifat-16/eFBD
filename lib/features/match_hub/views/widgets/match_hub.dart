import '../../models/match_model.dart';
import '../../../tournament/models/tournament_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/tournament_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'match_action_card.dart';

class MatchHub extends StatefulWidget {
  const MatchHub({super.key});

  @override
  State<MatchHub> createState() => _MatchHubState();
}

class _MatchHubState extends State<MatchHub> {
  String _selectedTournamentId = '';
  Stream<List<TournamentMatch>>? _matchesStream;
  Stream<List<TournamentMatch>>? _myMatchesStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchMatchHistory(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TournamentProvider>().fetchMatchHistory(
        tournamentId: _selectedTournamentId.isEmpty ? null : _selectedTournamentId,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isMobile = ResponsiveHelper.isMobile(context);

    if (user != null && _myMatchesStream == null) {
      _myMatchesStream = DatabaseService().getMyMatches(user.uid);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user != null) ...[
          _buildMyMatchesSection(user.uid),
          const SizedBox(height: 32),
          _buildMatchHistorySection(user.uid),
          const SizedBox(height: 40),
        ],
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppTheme.primaryGold),
                      const SizedBox(width: 12),
                      Text(
                        'LIVE MATCH CENTER',
                        style: GoogleFonts.rajdhani(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTournamentSelector(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppTheme.primaryGold),
                      const SizedBox(width: 12),
                      Text(
                        'LIVE MATCH CENTER',
                        style: GoogleFonts.rajdhani(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildTournamentSelector(),
                ],
              ),
        const SizedBox(height: 24),
        if (_selectedTournamentId.isEmpty)
          Center(child: Text('SELECT A TOURNAMENT TO VIEW MATCHES.', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2)))
        else
          StreamBuilder<List<TournamentMatch>>(
            stream: _matchesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
              }
              final matches = snapshot.data ?? [];
              if (matches.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('NO MATCHES SCHEDULED YET.', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                );
              }

              return Column(
                children: matches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MatchActionCard(
                    match: match,
                    isLive: !match.isCompleted && match.timestamp.isBefore(DateTime.now()),
                  ),
                )).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMyMatchesSection(String playerId) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return StreamBuilder<List<TournamentMatch>>(
      stream: _myMatchesStream,
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        if (matches.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.accentGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'YOUR ACTIVE MATCHES',
                    style: GoogleFonts.rajdhani(
                      fontSize: isMobile ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${matches.length} PENDING',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...matches.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MatchActionCard(
                match: match,
                isLive: !match.isCompleted && match.timestamp.isBefore(DateTime.now()),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildMatchHistorySection(String playerId) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Consumer<TournamentProvider>(
      builder: (context, provider, child) {
        final matches = provider.matchHistory;
        if (matches.isEmpty && !provider.isLoadingHistory) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.accentBlue),
                const SizedBox(width: 12),
                Text(
                  'MATCH HISTORY',
                  style: GoogleFonts.rajdhani(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...matches.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MatchActionCard(
                match: match,
                isLive: false,
              ),
            )),
            if (provider.isLoadingHistory)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              )),
              Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No more matches in history', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14)),
              )),
          ],
        );
      },
    );
  }

  Widget _buildTournamentSelector() {
    return StreamBuilder<List<Tournament>>(
      stream: DatabaseService().getTournaments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final tournaments = snapshot.data!.where((t) => t.status != TournamentStatus.completed).toList();
        if (tournaments.isEmpty) return const SizedBox.shrink();

        if (_selectedTournamentId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedTournamentId.isEmpty) {
              setState(() {
                _selectedTournamentId = tournaments.first.id;
                _matchesStream = DatabaseService().getMatches(tournaments.first.id);
              });
            }
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButton<String>(
            value: _selectedTournamentId.isEmpty ? null : _selectedTournamentId,
            underline: const SizedBox(),
            dropdownColor: AppTheme.cardBackground,
            hint: Text('SELECT TOURNAMENT', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            items: tournaments.map((t) => DropdownMenuItem(
              value: t.id,
              child: Text(t.title.toUpperCase(), style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedTournamentId = val;
                  _matchesStream = DatabaseService().getMatches(val);
                });
              }
            },
          ),
        );
      },
    );
  }
}
