import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';

class TournamentLifecycle extends StatelessWidget {
  const TournamentLifecycle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLifecycleStep(context, '1', 'Registration Phase', 'Players register with their IGN, UID, and WhatsApp.', Icons.how_to_reg, AppTheme.accentBlue),
        _buildLifecycleStep(context, '2', 'Group Draw & Fixtures', 'Automated group seeding. Players are assigned to groups (A-H).', Icons.groups, AppTheme.primaryGold),
        _buildLifecycleStep(context, '3', 'Group Stage Battles', 'Players play their group matches and submit screenshots.', Icons.sports_esports, AppTheme.accentGreen),
        _buildLifecycleStep(context, '4', 'Knockout Rounds', 'Top players advance to Round of 16, Quarters, Semis, and Finale.', Icons.account_tree, Colors.orangeAccent),
        _buildLifecycleStep(context, '5', 'Hall of Fame', 'Champions and Golden Boot winners are immortalized.', Icons.emoji_events, AppTheme.primaryGold),
      ],
    );
  }

  Widget _buildLifecycleStep(BuildContext context, String step, String title, String desc, IconData icon, Color color) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 28),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'STEP $step:',
                      style: GoogleFonts.rajdhani(
                        color: color,
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textGrey,
                    fontSize: isMobile ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
