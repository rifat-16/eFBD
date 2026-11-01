import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../../../core/providers/tournament_provider.dart';
import '../models/tournament_model.dart';
import '../models/group_model.dart';
import '../models/registration_model.dart';
import '../../profile/models/player_profile_model.dart';
import '../../profile/views/widgets/profile_dialog.dart';
import '../../match_hub/models/match_model.dart';
import '../../match_hub/views/widgets/match_action_card.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/web_safe_image.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/storage_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import 'registration_dialog.dart';

import 'widgets/group_standings_table.dart';
import 'widgets/knockout_bracket_view.dart';
import 'widgets/top_players_tab.dart';
import 'widgets/golden_boot_tab.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  int _getTabCount(Tournament tournament) {
    if (tournament.status == TournamentStatus.upcoming) {
      return 3; // Info, Players, My Match
    }
    int count = (tournament.type == TournamentType.knockout) ? 6 : 7;
    if (tournament.status == TournamentStatus.completed) {
      count++; // Match History
    }
    return count;
  }

  Widget _buildInfoTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.description.isNotEmpty) ...[
            Text('ABOUT TOURNAMENT', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(tournament.description, style: GoogleFonts.poppins(color: Colors.white70, height: 1.6, fontSize: 14)),
            const SizedBox(height: 32),
          ],
          if (tournament.prizes.isNotEmpty) _buildPrizePoolSection(tournament.prizes),
          if (tournament.rules.isNotEmpty) _buildRulesSection(tournament.rules),
        ],
      ),
    );
  }

  Widget _buildRulesSection(List<String> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppTheme.primaryGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'TOURNAMENT RULES',
              style: GoogleFonts.rajdhani(
                color: AppTheme.primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rules.map((rawRule) {
              String rule = rawRule.trim();
              if (rule.isEmpty) return const SizedBox.shrink();

              final isHeader = !rule.startsWith('*') &&
                  !rule.startsWith('-') &&
                  RegExp(r'^[০-৯0-9]+\.\s').hasMatch(rule);

              rule = rule.replaceAll(RegExp(r'^[\*\-\•\–\—]\s*'), '').trim();

              if (isHeader) {
                return Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_rounded, size: 16, color: AppTheme.primaryGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule,
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryGold,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 10),
                      child: Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.accentGreen),
                    ),
                    Expanded(
                      child: Text(
                        rule,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.6,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPrizePoolSection(Map<String, String> prizes) {
    final sortedEntries = _getSortedPrizeEntries(prizes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRIZE POOL',
              style: GoogleFonts.rajdhani(
                color: AppTheme.primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 14, color: AppTheme.primaryGold),
                  const SizedBox(width: 6),
                  Text(
                    '${prizes.length} TIERS',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.15)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.05),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final label = entry.key;
              final amount = entry.value;

              final labelLower = label.toLowerCase().trim();
              IconData icon = Icons.emoji_events;
              Color iconColor = AppTheme.primaryGold;
              Color badgeBg = AppTheme.primaryGold.withValues(alpha: 0.1);

              if (labelLower.contains('champion') || labelLower.contains('1st') || labelLower.contains('first')) {
                icon = Icons.emoji_events;
                iconColor = const Color(0xFFFFD700);
                badgeBg = const Color(0xFFFFD700).withValues(alpha: 0.15);
              } else if (labelLower.contains('runner') || labelLower.contains('2nd') || labelLower.contains('second')) {
                icon = Icons.workspace_premium;
                iconColor = const Color(0xFFC0C0C0);
                badgeBg = const Color(0xFFC0C0C0).withValues(alpha: 0.15);
              } else if (labelLower.contains('3rd') || labelLower.contains('third')) {
                icon = Icons.military_tech;
                iconColor = const Color(0xFFCD7F32);
                badgeBg = const Color(0xFFCD7F32).withValues(alpha: 0.15);
              } else if (labelLower.contains('golden boot') || labelLower.contains('boot')) {
                icon = Icons.sports_soccer;
                iconColor = const Color(0xFFFF9800);
                badgeBg = const Color(0xFFFF9800).withValues(alpha: 0.15);
              } else {
                icon = Icons.stars_rounded;
                iconColor = AppTheme.primaryGold.withValues(alpha: 0.8);
                badgeBg = AppTheme.primaryGold.withValues(alpha: 0.08);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        amount,
                        style: GoogleFonts.rajdhani(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<MapEntry<String, String>> _getSortedPrizeEntries(Map<String, String> prizes) {
    final entries = prizes.entries.toList();

    int getPriority(String label) {
      final l = label.toLowerCase().trim();
      if (l.contains('1st') || l.contains('first') || l.contains('champion')) {
        return 1;
      } else if (l.contains('2nd') || l.contains('second') || l.contains('runner')) {
        return 2;
      } else if (l.contains('3rd') || l.contains('third')) {
        return 3;
      } else if (l.contains('4th') || l.contains('fourth')) {
        return 4;
      } else if (l.contains('5th') || l.contains('fifth')) {
        return 5;
      } else if (l.contains('golden boot') || l.contains('boot')) {
        return 20;
      } else if (l.contains('winner')) {
        return 1;
      }
      final match = RegExp(r'\d+').firstMatch(l);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 99;
      }
      return 100;
    }

    entries.sort((a, b) {
      final pA = getPriority(a.key);
      final pB = getPriority(b.key);
      if (pA != pB) return pA.compareTo(pB);
      return a.key.compareTo(b.key);
    });

    return entries;
  }

  void _showSubmitScoreDialog(TournamentMatch match) {
    final p1Controller = TextEditingController();
    final p2Controller = TextEditingController();
    XFile? selectedImage;
    Uint8List? previewBytes;
    bool isUploading = false;
    final isMobile = ResponsiveHelper.isMobile(context);
    final size = MediaQuery.of(context).size;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: Text('SUBMIT SCORE', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 450, maxHeight: size.height * 0.8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: p1Controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: match.player1Ign, labelStyle: const TextStyle(fontSize: 12)))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('-')),
                        Expanded(child: TextField(controller: p2Controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: match.player2Ign, labelStyle: const TextStyle(fontSize: 12)))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (previewBytes != null)
                      Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(previewBytes!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedImage = image;
                            previewBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.image, color: AppTheme.primaryGold),
                      label: Text(selectedImage == null ? (isMobile ? 'UPLOAD' : 'UPLOAD SCREENSHOT') : (isMobile ? 'CHANGE' : 'CHANGE SCREENSHOT')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGold,
                        side: const BorderSide(color: AppTheme.primaryGold),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                      ),
                    ),
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(color: AppTheme.primaryGold),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.rajdhani(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  final s1 = int.tryParse(p1Controller.text);
                  final s2 = int.tryParse(p2Controller.text);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  if (s1 == null || s2 == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Please enter valid scores')));
                    return;
                  }
                  
                  if (selectedImage == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Screenshot is required')));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  final navigator = Navigator.of(context);

                  try {
                    final authProvider = context.read<AuthProvider>();
                    final updatedMatch = match.copyWith(
                      player1Score: s1,
                      player2Score: s2,
                      resultSubmittedBy: authProvider.user!.uid,
                      screenshotUrl: await StorageService().uploadMatchScreenshot(
                        matchId: match.id,
                        fileBytes: previewBytes!,
                      ),
                    );
                    
                    await DatabaseService().updateMatchResult(updatedMatch);
                    navigator.pop();
                  } catch (e) {
                    setDialogState(() => isUploading = false);
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(
                  'SUBMIT',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  late final Stream<Tournament?> _tournamentStream;
  late final Stream<List<Registration>> _registrationsStream;

  @override
  void initState() {
    super.initState();
    _tournamentStream = DatabaseService().getTournamentStream(widget.tournamentId);
    _registrationsStream = DatabaseService().getRegistrations(widget.tournamentId);
  }

  Tab _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tournament?>(
      stream: _tournamentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: CircularProgressIndicator()));
        }
        final tournament = snapshot.data;
        if (tournament == null) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: Text('Tournament not found', style: TextStyle(color: Colors.white))));

        final tabCount = _getTabCount(tournament);

        List<Widget> tabs = [];
        List<Widget> tabViews = [];

        if (tournament.status == TournamentStatus.upcoming) {
          tabs = [
            _buildTab('INFO', Icons.info_outline_rounded),
            _buildTab('PLAYERS', Icons.groups_rounded),
            _buildTab('MY MATCH', Icons.sports_esports_rounded),
          ];
          tabViews = [
            _buildInfoTab(tournament),
            _PlayersListTab(tournamentId: tournament.id),
            _MyMatchesTab(tournament: tournament),
          ];
        } else {
          tabs = [
            _buildTab('INFO', Icons.info_outline_rounded),
            _buildTab('MY MATCH', Icons.sports_esports_rounded),
            _buildTab('PLAYERS', Icons.groups_rounded),
            if (tournament.type == TournamentType.groupAndKnockout) _buildTab('GROUP STAGE', Icons.grid_view_rounded),
            _buildTab('KNOCKOUT', Icons.account_tree_rounded),
            if (tournament.status == TournamentStatus.completed) _buildTab('MATCH HISTORY', Icons.history_rounded),
            _buildTab('TOP PLAYERS', Icons.leaderboard_rounded),
            _buildTab('GOLDEN BOOT', Icons.sports_soccer_rounded),
          ];
          tabViews = [
            _buildInfoTab(tournament),
            _MyMatchesTab(tournament: tournament),
            _PlayersListTab(tournamentId: tournament.id),
            if (tournament.type == TournamentType.groupAndKnockout) _buildGroupStage(tournament),
            _buildKnockoutBracket(tournament),
            if (tournament.status == TournamentStatus.completed) _MatchHistoryTab(tournamentId: tournament.id),
            TopPlayersTab(tournament: tournament),
            GoldenBootTab(tournament: tournament),
          ];
        }

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Column(
              children: [
                _buildHeader(tournament),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F131C),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.25), width: 1.5),
                    ),
                  ),
                  child: TabBar(
                    indicatorColor: AppTheme.primaryGold,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primaryGold,
                    unselectedLabelColor: AppTheme.textGrey,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: tabs,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabViews,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Tournament tournament) {
    final isMobile = ResponsiveHelper.isMobile(context);

    Color statusColor;
    String statusText;
    if (tournament.status == TournamentStatus.ongoing) {
      statusColor = AppTheme.accentBlue;
      statusText = 'ONGOING CHAMPIONSHIP';
    } else if (tournament.status == TournamentStatus.upcoming) {
      statusColor = AppTheme.primaryGold;
      statusText = 'REGISTRATION OPEN';
    } else {
      statusColor = AppTheme.accentGreen;
      statusText = 'TOURNAMENT COMPLETED';
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF162030),
            const Color(0xFF0B0E14),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.25), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Status & Badge Row
          Row(
            children: [
              PulsingBadge(label: statusText, color: statusColor, fontSize: isMobile ? 10 : 11),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  tournament.isFree ? 'FREE ENTRY' : '${tournament.entryFee} BDT',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textGrey,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.title.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        fontSize: isMobile ? 22 : 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.primaryGold),
                        const SizedBox(width: 6),
                        if (tournament.registrationEndDate != null && tournament.status == TournamentStatus.upcoming)
                          StreamBuilder<DateTime>(
                            stream: Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now()),
                            builder: (context, _) {
                              final now = DateTime.now();
                              final remaining = tournament.registrationEndDate!.difference(now);
                              
                              if (remaining.isNegative) {
                                return Text(
                                  'REGISTRATION CLOSED',
                                  style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                                );
                              }
                              
                              final hours = remaining.inHours;
                              final minutes = remaining.inMinutes % 60;
                              
                              return Text(
                                'ENDS IN: ${hours}h ${minutes}m',
                                style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                              );
                            },
                          )
                        else if (tournament.startDate != null)
                          Text(
                            'STARTS: ${tournament.startDate!.toString().split(' ')[0]}',
                            style: GoogleFonts.poppins(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                _buildActionButtons(tournament),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 14),
            _buildActionButtons(tournament),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Tournament tournament) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isLoggedIn = authProvider.user != null;

        return StreamBuilder<List<Registration>>(
          stream: _registrationsStream,
          builder: (context, snapshot) {
            final regs = snapshot.data ?? [];
            final reg = regs.where((r) => r.playerId == authProvider.user?.uid).firstOrNull;
            final isVerified = reg?.status == RegistrationStatus.verified;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isVerified && tournament.whatsappGroupLink != null)
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(tournament.whatsappGroupLink),
                    icon: Icon(Icons.group, size: isMobile ? 18 : 24, color: Colors.white),
                    label: Text(
                      isMobile ? 'WHATSAPP' : 'JOIN WHATSAPP',
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
                    ),
                  ),
                if (tournament.status == TournamentStatus.upcoming)
                  Builder(builder: (context) {
                    final verifiedCount = regs.where((r) => r.status == RegistrationStatus.verified).length;
                    final isFull = verifiedCount >= tournament.maxPlayers;
                    final isRegClosed = tournament.registrationEndDate != null && 
                                        tournament.registrationEndDate!.isBefore(DateTime.now());

                    String btnText = isRegClosed ? 'CLOSED' : (isFull ? 'FULL' : 'JOIN');
                    if (!isMobile) {
                      btnText = isRegClosed ? 'REGISTRATION CLOSED' : (isFull ? 'SLOTS FULL' : 'JOIN TOURNAMENT');
                    }

                    VoidCallback? onPressed = (isLoggedIn && !isRegClosed && !isFull) ? () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: TournamentRegistrationDialog(tournament: tournament),
                        ),
                      );
                    } : (!isLoggedIn && !isRegClosed && !isFull ? () {
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
                    } : null);
                    
                    Color? btnColor = (isRegClosed || (isFull && reg == null)) ? Colors.white10 : AppTheme.primaryGold;
                    Color textColor = (isRegClosed || (isFull && reg == null)) ? AppTheme.textGrey : Colors.black;

                    if (reg != null) {
                      if (reg.status == RegistrationStatus.pending) {
                        btnText = isMobile ? 'PENDING' : 'PENDING VERIFICATION';
                        onPressed = null;
                        btnColor = Colors.white10;
                        textColor = Colors.white70;
                      } else if (reg.status == RegistrationStatus.verified) {
                        btnText = 'JOINED';
                        onPressed = null;
                        btnColor = AppTheme.accentGreen;
                        textColor = Colors.white;
                      }
                    }

                    return ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: textColor,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
                      ),
                      child: Text(
                        btnText,
                        style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  })
                else
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        final targetIndex = tournament.status == TournamentStatus.upcoming ? 2 : 1;
                        DefaultTabController.of(context).animateTo(targetIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
                      ),
                      child: Text(
                        'MY MATCHES',
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
        );
      },
    );
  }

  Widget _buildGroupStage(Tournament tournament) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return StreamBuilder<List<TournamentGroup>>(
      stream: DatabaseService().getTournamentGroups(tournament.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.group_work, size: 64, color: AppTheme.textGrey),
                const SizedBox(height: 16),
                Text('No groups generated for this tournament.', style: TextStyle(color: AppTheme.textGrey)),
              ],
            ),
          );
        }

        // Sort groups by name (Group A, Group B...)
        groups.sort((a, b) => a.name.compareTo(b.name));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 310,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return GroupStandingsTable(group: groups[index]);
            },
          ),
        );
      },
    );
  }



  Widget _buildKnockoutBracket(Tournament tournament) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
            minWidth: constraints.maxWidth,
          ),
          child: KnockoutBracket(tournamentId: tournament.id),
        );
      },
    );
  }

  Future<void> _launchWhatsApp(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp group link not available yet.')),
      );
      return;
    }
    
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not open WhatsApp link. $e')),
        );
      }
    }
  }
}

