import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';

class HallOfFameScreen extends StatelessWidget {
  const HallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 24 : 40,
        ),
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
            const SizedBox(height: 8),
            Text(
              'Celebrating the legends of eFootballers Bangladesh history.',
              style: GoogleFonts.poppins(
                color: AppTheme.textGrey,
                fontSize: AppTheme.responsiveFontSize(context, isMobile ? 14 : 16),
              ),
            ),
            SizedBox(height: isMobile ? 32 : 48),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hall_of_fame')
                  .orderBy('season', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: isMobile ? 1.2 : 0.8,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildTrophyCard(data, context, isMobile);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.military_tech, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'THE CABINET IS CURRENTLY EMPTY',
            style: GoogleFonts.rajdhani(
              color: AppTheme.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Win a tournament to be immortalized here.',
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyCard(Map<String, dynamic> data, BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.primaryGold.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SEASON ${data['season'] ?? '1'}',
            style: GoogleFonts.rajdhani(
              color: AppTheme.primaryGold,
              fontSize: AppTheme.responsiveFontSize(context, 14),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['tournamentName'] ?? 'Tournament',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: AppTheme.responsiveFontSize(context, isMobile ? 18 : 20),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildWinnerRow(context, Icons.emoji_events, AppTheme.primaryGold, 'CHAMPION', data['championName'] ?? 'TBA'),
          const SizedBox(height: 16),
          _buildWinnerRow(context, Icons.military_tech, Colors.blueGrey[300]!, 'RUNNER-UP', data['runnerUpName'] ?? 'TBA'),
          const SizedBox(height: 16),
          _buildWinnerRow(context, Icons.sports_soccer, Colors.orangeAccent, 'GOLDEN BOOT', data['goldenBootName'] ?? 'TBA'),
        ],
      ),
    );
  }

  Widget _buildWinnerRow(BuildContext context, IconData icon, Color color, String title, String name) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppTheme.responsiveFontSize(context, 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.rajdhani(
                color: AppTheme.textGrey,
                fontSize: AppTheme.responsiveFontSize(context, 12),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: AppTheme.responsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
