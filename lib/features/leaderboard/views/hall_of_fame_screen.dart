import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../profile/models/player_profile_model.dart';

class HallOfFameScreen extends StatelessWidget {
  const HallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: StreamBuilder<List<Player>>(
        stream: DatabaseService().getPlayersStream(),
        builder: (context, playersSnapshot) {
          final players = playersSnapshot.data ?? [];
          final avatarMap = <String, String?>{
            for (var p in players) p.ign.trim().toLowerCase(): p.profileImageUrl
          };

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 28,
              vertical: isMobile ? 24 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HALL OF FAME',
                            style: GoogleFonts.rajdhani(
                              fontSize: AppTheme.responsiveFontSize(context, isMobile ? 24 : 32),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                              letterSpacing: isMobile ? 2 : 4,
                            ),
                          ),
                          Text(
                            'Immortalizing the legends & champions of eFootballers Bangladesh.',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textGrey,
                              fontSize: AppTheme.responsiveFontSize(context, isMobile ? 12 : 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 28 : 40),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hall_of_fame')
                      .orderBy('season', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final docs = snapshot.data!.docs;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 28,
                        mainAxisExtent: isMobile ? 420 : 440,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildFancyTrophyCard(data, context, avatarMap, isMobile);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(Icons.military_tech_rounded, size: 70, color: AppTheme.primaryGold.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            'THE HALL OF FAME CABINET IS CURRENTLY EMPTY',
            style: GoogleFonts.rajdhani(
              color: AppTheme.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Win a tournament to be immortalized here among the legends.',
            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFancyTrophyCard(
    Map<String, dynamic> data,
    BuildContext context,
    Map<String, String?> avatarMap,
    bool isMobile,
  ) {
    final championName = data['championName'] ?? 'TBA';
    final runnerUpName = data['runnerUpName'] ?? 'TBA';
    final goldenBootName = data['goldenBootName'] ?? 'TBA';

    final champAvatar = avatarMap[championName.toString().trim().toLowerCase()];
    final runnerAvatar = avatarMap[runnerUpName.toString().trim().toLowerCase()];
    final bootAvatar = avatarMap[goldenBootName.toString().trim().toLowerCase()];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Subtle Glow Accent
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGold.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top Season Ribbon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGold, Color(0xFFD4AF37)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'SEASON ${data['season'] ?? '1'}',
                              style: GoogleFonts.rajdhani(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          'OFFICIAL CHAMPIONSHIP',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.textGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Tournament Title
                  Text(
                    data['tournamentName'] ?? 'Tournament',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- CHAMPION HERO PEDESTAL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF261E0B),
                          Color(0xFF141007),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Champion Badge Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'CHAMPION',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.primaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Champion Avatar / Crown
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryGold, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: (champAvatar != null && champAvatar.trim().isNotEmpty)
                                    ? WebSafeImage(
                                        imageUrl: champAvatar,
                                        fit: BoxFit.cover,
                                        fallbackWidget: const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 30),
                                      )
                                    : const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 30),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Champion IGN Name
                        Text(
                          championName,
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.primaryGold,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- SECONDARY PODIUM (RUNNER-UP & GOLDEN BOOT SIDE BY SIDE) ---
                  Row(
                    children: [
                      // Runner-Up Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF1B2433), Color(0xFF101622)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.military_tech_rounded, color: Colors.blueGrey[200], size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'RUNNER-UP',
                                    style: GoogleFonts.rajdhani(
                                      color: Colors.blueGrey[200],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blueGrey[300]!, width: 1.5),
                                ),
                                child: ClipOval(
                                  child: (runnerAvatar != null && runnerAvatar.trim().isNotEmpty)
                                      ? WebSafeImage(
                                          imageUrl: runnerAvatar,
                                          fit: BoxFit.cover,
                                          fallbackWidget: Icon(Icons.person, color: Colors.blueGrey[200], size: 20),
                                        )
                                      : Icon(Icons.person, color: Colors.blueGrey[200], size: 20),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                runnerUpName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Golden Boot Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2E1C0C), Color(0xFF1A0F06)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sports_soccer_rounded, color: Colors.orangeAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GOLDEN BOOT',
                                    style: GoogleFonts.rajdhani(
                                      color: Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orangeAccent, width: 1.5),
                                ),
                                child: ClipOval(
                                  child: (bootAvatar != null && bootAvatar.trim().isNotEmpty)
                                      ? WebSafeImage(
                                          imageUrl: bootAvatar,
                                          fit: BoxFit.cover,
                                          fallbackWidget: const Icon(Icons.sports_soccer, color: Colors.orangeAccent, size: 20),
                                        )
                                      : const Icon(Icons.sports_soccer, color: Colors.orangeAccent, size: 20),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                goldenBootName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