class _MyMatchesTab extends StatefulWidget {
  final Tournament tournament;
  const _MyMatchesTab({required this.tournament});

  @override
  State<_MyMatchesTab> createState() => _MyMatchesTabState();
}

class _MyMatchesTabState extends State<_MyMatchesTab> with AutomaticKeepAliveClientMixin {
  Stream<List<TournamentMatch>>? _myMatchesStream;
  String? _userId;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.watch<AuthProvider>();
    final newUserId = authProvider.user?.uid;
    if (newUserId != _userId) {
      _userId = newUserId;
      if (_userId != null) {
        _myMatchesStream = DatabaseService().getMyMatchesByTournament(widget.tournament.id, _userId!);
      } else {
        _myMatchesStream = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_userId == null || _myMatchesStream == null) {
      return const Center(child: Text('Please login to see your matches.', style: TextStyle(color: AppTheme.textGrey)));
    }

    return StreamBuilder<List<TournamentMatch>>(
      stream: _myMatchesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No active matches assigned to you in this tournament yet.', style: TextStyle(color: AppTheme.textGrey)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: matches.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MatchActionCard(
                match: match,
                isLive: !match.isCompleted && match.timestamp.isBefore(DateTime.now()),
              ),
            )).toList(),
          ),
        );
      },
    );
  }
}

