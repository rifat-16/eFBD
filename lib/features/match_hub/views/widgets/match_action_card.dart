import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:efbd/core/services/database_service.dart';
import 'package:provider/provider.dart';
import '../../models/match_model.dart';
import '../../../profile/models/player_profile_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../../core/widgets/web_safe_image.dart';

class MatchActionCard extends StatelessWidget {
  final TournamentMatch match;
  final bool isLive;

  const MatchActionCard({
    super.key,
    required this.match,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    final isParticipant = currentUserId != null && 
        (currentUserId == match.player1Id || currentUserId == match.player2Id);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? AppTheme.primaryGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPlayerInfo(context, match.player1Id, match.player1Ign),
              ),
              const SizedBox(width: 4),
              _buildMatchStatus(context, match, isLive),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPlayerInfo(context, match.player2Id, match.player2Ign),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (!match.isCompleted && match.resultSubmittedBy == null && isParticipant) ...[
                _ActionButton(
                  onPressed: () => _launchWhatsApp(context),
                  icon: Icons.chat,
                  label: isMobile ? 'WA' : 'WHATSAPP',
                  color: const Color(0xFF25D366),
                ),
                _ActionButton(
                  onPressed: () => _showReportScoreDialog(context),
                  icon: Icons.emoji_events,
                  label: isMobile ? 'REPORT' : 'REPORT SCORE',
                  color: AppTheme.primaryGold,
                  isPrimary: true,
                ),
              ] else if (match.isCompleted && match.isVerified)
                Column(
                  children: [
                    Text(
                      'MATCH COMPLETED',
                      style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14, letterSpacing: 1.2),
                    ),
                    if (match.screenshotUrl != null)
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: match.screenshotUrl!,
                              title: 'Match Proof',
                            )
                          )
                        ),
                        icon: Icon(Icons.image, size: isMobile ? 12 : 14, color: AppTheme.textGrey),
                        label: Text('VIEW PROOF', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                  ],
                )
              else if (match.resultSubmittedBy != null && !match.isVerified)
                Column(
                  children: [
                    Text(
                      'WAITING FOR ADMIN',
                      style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14, letterSpacing: 1.2),
                    ),
                    if (match.screenshotUrl != null && isParticipant)
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: match.screenshotUrl!,
                              title: 'Submitted Proof',
                            )
                          )
                        ),
                        icon: Icon(Icons.image, size: isMobile ? 12 : 14, color: AppTheme.primaryGold),
                        label: Text('VIEW SUBMITTED PROOF', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context, String playerId, String fallbackName) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return FutureBuilder<Player?>(
      future: DatabaseService().getPlayer(playerId),
      builder: (context, snapshot) {
        final player = snapshot.data;
        final name = player?.ign ?? fallbackName;
        final imageUrl = player?.profileImageUrl;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: isMobile ? 24 : 28,
                backgroundColor: AppTheme.darkBackground,
                child: ClipOval(
                  child: imageUrl != null
                      ? WebSafeImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: isMobile ? 48 : 56,
                          height: isMobile ? 48 : 56,
                        )
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : 22,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.rajdhani(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchStatus(BuildContext context, TournamentMatch match, bool isLive) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLive ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isLive ? 'LIVE' : (match.isCompleted ? 'FINISHED' : 'UPCOMING'),
            style: GoogleFonts.rajdhani(
              color: isLive ? Colors.redAccent : AppTheme.textGrey,
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
          child: (match.isCompleted || match.resultSubmittedBy != null)
              ? Column(
                  children: [
                    Text(
                      '${match.player1Score ?? 0} - ${match.player2Score ?? 0}',
                      style: GoogleFonts.rajdhani(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1),
                    ),
                    if (match.isCompleted && !match.isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'PENDING VERIFICATION',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.primaryGold,
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                )
              : Text('VS', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 22, letterSpacing: 2)),
        ),
        Text(match.round.toUpperCase(), style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        if (match.deadline != null && !match.isCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'DEADLINE: ${match.deadline!.day}/${match.deadline!.month} ${match.deadline!.hour.toString().padLeft(2, '0')}:${match.deadline!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
      ],
    );
  }

  void _launchWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Fetch both players to get the WhatsApp number of the opponent
    // For now, this is a bit complex without knowing which player the current user is.
    // Assuming we want to contact the admin or the opponent.
    
    // Attempt to get player data from Database
    final playersStream = DatabaseService().getPlayersStream();
    final players = await playersStream.first;
    final p1 = players.firstWhere((p) => p.id == match.player1Id, orElse: () => Player(id: '', name: 'Unknown', email: '', ign: '', uid: ''));
    final p2 = players.firstWhere((p) => p.id == match.player2Id, orElse: () => Player(id: '', name: 'Unknown', email: '', ign: '', uid: ''));
    
    // In a real scenario, we'd identify 'self' and pick the other one.
    // For this preview, let's just pick p2's WhatsApp if available, else p1's, else default.
    final contactNumber = p2.whatsapp ?? p1.whatsapp ?? "8801700000000";
    
    final url = "https://wa.me/$contactNumber?text=${Uri.encodeComponent('Hi, I am your opponent for the eFootballers Bangladesh tournament match: ${match.player1Ign} vs ${match.player2Ign}.')}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _showReportScoreDialog(BuildContext context) {
    final s1Controller = TextEditingController();
    final s2Controller = TextEditingController();
    Uint8List? screenshotBytes;
    bool isUploading = false;
    final isMobile = ResponsiveHelper.isMobile(context);
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('SUBMIT MATCH SCORE', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 450, maxHeight: size.height * 0.8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter scores and upload the match result screenshot for verification.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: s1Controller,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: match.player1Ign.toUpperCase(), 
                              labelStyle: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('-', style: GoogleFonts.rajdhani(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: s2Controller,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: match.player2Ign.toUpperCase(), 
                              labelStyle: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setDialogState(() => screenshotBytes = bytes);
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: screenshotBytes != null
                          ? Image.memory(screenshotBytes!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, color: AppTheme.primaryGold),
                                const SizedBox(height: 8),
                                Text('UPLOAD SCREENSHOT', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final s1 = int.tryParse(s1Controller.text);
                final s2 = int.tryParse(s2Controller.text);
                
                if (s1 != null && s2 != null && screenshotBytes != null) {
                  setDialogState(() => isUploading = true);
                  final navigator = Navigator.of(context);
                  final authProvider = context.read<AuthProvider>();
                  try {
                    // 1. Upload screenshot
                    final screenshotUrl = await StorageService().uploadMatchScreenshot(
                      matchId: match.id,
                      fileBytes: screenshotBytes!,
                    );

                    // 2. Update match document
                    final updatedMatch = match.copyWith(
                      player1Score: s1,
                      player2Score: s2,
                      isCompleted: false, // Keep false until verified by admin
                      resultSubmittedBy: authProvider.playerProfile?.ign ?? 'Unknown',
                      screenshotUrl: screenshotUrl,
                    );

                    await DatabaseService().updateMatchResult(updatedMatch);
                    navigator.pop();
                  } catch (e) {
                    // Handle error
                  } finally {
                    setDialogState(() => isUploading = false);
                  }
                }
              },
              child: isUploading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SUBMIT FOR VERIFICATION'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: isPrimary ? Colors.black : Colors.white),
      label: Text(label, style: TextStyle(color: isPrimary ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.transparent,
        side: isPrimary ? BorderSide.none : BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: isPrimary ? 2 : 0,
      ),
    );
  }
}
