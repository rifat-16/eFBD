import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/web_safe_image.dart';

class SeasonHistoryScreen extends StatelessWidget {
  const SeasonHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SEASON ARCHIVE',
          style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('season_history')
            .orderBy('seasonId', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'No archived seasons yet.',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildSeasonCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildSeasonCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          '${data['month']} ${data['year']}',
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          'Top players of the month',
          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
        ),
        iconColor: AppTheme.primaryGold,
        collapsedIconColor: AppTheme.textGrey,
        children: [
          _buildStandingsList(data['standings'] as List<dynamic>? ?? []),
        ],
      ),
    );
  }

  Widget _buildStandingsList(List<dynamic> standings) {
    if (standings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No data recorded for this season.',
          style: GoogleFonts.poppins(color: AppTheme.textGrey),
        ),
      );
    }

    return Column(
      children: [
        const Divider(color: Colors.white10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: standings.length,
          itemBuilder: (context, index) {
            final player = standings[index] as Map<String, dynamic>;
            final rank = index + 1;
            final rankColor = rank == 1 ? AppTheme.primaryGold : (rank == 2 ? Colors.white70 : (rank == 3 ? const Color(0xFFCD7F32) : AppTheme.textGrey));

            return ListTile(
              dense: true,
              leading: SizedBox(
                width: 40,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.rajdhani(
                    color: rankColor,
                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                player['ign'] ?? 'Unknown',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              trailing: Text(
                '${player['points']} PTS',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
