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
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/web_safe_image.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/storage_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/responsive_helper.dart';
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
    final isMobile = ResponsiveHelper.isMobile(context);
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
          if (tournament.prizes.isNotEmpty) ...[
            Text('PRIZE POOL', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: tournament.prizes.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
                        Text(entry.value, style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
          if (tournament.rules.isNotEmpty) ...[
            Text('TOURNAMENT RULES', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...tournament.rules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(Icons.circle, size: 6, color: AppTheme.primaryGold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(rule, style: GoogleFonts.poppins(color: Colors.white70, height: 1.5, fontSize: 14)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMyMatchSection(Tournament tournament) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.user == null) {
      return const Center(child: Text('Please login to see your match.', style: TextStyle(color: AppTheme.textGrey)));
    }

    return StreamBuilder<TournamentMatch?>(
      stream: DatabaseService().getMyMatchByTournament(tournament.id, authProvider.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final match = snapshot.data;

        if (match == null) {
          return const Center(
            child: Text('No matches assigned to you yet.', style: TextStyle(color: AppTheme.textGrey)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(match.round.toUpperCase(), style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    if (match.deadline != null && !match.isCompleted) ...[
                      const SizedBox(height: 8),
                      Text(
                        'DEADLINE: ${match.deadline!.day}/${match.deadline!.month} ${match.deadline!.hour.toString().padLeft(2, '0')}:${match.deadline!.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.rajdhani(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (match.player2Id == 'BYE') ...[
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryGold, size: 48),
                      const SizedBox(height: 16),
                      Text('YOU GOT A BYE!', style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentGreen, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('You have automatically advanced to the next round.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14)),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMatchPlayer(match.player1Ign, match.player1Id, true),
                          Text(
                            match.isCompleted ? '${match.player1Score} - ${match.player2Score}' : 'VS',
                            style: GoogleFonts.rajdhani(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          _buildMatchPlayer(match.player2Ign, match.player2Id, false),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (!match.isCompleted && match.resultSubmittedBy == null)
                        ElevatedButton.icon(
                          onPressed: () => _showSubmitScoreDialog(match),
                          icon: const Icon(Icons.upload_file),
                          label: Text('SUBMIT RESULT', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        )
                      else if (match.resultSubmittedBy != null && !match.isVerified)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'RESULT PENDING VERIFICATION',
                            style: GoogleFonts.rajdhani(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else if (match.isVerified)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified, color: AppTheme.accentGreen),
                            const SizedBox(width: 8),
                            Text(
                              'MATCH COMPLETED',
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchPlayer(String ign, String? playerId, bool isLeft) {
    return Column(
      children: [
        if (playerId != null && playerId != 'BYE')
          StreamBuilder<Player?>(
            stream: DatabaseService().getPlayerStream(playerId),
            builder: (context, snapshot) {
              final player = snapshot.data;
              return Container(
                width: 60,
                height: 60,
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
                      : const Icon(Icons.person, size: 30, color: AppTheme.textGrey),
                ),
              );
            },
          )
        else
          const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
        const SizedBox(height: 12),
        Text(ign, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tournament?>(
      stream: DatabaseService().getTournamentStream(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: CircularProgressIndicator()));
        final tournament = snapshot.data;
        if (tournament == null) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: Text('Tournament not found', style: TextStyle(color: Colors.white))));

        final tabCount = _getTabCount(tournament);

        List<Widget> tabs = [];
        List<Widget> tabViews = [];

        if (tournament.status == TournamentStatus.upcoming) {
          tabs = const [
            Tab(text: 'INFO'),
            Tab(text: 'PLAYERS'),
            Tab(text: 'MY MATCH'),
          ];
          tabViews = [
            _buildInfoTab(tournament),
            _PlayersListTab(tournamentId: tournament.id),
            _buildMyMatchSection(tournament),
          ];
        } else {
          tabs = [
            const Tab(text: 'INFO'),
            const Tab(text: 'MY MATCH'),
            const Tab(text: 'PLAYERS'),
            if (tournament.type == TournamentType.groupAndKnockout) const Tab(text: 'GROUP STAGE'),
            const Tab(text: 'KNOCKOUT'),
            if (tournament.status == TournamentStatus.completed) const Tab(text: 'MATCH HISTORY'),
            const Tab(text: 'TOP PLAYERS'),
            const Tab(text: 'GOLDEN BOOT'),
          ];
          tabViews = [
            _buildInfoTab(tournament),
            _buildMyMatchSection(tournament),
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
                TabBar(
                  indicatorColor: AppTheme.primaryGold,
                  labelColor: AppTheme.primaryGold,
                  unselectedLabelColor: AppTheme.textGrey,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: tabs,
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
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.title.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        fontSize: isMobile ? 24 : 36, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              ),
              if (!isMobile) _buildActionButtons(tournament),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
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
          stream: DatabaseService().getRegistrations(tournament.id),
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
                        DefaultTabController.of(context).animateTo(0);
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
          child: Column(
            children: groups.map((g) => GroupStandingsTable(group: g)).toList(),
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

  Widget _buildMatchHistory(Tournament tournament) {
    return _MatchHistoryTab(tournamentId: tournament.id);
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
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory && provider.matchHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }

        final matches = provider.matchHistory;

        if (matches.isEmpty) {
          return const Center(
            child: Text('No completed matches yet.', style: TextStyle(color: AppTheme.textGrey)),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          itemCount: matches.length + (provider.hasMoreHistory ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == matches.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final match = matches[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(match.round.toUpperCase(),
                          style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Text(
                        match.timestamp.toString().split(' ')[0],
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.player1Ign,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${match.player1Score} - ${match.player2Score}',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 18, letterSpacing: 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          match.player2Ign,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayersList(Tournament tournament) {
    return _PlayersListTab(tournamentId: tournament.id);
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
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRegs && provider.registrations.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }

        final regs = provider.registrations;

        if (regs.isEmpty) {
          return const Center(
            child: Text('No verified players yet.', style: TextStyle(color: AppTheme.textGrey)),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          itemCount: regs.length + (provider.hasMoreRegs ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == regs.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final reg = regs[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${index + 1}', 
                        style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: ClipOval(
                      child: reg.playerProfileImageUrl != null
                          ? WebSafeImage(
                              imageUrl: reg.playerProfileImageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.person, size: 20, color: AppTheme.textGrey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reg.playerIgn, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                        Text(reg.playerName, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified, color: AppTheme.accentGreen, size: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