class _MatchHistoryTab extends StatefulWidget {
  final String tournamentId;
  const _MatchHistoryTab({required this.tournamentId});

  @override
  State<_MatchHistoryTab> createState() => _MatchHistoryTabState();
}

class _MatchHistoryTabState extends State<_MatchHistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchMatchHistory(
        tournamentId: widget.tournamentId,
        refresh: true,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TournamentProvider>().fetchMatchHistory(
          tournamentId: widget.tournamentId,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory && provider.matchHistory.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryGold)));
        }

        final matches = provider.matchHistory;

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.history_rounded, size: 64, color: AppTheme.textGrey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No completed matches yet in history.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ],
            ),
          );
        }

        final int crossAxisCount = isMobile ? 1 : 2;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 180,
              ),
              itemCount: matches.length + (provider.hasMoreHistory ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == matches.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                    ),
                  );
                }

                final match = matches[index];
                return _buildHistoryMatchCard(context, match, isMobile);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryMatchCard(BuildContext context, TournamentMatch match, bool isMobile) {
    final s1 = match.player1Score ?? 0;
    final s2 = match.player2Score ?? 0;
    final pk1 = match.p1PkScore;
    final pk2 = match.p2PkScore;

    bool p1Winner = s1 > s2;
    bool p2Winner = s2 > s1;
    if (s1 == s2 && pk1 != null && pk2 != null) {
      p1Winner = pk1 > pk2;
      p2Winner = pk2 > pk1;
    }

    final p1Color = p1Winner ? AppTheme.primaryGold : Colors.white;
    final p2Color = p2Winner ? AppTheme.primaryGold : Colors.white;

    return HoverCard(
      borderRadius: BorderRadius.circular(16),
      borderColor: AppTheme.primaryGold.withValues(alpha: 0.3),
      glowColor: AppTheme.primaryGold,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F131C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Ribbon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 16, color: AppTheme.primaryGold),
                      const SizedBox(width: 6),
                      Text(
                        match.round.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.primaryGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 12, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        match.timestamp.toString().split(' ')[0],
                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scoreboard Row
              Row(
                children: [
                  // Player 1
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            match.player1Ign,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : 18,
                              color: p1Color,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildPlayerAvatar(match.player1Id, p1Winner, isMobile),
                      ],
                    ),
                  ),

                  // Score Badge
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182232),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$s1 - $s2',
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                            fontSize: isMobile ? 18 : 22,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (pk1 != null && pk2 != null)
                          Text(
                            '($pk1 - $pk2 PK)',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Player 2
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildPlayerAvatar(match.player2Id, p2Winner, isMobile),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            match.player2Ign,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : 18,
                              color: p2Color,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Match Proof Button
              if (match.screenshotUrl != null && match.screenshotUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: match.screenshotUrl!,
                          title: 'Match Proof (${match.player1Ign} vs ${match.player2Ign})',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.image_search_rounded, size: 14, color: AppTheme.primaryGold),
                    label: Text(
                      'VIEW PROOF',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

  Widget _buildPlayerAvatar(String playerId, bool isWinner, bool isMobile) {
    if (playerId.isEmpty || playerId == 'BYE') {
      return Container(
        width: isMobile ? 28 : 34,
        height: isMobile ? 28 : 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
      );
    }

    return StreamBuilder<Player?>(
      stream: DatabaseService().getPlayerStream(playerId),
      builder: (context, snapshot) {
        final player = snapshot.data;
        return Container(
          width: isMobile ? 28 : 34,
          height: isMobile ? 28 : 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isWinner ? Border.all(color: AppTheme.primaryGold, width: 1.5) : Border.all(color: Colors.white24, width: 1.0),
            boxShadow: [
              if (isWinner)
                BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.3), blurRadius: 8),
            ],
          ),
          child: ClipOval(
            child: (player != null && player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                ? WebSafeImage(
                    imageUrl: player.profileImageUrl!,
                    fit: BoxFit.cover,
                    fallbackWidget: Icon(Icons.person, size: 14, color: isWinner ? AppTheme.primaryGold : AppTheme.textGrey),
                  )
                : Icon(Icons.person, size: 14, color: isWinner ? AppTheme.primaryGold : AppTheme.textGrey),
          ),
        );
      },
    );
  }
}

