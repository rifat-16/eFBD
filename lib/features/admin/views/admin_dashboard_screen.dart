import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'admin_profile_requests_view.dart';
import '../../tournament/models/registration_model.dart';
import '../../tournament/models/tournament_model.dart';
import '../../match_hub/models/match_model.dart';
import '../../profile/models/player_profile_model.dart';
import '../../profile/models/trophy_model.dart';
import '../../profile/views/widgets/profile_dialog.dart';
import '../../../core/services/database_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/tournament_create_form.dart';
import '../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:efbd/core/widgets/web_safe_image.dart';
import 'package:efbd/core/widgets/full_screen_image_viewer.dart';
import '../../../core/models/community_config.dart';

enum AdminView { dashboard, tournaments, matches, players, profileRequests, community }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminView _currentView = AdminView.dashboard;
  String _selectedTournamentId = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'eFootballers Bangladesh Admin Panel',
          style: GoogleFonts.rajdhani(
            letterSpacing: 1.5,
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = GoRouter.of(context);
                await context.read<AuthProvider>().signOut();
                if (mounted) navigator.go('/');
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          // Sidebar
          if (!isMobile)
            Container(
              width: 250,
              color: AppTheme.cardBackground,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSidebarItem(Icons.dashboard, 'Dashboard', _currentView == AdminView.dashboard,
                      () => setState(() => _currentView = AdminView.dashboard)),
                  _buildSidebarItem(Icons.emoji_events, 'Tournaments', _currentView == AdminView.tournaments,
                      () => setState(() => _currentView = AdminView.tournaments)),
                  _buildSidebarItem(Icons.sports_esports, 'Matches', _currentView == AdminView.matches,
                      () => setState(() => _currentView = AdminView.matches)),
                  _buildSidebarItem(Icons.people, 'Players', _currentView == AdminView.players,
                      () => setState(() => _currentView = AdminView.players)),
                  _buildSidebarItem(Icons.archive, 'Season Control', _currentView == AdminView.dashboard,
                      () => _showSeasonControlDialog(context)),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService().getProfileUpdateRequests(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _buildSidebarItem(
                        Icons.notification_important, 
                        'Profile Updates', 
                        _currentView == AdminView.profileRequests,
                        () => setState(() => _currentView = AdminView.profileRequests),
                        badgeCount: count > 0 ? count : null,
                      );
                    }
                  ),
                  _buildSidebarItem(
                    Icons.public, 
                    'Community Links', 
                    _currentView == AdminView.community,
                    () => setState(() => _currentView = AdminView.community),
                  ),
                  const Spacer(),
                  _buildSidebarItem(Icons.logout, 'Logout', false, () async {
                    final navigator = GoRouter.of(context);
                    await context.read<AuthProvider>().signOut();
                    if (mounted) navigator.go('/');
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.darkBackground,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.cardBackground),
            child: Center(
              child: Text(
                'ADMIN PANEL',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.primaryGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          _buildSidebarItem(Icons.dashboard, 'Dashboard', _currentView == AdminView.dashboard,
              () {
                setState(() => _currentView = AdminView.dashboard);
                Navigator.pop(context);
              }),
          _buildSidebarItem(Icons.emoji_events, 'Tournaments', _currentView == AdminView.tournaments,
              () {
                setState(() => _currentView = AdminView.tournaments);
                Navigator.pop(context);
              }),
          _buildSidebarItem(Icons.sports_esports, 'Matches', _currentView == AdminView.matches,
              () {
                setState(() => _currentView = AdminView.matches);
                Navigator.pop(context);
              }),
          _buildSidebarItem(Icons.people, 'Players', _currentView == AdminView.players,
              () {
                setState(() => _currentView = AdminView.players);
                Navigator.pop(context);
              }),
          _buildSidebarItem(Icons.archive, 'Season Control', false,
              () {
                Navigator.pop(context);
                _showSeasonControlDialog(context);
              }),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: DatabaseService().getProfileUpdateRequests(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildSidebarItem(
                Icons.notification_important, 
                'Profile Updates', 
                _currentView == AdminView.profileRequests,
                () {
                  setState(() => _currentView = AdminView.profileRequests);
                  Navigator.pop(context);
                },
                badgeCount: count > 0 ? count : null,
              );
            }
          ),
          _buildSidebarItem(
            Icons.public, 
            'Community Links', 
            _currentView == AdminView.community,
            () {
              setState(() => _currentView = AdminView.community);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentView) {
      case AdminView.dashboard:
        return _buildDashboard();
      case AdminView.tournaments:
        return _buildTournamentsView();
      case AdminView.matches:
        return _buildMatchDashboard();
      case AdminView.players:
        return _buildPlayersView();
      case AdminView.profileRequests:
        return const AdminProfileRequestsView();
      case AdminView.community:
        return _buildCommunitySettings();
    }
  }

  Widget _buildTournamentsView() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOURNAMENT MANAGEMENT',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTournament(context),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'NEW TOURNAMENT',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOURNAMENT MANAGEMENT',
                    style: GoogleFonts.rajdhani(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTournament(context),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'NEW TOURNAMENT',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 32),
          StreamBuilder<List<Tournament>>(
            stream: DatabaseService().getTournaments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tournaments = snapshot.data ?? [];
              return Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: tournaments.map((t) => _buildAdminTournamentCard(t)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTournamentCard(Tournament t) {
    return StreamBuilder<List<Registration>>(
      stream: DatabaseService().getRegistrations(t.id),
      builder: (context, snapshot) {
        final regs = snapshot.data ?? [];
        final pendingCount = regs.where((r) => r.status == RegistrationStatus.pending).length;
        
        Color statusColor = AppTheme.primaryGold;
        if (t.status == TournamentStatus.ongoing) statusColor = AppTheme.accentBlue;
        if (t.status == TournamentStatus.completed) statusColor = AppTheme.accentGreen;

        return InkWell(
          onTap: () => context.push('/admin/tournaments/${t.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(t.status.name.toUpperCase(),
                          style: GoogleFonts.rajdhani(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$pendingCount PENDING',
                            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(t.title,
                    style: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 8),
                Text('${t.registeredPlayers.length} / ${t.maxPlayers} Players Registered',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryGold),
                    const SizedBox(width: 8),
                    Text('MANAGE TOURNAMENT',
                        style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            color: AppTheme.primaryGold,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> _seedPlayers() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    for (int i = 1; i <= 64; i++) {
      final docRef = db.collection('players').doc('test_player_$i');
      batch.set(docRef, {
        'name': 'Test Player $i',
        'ign': 'TEST_IGN_$i',
        'email': 'test$i@example.com',
        'uid': 'UID_TEST_$i',
        'whatsapp': '017000000$i',
        'role': 'player',
        'totalPoints': 0,
        'matchesPlayed': 0,
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'champions': 0,
        'runnersUp': 0,
        'monthlyPoints': 0,
        'monthlyWins': 0,
        'monthlyDraws': 0,
        'monthlyLosses': 0,
        'monthlyGoalsFor': 0,
        'monthlyGoalsAgainst': 0,
        'monthlyMatchesPlayed': 0,
        'trophies': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentGreen,
            content: Text(
              'SUCCESSFULLY SEEDED 64 TEST PLAYERS!',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'ERROR SEEDING PLAYERS: ${e.toString().toUpperCase()}',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }
  }

  Future<void> _createDemoTournament() async {
    final db = FirebaseFirestore.instance;
    final playersStream = DatabaseService().getPlayersStream();
    final players = await playersStream.first;
    
    // We want at least 64 for a good "Knockout to Groups" test
    int testSize = 64;
    if (players.length < testSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'NEED AT LEAST $testSize PLAYERS IN DB. FOUND ${players.length}.',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
      return;
    }

    final batch = db.batch();
    final tournamentId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final tournamentRef = db.collection('tournaments').doc(tournamentId);

    // 1. Create Tournament (Direct Knockout for start)
    final playerIds = players.take(testSize).map((p) => p.id).toList();
    batch.set(tournamentRef, {
      'title': 'Test Tournament ($testSize Players)',
      'description': 'Test system: Start with Knockout, then move to Groups.',
      'status': 'upcoming',
      'type': 'knockout',
      'startDate': Timestamp.now(),
      'entryFee': 0,
      'isFree': true,
      'maxPlayers': testSize,
      'registeredPlayers': playerIds,
    });

    // 2. Create Verified Registrations
    for (final player in players.take(testSize)) {
      final regRef = db.collection('registrations').doc('${tournamentId}_${player.id}');
      batch.set(regRef, {
        'tournamentId': tournamentId,
        'playerId': player.id,
        'playerName': player.name,
        'playerIgn': player.ign,
        'playerUid': player.uid,
        'playerWhatsapp': player.whatsapp ?? '01700000000',
        'playerEmail': player.email,
        'trxId': 'TEST-TRX-${player.ign}',
        'status': 'verified',
        'timestamp': Timestamp.now(),
      });
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentGreen,
          content: Text(
            'TEST TOURNAMENT CREATED WITH $testSize PLAYERS!',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
      setState(() {
        _selectedTournamentId = tournamentId;
      });
    }
  }

  Future<void> _quickVerifyMatches() async {
    if (_selectedTournamentId.isEmpty) return;
    
    final matchesStream = DatabaseService().getMatches(_selectedTournamentId);
    final matches = await matchesStream.first;
    final db = DatabaseService();
    final random = Random();
    int count = 0;
    
    for (var match in matches) {
      if (!match.isVerified) {
        int score1 = random.nextInt(5);
        int score2 = random.nextInt(5);
        
        // Ensure no draws for testing knockout progression
        while (score1 == score2) {
          score2 = random.nextInt(5);
        }
        
        final updatedMatch = match.copyWith(
          player1Score: score1,
          player2Score: score2,
          isCompleted: true,
          resultSubmittedBy: 'AUTO_TEST',
        );
        await db.verifyMatchResult(updatedMatch);
        count++;
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentGreen,
          content: Text(
            'VERIFIED $count MATCHES WITH RANDOM SCORES!',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  Widget _buildPlayersView() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAYER DIRECTORY',
            style: GoogleFonts.rajdhani(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<Player>>(
            stream: DatabaseService().getPlayersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final players = snapshot.data ?? [];
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.primaryGold.withValues(alpha: 0.05)),
                    columns: [
                      DataColumn(
                          label: Text('REAL NAME',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('IGN',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('EMAIL',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('UID',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('WHATSAPP',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('PTS',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('ACHIEVEMENTS',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                      DataColumn(
                          label: Text('ACTIONS',
                              style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                    ],
                    rows: players.map((p) => DataRow(cells: [
                          DataCell(Text(p.name, style: GoogleFonts.poppins(fontSize: 13))),
                          DataCell(Text(p.ign, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGold))),
                          DataCell(Text(p.email, style: GoogleFonts.poppins(fontSize: 13))),
                          DataCell(Text(p.uid, style: GoogleFonts.poppins(fontSize: 13))),
                          DataCell(Text(p.whatsapp ?? '-', style: GoogleFonts.poppins(fontSize: 13))),
                          DataCell(Text(p.totalPoints.toString(), style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 15))),
                          DataCell(Text('${p.champions}🏆 ${p.runnersUp}🥈', style: GoogleFonts.poppins(fontSize: 13))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () => _showPlayerDetails(context, p),
                                tooltip: 'View Profile',
                              ),
                              IconButton(
                                icon: const Icon(Icons.military_tech, size: 18, color: AppTheme.primaryGold),
                                onPressed: () => _showAwardTrophyDialog(p),
                                tooltip: 'Award Trophy',
                              ),
                            ],
                          )),
                        ])).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ProfileDialog(player: player),
        ),
      ),
    );
  }

  void _showAwardTrophyDialog(Player player) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TrophyTier selectedTier = TrophyTier.gold;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'AWARD TROPHY TO ${player.ign.toUpperCase()}',
            style: GoogleFonts.rajdhani(
              color: AppTheme.primaryGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Trophy Title (e.g. MVP)',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w600, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (e.g. Season 1)',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w600, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrophyTier>(
                value: selectedTier,
                decoration: InputDecoration(
                  labelText: 'Tier',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w600, letterSpacing: 1.1),
                ),
                items: TrophyTier.values.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text(
                      tier.name.toUpperCase(),
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedTier = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final trophy = Trophy(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    tier: selectedTier,
                    earnedAt: DateTime.now(),
                  );
                  await DatabaseService().awardTrophy(player.id, trophy);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'TROPHY AWARDED TO ${player.ign.toUpperCase()}!',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'AWARD',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeasonControlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'SEASON CONTROL',
          style: GoogleFonts.rajdhani(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        content: Text(
          'Closing the current season will archive the top 100 players from the monthly leaderboard to the Season History and reset all monthly stats (points, wins, etc.) for everyone.\n\nThis action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _closeSeasonManually();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'CLOSE SEASON & RESET STATS',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeSeasonManually() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db.collection('players').get();

      if (snapshot.docs.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final now = DateTime.now();
      // Month names
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthName = months[now.month - 1];
      final year = now.year;
      final monthStr = now.month < 10 ? '0${now.month}' : '${now.month}';
      final seasonId = '${year}-$monthStr';

      final playersData = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': data['uid'] ?? '',
          'ign': data['ign'] ?? 'Unknown',
          'points': data['monthlyPoints'] ?? 0,
          'wins': data['monthlyWins'] ?? 0,
          'draws': data['monthlyDraws'] ?? 0,
          'losses': data['monthlyLosses'] ?? 0,
          'gf': data['monthlyGoalsFor'] ?? 0,
          'ga': data['monthlyGoalsAgainst'] ?? 0,
        };
      }).toList();

      playersData.sort((a, b) {
        if ((b['points'] as int) != (a['points'] as int)) return (b['points'] as int).compareTo(a['points'] as int);
        final gdA = (a['gf'] as int) - (a['ga'] as int);
        final gdB = (b['gf'] as int) - (b['ga'] as int);
        if (gdB != gdA) return gdB.compareTo(gdA);
        return (b['gf'] as int).compareTo(a['gf'] as int);
      });

      final topPlayers = playersData.take(100).toList();

      final batch = db.batch();
      
      // Save Archive
      final archiveRef = db.collection('season_history').doc(seasonId);
      batch.set(archiveRef, {
        'seasonId': seasonId,
        'month': monthName,
        'year': year,
        'timestamp': FieldValue.serverTimestamp(),
        'standings': topPlayers,
      });

      // Reset Stats
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'monthlyPoints': 0,
          'monthlyGoalsFor': 0,
          'monthlyGoalsAgainst': 0,
          'monthlyWins': 0,
          'monthlyDraws': 0,
          'monthlyLosses': 0,
          'monthlyMatchesPlayed': 0,
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentGreen,
            content: Text(
              'SEASON CLOSED AND STATS RESET SUCCESSFULLY!',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('ERROR CLOSING SEASON: ${e.toString().toUpperCase()}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        );
      }
    }
  }

  Widget _buildDashboard() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DASHBOARD OVERVIEW',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _seedPlayers(),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: Text('SEED',
                              style: GoogleFonts.rajdhani(
                                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _createDemoTournament(),
                          icon: const Icon(Icons.science, size: 18),
                          label: Text('DEMO',
                              style: GoogleFonts.rajdhani(
                                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: EdgeInsets.zero),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTournament(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('NEW',
                              style: GoogleFonts.rajdhani(
                                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'DASHBOARD OVERVIEW',
                      style: GoogleFonts.rajdhani(
                        fontSize: isMobile ? 24 : 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _seedPlayers(),
                        icon: const Icon(Icons.person_add),
                        label: Text('SEED 64 PLAYERS',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _createDemoTournament(),
                        icon: const Icon(Icons.science),
                        label: Text('DEMO TOURNAMENT',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateTournament(context),
                        icon: const Icon(Icons.add),
                        label: Text('NEW TOURNAMENT',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                ],
              ),
          const SizedBox(height: 32),
          isMobile
            ? Column(
                children: [
                  Row(
                    children: [
                      StreamBuilder<List<Tournament>>(
                        stream: DatabaseService().getTournaments(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.where((t) => t.status == TournamentStatus.ongoing).length ?? 0;
                          return _buildStatCard('Active', '$count', Icons.play_arrow, AppTheme.accentBlue, isMobile: true);
                        },
                      ),
                      const SizedBox(width: 12),
                      StreamBuilder<List<Registration>>(
                        stream: DatabaseService().getAllRegistrations(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.where((r) => r.status == RegistrationStatus.pending).length ?? 0;
                          return _buildStatCard('Pending', '$count', Icons.pending_actions, AppTheme.primaryGold, isMobile: true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseService().getProfileUpdateRequests(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return _buildStatCard('Requests', '$count', Icons.notification_important, Colors.orangeAccent, isMobile: true);
                        },
                      ),
                      const SizedBox(width: 12),
                      StreamBuilder<List<Player>>(
                        stream: DatabaseService().getPlayersStream(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return _buildStatCard('Total Players', '$count', Icons.group, AppTheme.accentGreen, isMobile: true);
                        },
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  StreamBuilder<List<Tournament>>(
                    stream: DatabaseService().getTournaments(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.where((t) => t.status == TournamentStatus.ongoing).length ?? 0;
                      return _buildStatCard('Active Tournaments', '$count', Icons.play_arrow, AppTheme.accentBlue);
                    },
                  ),
                  const SizedBox(width: 24),
                  StreamBuilder<List<Registration>>(
                    stream: DatabaseService().getAllRegistrations(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.where((r) => r.status == RegistrationStatus.pending).length ?? 0;
                      return _buildStatCard('Pending Payments', '$count', Icons.pending_actions, AppTheme.primaryGold);
                    },
                  ),
                  const SizedBox(width: 24),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService().getProfileUpdateRequests(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _buildStatCard('Profile Requests', '$count', Icons.notification_important, Colors.orangeAccent);
                    },
                  ),
                  const SizedBox(width: 24),
                  StreamBuilder<List<Player>>(
                    stream: DatabaseService().getPlayersStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _buildStatCard('Total Players', '$count', Icons.group, AppTheme.accentGreen);
                    },
                  ),
                ],
              ),
          const SizedBox(height: 48),
          _buildTournamentSelector(),
          const SizedBox(height: 24),
          _buildRecentPaymentsTable(),
        ],
      ),
    );
  }

  Widget _buildMatchDashboard() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATCH MANAGEMENT',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_selectedTournamentId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => _quickVerifyMatches(),
                        icon: const Icon(Icons.bolt),
                        label: Text('QUICK VERIFY',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade900,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MATCH MANAGEMENT',
                    style: GoogleFonts.rajdhani(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_selectedTournamentId.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _quickVerifyMatches(),
                      icon: const Icon(Icons.bolt),
                      label: Text('QUICK VERIFY ALL (TEST)',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900),
                    ),
                ],
              ),
          const SizedBox(height: 32),
          _buildTournamentSelector(),
          const SizedBox(height: 24),
          if (_selectedTournamentId.isNotEmpty)
            StreamBuilder<List<TournamentMatch>>(
              stream: DatabaseService().getMatches(_selectedTournamentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matches = snapshot.data ?? [];
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        const Icon(Icons.sports_esports, size: 64, color: AppTheme.textGrey),
                        const SizedBox(height: 16),
                        Text('No matches found for this tournament.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildMatchCard(matches[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(match.player1Ign,
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                  if (match.isCompleted || match.resultSubmittedBy != null)
                    Text(match.player1Score.toString(),
                        style: GoogleFonts.rajdhani(fontSize: 26, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(match.round,
                      style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 14, letterSpacing: 1.1)),
                  Text('VS',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.textGrey, letterSpacing: 1.5)),
                  if (match.resultSubmittedBy != null && !match.isVerified)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('PENDING',
                          style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.player2Ign,
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                  if (match.isCompleted || match.resultSubmittedBy != null)
                    Text(match.player2Score.toString(),
                        style: GoogleFonts.rajdhani(fontSize: 26, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (match.resultSubmittedBy != null && !match.isVerified)
              ElevatedButton(
                onPressed: () => _showVerificationDialog(match),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                child: Text('VERIFY',
                    style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              )
            else if (match.isVerified)
              const Icon(Icons.verified, color: AppTheme.accentGreen)
            else
              const Icon(Icons.hourglass_empty, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog(TournamentMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'VERIFY MATCH RESULT',
          style: GoogleFonts.rajdhani(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Player?>(
              future: match.resultSubmittedBy != null && match.resultSubmittedBy!.length > 20
                  ? DatabaseService().getPlayer(match.resultSubmittedBy!)
                  : Future.value(null),
              builder: (context, snapshot) {
                final displayName = snapshot.data?.ign ?? match.resultSubmittedBy ?? 'Unknown';
                return Text(
                  'Result submitted by: $displayName',
                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                );
              },
            ),
            const SizedBox(height: 16),
            if (match.screenshotUrl != null)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WebSafeImage(
                    imageUrl: match.screenshotUrl!,
                    fit: BoxFit.contain,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: match.screenshotUrl!,
                            title: 'Match Result Proof',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${match.player1Ign} ${match.player1Score} - ${match.player2Score} ${match.player2Ign}',
              style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().verifyMatchResult(match);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'VERIFY & UPDATE STANDINGS',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySettings() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY SETTINGS',
            style: GoogleFonts.rajdhani(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          StreamBuilder<CommunityConfig>(
            stream: DatabaseService().getCommunityConfigStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final config = snapshot.data ?? CommunityConfig(facebookGroup: '', facebookPage: '', whatsappGroup: '');
              
              return _CommunitySettingsForm(config: config);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentSelector() {
    final isMobile = ResponsiveHelper.isMobile(context);
    return StreamBuilder<List<Tournament>>(
      stream: DatabaseService().getTournaments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final tournaments = snapshot.data!;
        if (tournaments.isEmpty) return const SizedBox.shrink();

        if (_selectedTournamentId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTournamentId = tournaments.first.id);
          });
        }

        return SizedBox(
          width: isMobile ? double.infinity : 300,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedTournamentId.isEmpty ? null : _selectedTournamentId,
            decoration: const InputDecoration(labelText: 'Select Tournament'),
            items: tournaments
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedTournamentId = val!),
          ),
        );
      },
    );
  }

  void _showCreateTournament(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const TournamentCreateForm(),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive, VoidCallback onTap, {int? badgeCount}) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: isActive ? AppTheme.primaryGold : AppTheme.textGrey),
          if (badgeCount != null)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.rajdhani(
          color: isActive ? AppTheme.primaryGold : AppTheme.textGrey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
          letterSpacing: 1.5,
        ),
      ),
      onTap: onTap,
      selected: isActive,
      selectedTileColor: AppTheme.primaryGold.withValues(alpha: 0.05),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isMobile = false}) {
    final card = Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: isMobile ? 26 : 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.rajdhani(
              color: AppTheme.textGrey,
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Expanded(child: card);
  }

  Widget _buildRecentPaymentsTable() {
    if (_selectedTournamentId.isEmpty) return const SizedBox.shrink();
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOURNAMENT REGISTRATIONS',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<Registration>>(
          stream: DatabaseService().getRegistrations(_selectedTournamentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final registrations = snapshot.data ?? [];

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: isMobile ? 24 : 56,
                  headingRowColor: WidgetStateProperty.all(AppTheme.primaryGold.withValues(alpha: 0.05)),
                  columns: [
                    DataColumn(
                        label: Text('PLAYER INFO',
                            style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                    DataColumn(
                        label: Text('TRXID',
                            style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                    DataColumn(
                        label: Text('STATUS',
                            style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                    DataColumn(
                        label: Text('ACTIONS',
                            style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.2))),
                  ],
                  rows: registrations.map((reg) {
                    Color statusColor = Colors.white70;
                    if (reg.status == RegistrationStatus.verified) statusColor = AppTheme.accentGreen;
                    if (reg.status == RegistrationStatus.rejected) statusColor = Colors.redAccent;

                    return DataRow(
                      cells: [
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${reg.playerName}\nIGN: ${reg.playerIgn}\nEmail: ${reg.playerEmail}\nUID: ${reg.playerUid}\nWA: ${reg.playerWhatsapp}',
                            style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
                          ),
                        )),
                        DataCell(Text(reg.trxId, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reg.status.name.toUpperCase(),
                            style: GoogleFonts.rajdhani(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        )),
                        DataCell(
                          Row(
                            children: [
                              if (reg.status == RegistrationStatus.pending) ...[
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 22),
                                  onPressed: () => DatabaseService().verifyRegistration(reg),
                                  tooltip: 'Approve & Lock Seat',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                                  onPressed: () => DatabaseService().updateRegistrationStatus(reg.id, RegistrationStatus.rejected),
                                  tooltip: 'Reject',
                                ),
                              ] else
                                const Icon(Icons.done_all, color: Colors.white24, size: 20),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CommunitySettingsForm extends StatefulWidget {
  final CommunityConfig config;
  const _CommunitySettingsForm({required this.config});

  @override
  State<_CommunitySettingsForm> createState() => _CommunitySettingsFormState();
}

class _CommunitySettingsFormState extends State<_CommunitySettingsForm> {
  late TextEditingController _fbGroupController;
  late TextEditingController _fbPageController;
  late TextEditingController _waGroupController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fbGroupController = TextEditingController(text: widget.config.facebookGroup);
    _fbPageController = TextEditingController(text: widget.config.facebookPage);
    _waGroupController = TextEditingController(text: widget.config.whatsappGroup);
  }

  @override
  void dispose() {
    _fbGroupController.dispose();
    _fbPageController.dispose();
    _waGroupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final newConfig = CommunityConfig(
        facebookGroup: _fbGroupController.text.trim(),
        facebookPage: _fbPageController.text.trim(),
        whatsappGroup: _waGroupController.text.trim(),
      );
      await DatabaseService().updateCommunityConfig(newConfig);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('COMMUNITY LINKS UPDATED!', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR UPDATING LINKS: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('FACEBOOK COMMUNITY GROUP', _fbGroupController, Icons.groups),
          const SizedBox(height: 20),
          _buildField('FACEBOOK PAGE', _fbPageController, Icons.facebook),
          const SizedBox(height: 20),
          _buildField('WHATSAPP COMMUNITY GROUP', _waGroupController, Icons.chat),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('SAVE CHANGES', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(icon, size: 20, color: AppTheme.textGrey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text),
    );
  }
}
