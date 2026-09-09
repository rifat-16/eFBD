import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../tournament/models/tournament_model.dart';
import '../../tournament/models/registration_model.dart';
import '../../tournament/models/group_model.dart';
import '../../match_hub/models/match_model.dart';
import '../../profile/models/player_profile_model.dart';
import 'widgets/tournament_create_form.dart';
import '../../tournament/views/widgets/knockout_bracket_view.dart';
import '../../tournament/views/widgets/golden_boot_tab.dart';
import '../../tournament/views/widgets/top_players_tab.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/web_safe_image.dart';

import '../../../core/widgets/full_screen_image_viewer.dart';

class AdminTournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const AdminTournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<AdminTournamentDetailScreen> createState() => _AdminTournamentDetailScreenState();
}

class _AdminTournamentDetailScreenState extends State<AdminTournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditTournamentDialog(Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: TournamentCreateForm(tournament: tournament),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('DELETE TOURNAMENT', style: GoogleFonts.rajdhani(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5)),
        content: Text(
          'Are you sure you want to delete "${tournament.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await DatabaseService().deleteTournament(tournament.id);
              navigator.pop();
              navigator.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('DELETE', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  void _showCompleteTournamentConfirmation(BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('COMPLETE TOURNAMENT', style: GoogleFonts.rajdhani(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5)),
        content: Text(
          'Are you sure you want to complete this tournament? This will calculate winners and add them to the Hall of Fame.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await DatabaseService().completeTournament(tournament);
                navigator.pop();
                messenger.showSnackBar(SnackBar(
                  backgroundColor: AppTheme.accentGreen,
                  content: Text(
                    'TOURNAMENT COMPLETED AND HALL OF FAME UPDATED!',
                    style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                ));
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            child: Text('COMPLETE', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tournament?>(
      stream: DatabaseService().getTournamentStream(widget.tournamentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final tournament = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              tournament.title.toUpperCase(),
              style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            actions: [
              if (tournament.status == TournamentStatus.ongoing)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.accentGreen),
                  onPressed: () => _showCompleteTournamentConfirmation(context, tournament),
                  tooltip: 'Complete Tournament',
                ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: AppTheme.primaryGold),
                onPressed: () => _showEditTournamentDialog(tournament),
                tooltip: 'Edit Tournament',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(context, tournament),
                tooltip: 'Delete Tournament',
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGold,
              labelColor: AppTheme.primaryGold,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
              tabs: const [
                Tab(text: 'REGISTRATIONS'),
                Tab(text: 'MATCHES'),
                Tab(text: 'GROUPS'),
                Tab(text: 'KNOCKOUT'),
                Tab(text: 'TOP PLAYERS'),
                Tab(text: 'GOLDEN BOOT'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              RegistrationsTab(tournament: tournament),
              MatchesTab(tournament: tournament),
              GroupsTab(tournament: tournament),
              KnockoutTab(tournament: tournament),
              TopPlayersTab(tournament: tournament),
              GoldenBootTab(tournament: tournament),
            ],
          ),
        );
      },
    );
  }
}

class RegistrationsTab extends StatefulWidget {
  final Tournament tournament;
  const RegistrationsTab({super.key, required this.tournament});

  @override
  State<RegistrationsTab> createState() => _RegistrationsTabState();
}

class _RegistrationsTabState extends State<RegistrationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Registration>>(
      stream: DatabaseService().getRegistrations(widget.tournament.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final displayRegs = snapshot.data!.where((r) => r.status != RegistrationStatus.rejected).toList();
        if (displayRegs.isEmpty) {
          return Center(
            child: Text(
              'NO ACTIVE REGISTRATIONS.',
              style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: displayRegs.length,
          itemBuilder: (context, index) => _RegistrationItem(reg: displayRegs[index], index: index),
        );
      },
    );
  }
}

class _RegistrationItem extends StatelessWidget {
  final Registration reg;
  final int index;
  const _RegistrationItem({required this.reg, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPending = reg.status == RegistrationStatus.pending;
    final isVerified = reg.status == RegistrationStatus.verified;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? AppTheme.primaryGold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text('${index + 1}.', style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reg.playerName,
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: AppTheme.accentGreen, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'IGN: ${reg.playerIgn} | UID: ${reg.playerUid}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp: ${reg.playerWhatsapp}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  'TrxID: ${reg.trxId}',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          if (isPending)
            Row(
              children: [
                IconButton(
                  onPressed: () => _showRejectDialog(context, reg),
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => DatabaseService().verifyRegistration(reg),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'VERIFY',
                    style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ],
            )
          else if (isVerified)
            _StatusBadge(status: reg.status),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Registration reg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'REJECT REGISTRATION?',
          style: GoogleFonts.rajdhani(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
        ),
        content: Text(
          'Are you sure you want to reject ${reg.playerName}\'s registration?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await DatabaseService().updateRegistrationStatus(reg.id, RegistrationStatus.rejected);
              navigator.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('REJECT', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}

class MatchesTab extends StatefulWidget {
  final Tournament tournament;
  const MatchesTab({super.key, required this.tournament});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.tournament;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                  Text(
                    'MATCH FIXTURES',
                    style: GoogleFonts.rajdhani(fontSize: 22, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
            Row(
              children: [
                if (t.status != TournamentStatus.completed)
                  TextButton.icon(
                    onPressed: () => _quickVerifyAllMatches(t.id),
                    icon: const Icon(Icons.speed, color: AppTheme.accentGreen, size: 18),
                    label: Text(
                      'QUICK VERIFY',
                      style: GoogleFonts.rajdhani(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                const SizedBox(width: 8),
                if (t.status != TournamentStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () => _showGenerationOptions(context),
                    icon: const Icon(Icons.auto_awesome, color: Colors.black),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                    label: Text(
                      'GENERATE',
                      style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<TournamentMatch>>(
          stream: DatabaseService().getMatches(t.id),
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];
            if (matches.isEmpty) return Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Text('No matches generated yet.', style: GoogleFonts.poppins(color: AppTheme.textGrey))));
            
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _MatchCard(match: matches[index], index: index),
            );
          },
        ),
      ],
    );
  }

  void _showQualifyingRoundDialog(BuildContext context) {
    DateTime? selectedDeadline;
    bool isGenerating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'QUALIFYING ROUND',
            style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will generate a single knockout round for all registered players.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Text(
                'MATCH DEADLINE (REQUIRED)',
                style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isGenerating ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryGold,
                              onPrimary: Colors.black,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryGold,
                                onPrimary: Colors.black,
                              ),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  selectedDeadline == null ? 'SELECT DEADLINE' : '${selectedDeadline!.day}/${selectedDeadline!.month} ${selectedDeadline!.hour}:${selectedDeadline!.minute}',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
              ElevatedButton(
                onPressed: isGenerating ? null : () async {
                  if (selectedDeadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PLEASE SELECT A DEADLINE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  setState(() => isGenerating = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await DatabaseService().generateQualifyingRound(widget.tournament.id, deadline: selectedDeadline);
                    navigator.pop();
                    messenger.showSnackBar(SnackBar(
                      backgroundColor: AppTheme.accentGreen,
                      content: Text(
                        'QUALIFYING MATCHES GENERATED!',
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                      ),
                    ));
                  } catch (e) {
                    setState(() => isGenerating = false);
                    messenger.showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                      ),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                child: isGenerating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('GENERATE', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
          ],
        ),
      ),
    );
  }

  void _showGenerateFixturesDialog(Tournament t) async {
    final playerIds = t.registeredPlayers;
    DateTime? selectedDeadline;
    bool isGenerating = false;

    if (playerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'AT LEAST 2 VERIFIED PLAYERS NEEDED TO GENERATE FIXTURES.',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('GENERATE FIXTURES', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generate matches for ${playerIds.length} verified players?', style: GoogleFonts.poppins()),
              const SizedBox(height: 20),
              Text('MATCH DEADLINE (REQUIRED)', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isGenerating ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryGold,
                              onPrimary: Colors.black,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryGold,
                                onPrimary: Colors.black,
                              ),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedDeadline == null ? 'SELECT DEADLINE' : '${selectedDeadline!.day}/${selectedDeadline!.month} ${selectedDeadline!.hour}:${selectedDeadline!.minute}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ElevatedButton(
              onPressed: isGenerating ? null : () async {
                if (selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PLEASE SELECT A DEADLINE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                
                setState(() => isGenerating = true);
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  List<String> shuffled = List.from(playerIds)..shuffle();
                  final playersStream = DatabaseService().getPlayersStream();
                  final players = await playersStream.first;

                  int count = shuffled.length;
                  int targetSize = 2;
                  while (targetSize < count) {
                    targetSize *= 2;
                  }

                  String roundName = DatabaseService.getRoundName(targetSize);

                  List<TournamentMatch> matches = [];
                  int matchCount = targetSize ~/ 2;

                  for (int i = 0; i < matchCount; i++) {
                    final p1Idx = i * 2;
                    final p2Idx = i * 2 + 1;

                    String p1Id = p1Idx < shuffled.length ? shuffled[p1Idx] : 'BYE';
                    String p2Id = p2Idx < shuffled.length ? shuffled[p2Idx] : 'BYE';

                    if (p1Id == 'BYE' && p2Id == 'BYE') continue;

                    final p1 = p1Id != 'BYE'
                        ? players.firstWhere((p) => p.id == p1Id)
                        : null;
                    final p2 = p2Id != 'BYE'
                        ? players.firstWhere((p) => p.id == p2Id)
                        : null;

                    matches.add(TournamentMatch(
                      id: '',
                      tournamentId: t.id,
                      player1Id: p1Id,
                      player2Id: p2Id,
                      player1Ign: p1?.ign ?? 'BYE',
                      player2Ign: p2?.ign ?? 'BYE',
                      timestamp: DateTime.now(),
                      deadline: selectedDeadline,
                      round: roundName,
                      bracketIndex: i,
                      isCompleted: p2Id == 'BYE' || p1Id == 'BYE',
                      isVerified: p2Id == 'BYE' || p1Id == 'BYE',
                      player1Score: p2Id == 'BYE' ? 1 : (p1Id == 'BYE' ? 0 : null),
                      player2Score: p1Id == 'BYE' ? 1 : (p2Id == 'BYE' ? 0 : null),
                    ));
                  }

                  await DatabaseService().createMatches(matches);

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.accentGreen,
                      content: Text(
                        'FIXTURES GENERATED SUCCESSFULLY!',
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                      ),
                    ),
                  );
                } catch (e) {
                  setState(() => isGenerating = false);
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: isGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('GENERATE', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickVerifyAllMatches(String tournamentId) async {
    final messenger = ScaffoldMessenger.of(context);
    final matchesStream = DatabaseService().getMatches(tournamentId);
    final matches = await matchesStream.first;
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
        await DatabaseService().verifyMatchResult(updatedMatch);
        count++;
      }
    }
    
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentGreen,
          content: Text(
            'VERIFIED $count MATCHES WITH RANDOM SCORES!',
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
        ),
      );
    }
  }

  void _showMatchVerificationDialog(TournamentMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'VERIFY MATCH RESULT',
          style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
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
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(imageUrl: match.screenshotUrl!)
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${match.player1Ign} ${match.player1Score} - ${match.player2Score} ${match.player2Ign}',
              style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await DatabaseService().verifyMatchResult(match);
              navigator.pop();
            },
            child: Text('VERIFY', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  void _showGenerationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CHOOSE STRUCTURE', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.bolt, color: AppTheme.primaryGold),
              title: Text('Qualifying Round (Knockout)'.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              subtitle: Text('Single round to filter players', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showQualifyingRoundDialog(context);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.grid_view, color: AppTheme.primaryGold),
              title: Text('Group Stage + Knockout'.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              subtitle: Text('Top 2 from each group advance', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showGroupCountDialog(context);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.account_tree, color: AppTheme.primaryGold),
              title: Text('Direct Knockout'.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              subtitle: Text('Random pairing from all players', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showGenerateFixturesDialog(widget.tournament);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.groups_outlined, color: AppTheme.accentGreen),
              title: Text('Groups from Winners'.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              subtitle: Text('Create groups from previous round winners', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showGroupsFromWinnersDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupsFromWinnersDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final matchesStream = DatabaseService().getMatches(widget.tournament.id);
    final matches = await matchesStream.first;
    final rounds = matches.map((m) => m.round).toSet().toList();
    
    if (rounds.isEmpty) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          'NO MATCHES FOUND TO PICK WINNERS FROM.',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
      ));
      return;
    }

    String selectedRound = rounds.contains('Round of 64') ? 'Round of 64' : rounds.first;
    int playersPerGroup = 4;
    DateTime? selectedDeadline;
    bool isGenerating = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('GROUPS FROM WINNERS', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SELECT SOURCE ROUND:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              DropdownButton<String>(
                value: selectedRound,
                isExpanded: true,
                dropdownColor: AppTheme.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: rounds.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase(), style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)))).toList(),
                onChanged: isGenerating ? null : (val) => setState(() => selectedRound = val!),
              ),
              const SizedBox(height: 20),
              const Text('PLAYERS PER GROUP:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: isGenerating ? null : () => setState(() => playersPerGroup = (playersPerGroup > 2) ? playersPerGroup - 1 : 2)),
                  Text('$playersPerGroup', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: isGenerating ? null : () => setState(() => playersPerGroup++)),
                ],
              ),
              const SizedBox(height: 20),
              Text('MATCH DEADLINE (REQUIRED)', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isGenerating ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryGold,
                              onPrimary: Colors.black,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryGold,
                                onPrimary: Colors.black,
                              ),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedDeadline == null ? 'SELECT DEADLINE' : '${selectedDeadline!.day}/${selectedDeadline!.month} ${selectedDeadline!.hour}:${selectedDeadline!.minute}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ElevatedButton(
              onPressed: isGenerating ? null : () async {
                if (selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PLEASE SELECT A DEADLINE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                setState(() => isGenerating = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                try {
                  final winners = await DatabaseService().getKnockoutWinnersFromRound(widget.tournament.id, selectedRound);
                  
                  if (winners.isEmpty) {
                    throw Exception('No verified winners found in $selectedRound.');
                  }

                  await DatabaseService().generateGroups(
                    widget.tournament.id, 
                    playersPerGroup,
                    customPlayerIds: winners,
                    deadline: selectedDeadline,
                  );
                  
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: AppTheme.accentGreen,
                    content: Text(
                      'GENERATED GROUPS FOR ${winners.length} WINNERS!',
                      style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                } catch (e) {
                  setState(() => isGenerating = false);
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: isGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('GENERATE', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupCountDialog(BuildContext context) {
    int playersPerGroup = 4;
    DateTime? selectedDeadline;
    bool isGenerating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('GROUP SETTINGS', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAYERS PER GROUP:', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: isGenerating ? null : () => setState(() => playersPerGroup = (playersPerGroup > 2) ? playersPerGroup - 1 : 2)),
                  Text('$playersPerGroup', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: isGenerating ? null : () => setState(() => playersPerGroup++)),
                ],
              ),
              const SizedBox(height: 20),
              Text('MATCH DEADLINE (REQUIRED)', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isGenerating ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryGold,
                              onPrimary: Colors.black,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryGold,
                                onPrimary: Colors.black,
                              ),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedDeadline == null ? 'SELECT DEADLINE' : '${selectedDeadline!.day}/${selectedDeadline!.month} ${selectedDeadline!.hour}:${selectedDeadline!.minute}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ElevatedButton(
              onPressed: isGenerating ? null : () async {
                if (selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PLEASE SELECT A DEADLINE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                setState(() => isGenerating = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await DatabaseService().generateGroups(widget.tournament.id, playersPerGroup, deadline: selectedDeadline);
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: AppTheme.accentGreen,
                    content: Text(
                      'GROUPS AND MATCHES GENERATED!',
                      style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                } catch (e) {
                  setState(() => isGenerating = false);
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: isGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('GENERATE', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  // Removed duplicate helper functions that were causing issues
}

class _MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final int index;
  const _MatchCard({required this.match, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text('${index + 1}.', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                match.player1Ign,
                textAlign: TextAlign.end,
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  match.round.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.primaryGold.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (match.deadline != null && !match.isCompleted)
                  Text(
                    'DL: ${match.deadline!.day}/${match.deadline!.month} ${match.deadline!.hour}:${match.deadline!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                Text(
                  match.isCompleted ? '${match.player1Score} - ${match.player2Score}' : 'VS',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, 
                    color: AppTheme.primaryGold,
                    fontSize: 18,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              match.player2Ign,
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (match.resultSubmittedBy != null && !match.isVerified)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ElevatedButton(
                onPressed: () => _showMatchVerificationDialog(context, match),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('VERIFY', style: TextStyle(color: Colors.black, fontSize: 10)),
              ),
            )
          else if (match.isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.verified, color: AppTheme.accentGreen, size: 20),
            )
        ],
      ),
    );
  }

  void _showMatchVerificationDialog(BuildContext context, TournamentMatch match) {
     _MatchesTabState parent = context.findAncestorStateOfType<_MatchesTabState>()!;
     parent._showMatchVerificationDialog(match);
  }
}

class GroupsTab extends StatefulWidget {
  final Tournament tournament;
  const GroupsTab({super.key, required this.tournament});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<TournamentGroup>>(
      stream: DatabaseService().getTournamentGroups(widget.tournament.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'NO GROUPS GENERATED.',
              style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          );
        }
        final groups = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: groups.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'GROUPS & STANDINGS',
                  style: GoogleFonts.rajdhani(fontSize: 22, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              );
            }
            if (index == groups.length + 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () => _showAdvanceConfirmDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    'ADVANCE TOP 2 TO KNOCKOUT',
                    style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
              );
            }
            return _GroupStandingsCard(group: groups[index - 1]);
          },
        );
      },
    );
  }

  void _showAdvanceConfirmDialog(BuildContext context) {
    DateTime? selectedDeadline;
    bool isAdvancing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('ADVANCE PLAYERS', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will take the Top 2 players from each group and generate knockout fixtures.'),
              const SizedBox(height: 20),
              Text('MATCH DEADLINE (REQUIRED)', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isAdvancing ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryGold,
                              onPrimary: Colors.black,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryGold,
                                onPrimary: Colors.black,
                              ),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  selectedDeadline == null ? 'SELECT DEADLINE' : '${selectedDeadline!.day}/${selectedDeadline!.month} ${selectedDeadline!.hour}:${selectedDeadline!.minute}',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAdvancing ? null : () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ElevatedButton(
              onPressed: isAdvancing ? null : () async {
                if (selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('PLEASE SELECT A DEADLINE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  ));
                  return;
                }
                setState(() => isAdvancing = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await DatabaseService().advanceToKnockout(widget.tournament.id, 2, deadline: selectedDeadline);
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: AppTheme.accentGreen,
                    content: Text(
                      'PLAYERS ADVANCED TO KNOCKOUT!',
                      style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                } catch (e) {
                  setState(() => isAdvancing = false);
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'ERROR: ${e.toString().replaceAll('Exception: ', '').toUpperCase()}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                  ));
                }
              },
              child: isAdvancing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('ADVANCE', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupStandingsCard extends StatelessWidget {
  final TournamentGroup group;
  const _GroupStandingsCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name.toUpperCase(), style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreamBuilder<List<Player>>(
              stream: DatabaseService().getPlayersStream(),
              builder: (context, playerSnapshot) {
                final players = playerSnapshot.data ?? [];
                List<String> sortedIds = List.from(group.playerIds);
                sortedIds.sort((a, b) {
                  final statsA = group.playerStats[a] ?? GroupStats();
                  final statsB = group.playerStats[b] ?? GroupStats();
                  if (statsB.points != statsA.points) return statsB.points.compareTo(statsA.points);
                  return statsB.goalDifference.compareTo(statsA.goalDifference);
                });

                return DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 45,
                  columns: [
                    DataColumn(label: Text('POS', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('PLAYER', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('P', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('W', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('D', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('L', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('GD', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                    DataColumn(label: Text('PTS', style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                  ],
                  rows: sortedIds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pid = entry.value;
                    final stats = group.playerStats[pid] ?? GroupStats();
                    final player = players.firstWhere((p) => p.id == pid, orElse: () => Player(id: pid, name: 'Unknown', email: '', ign: 'Player', uid: ''));

                    return DataRow(cells: [
                      DataCell(Text('${index + 1}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text(player.ign, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5))),
                      DataCell(Text('${stats.played}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text('${stats.won}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text('${stats.drawn}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text('${stats.lost}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text('${stats.goalDifference > 0 ? '+' : ''}${stats.goalDifference}', style: GoogleFonts.poppins(fontSize: 13))),
                      DataCell(Text('${stats.points}', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 15))),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KnockoutTab extends StatefulWidget {
  final Tournament tournament;
  const KnockoutTab({super.key, required this.tournament});

  @override
  State<KnockoutTab> createState() => _KnockoutTabState();
}

class _KnockoutTabState extends State<KnockoutTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: KnockoutBracket(tournamentId: widget.tournament.id),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RegistrationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == RegistrationStatus.verified ? AppTheme.accentGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