class _PlayersListTab extends StatefulWidget {
  final String tournamentId;
  const _PlayersListTab({required this.tournamentId});

  @override
  State<_PlayersListTab> createState() => _PlayersListTabState();
}

class _PlayersListTabState extends State<_PlayersListTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchRegistrationsPaginated(
        tournamentId: widget.tournamentId,
        refresh: true,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TournamentProvider>().fetchRegistrationsPaginated(
          tournamentId: widget.tournamentId,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRegs && provider.registrations.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryGold)));
        }

        final regs = provider.registrations;

        if (regs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.groups_rounded, size: 64, color: AppTheme.textGrey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No verified players registered yet.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: 84,
            ),
            itemCount: regs.length + (provider.hasMoreRegs ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == regs.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                  ),
                );
              }

              final reg = regs[index];
              final isTop3 = index < 3;
              final rankColor = index == 0 ? AppTheme.primaryGold : (index == 1 ? const Color(0xFFC0C0C0) : (index == 2 ? const Color(0xFFCD7F32) : AppTheme.primaryGold));

              return HoverCard(
                borderRadius: BorderRadius.circular(14),
                borderColor: isTop3 ? rankColor : AppTheme.primaryGold.withValues(alpha: 0.25),
                glowColor: rankColor,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F131C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isTop3 ? rankColor.withValues(alpha: 0.6) : AppTheme.primaryGold.withValues(alpha: 0.25),
                      width: isTop3 ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Slot Badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isTop3 ? rankColor.withValues(alpha: 0.2) : AppTheme.primaryGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: isTop3 ? Border.all(color: rankColor.withValues(alpha: 0.6)) : null,
                        ),
                        child: Text(
                          '${index + 1}', 
                          style: GoogleFonts.rajdhani(
                            color: isTop3 ? rankColor : AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTop3 ? rankColor : Colors.white24,
                            width: isTop3 ? 1.5 : 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: (reg.playerProfileImageUrl != null && reg.playerProfileImageUrl!.trim().isNotEmpty)
                              ? WebSafeImage(
                                  imageUrl: reg.playerProfileImageUrl!,
                                  fit: BoxFit.cover,
                                  fallbackWidget: Icon(Icons.person, size: 20, color: isTop3 ? rankColor : AppTheme.textGrey),
                                )
                              : Icon(Icons.person, size: 20, color: isTop3 ? rankColor : AppTheme.textGrey),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // IGN & Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reg.playerIgn, 
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16, 
                                color: isTop3 ? rankColor : Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (reg.playerName.isNotEmpty)
                              Text(
                                reg.playerName, 
                                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Verified Icon
                      Icon(
                        Icons.verified_rounded, 
                        color: isTop3 ? rankColor : AppTheme.accentGreen, 
                        size: 20,
                      ),
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
}
