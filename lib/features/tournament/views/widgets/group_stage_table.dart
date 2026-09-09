import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupStageTable extends StatelessWidget {
  const GroupStageTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GROUP STAGE DRAW',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemCount: 4, // Showing 4 groups as an example
              itemBuilder: (context, index) {
                String groupName = String.fromCharCode(65 + index); // A, B, C, D
                return _buildGroupCard(groupName);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupCard(String name) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              'GROUP $name',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
          _buildGroupRow('1', 'RT6TEEN', '9'),
          _buildGroupRow('2', 'SIAM_ESPORT', '6'),
          _buildGroupRow('3', 'NAHID_07', '3'),
          _buildGroupRow('4', 'JOY_EFB', '0'),
        ],
      ),
    );
  }

  Widget _buildGroupRow(String pos, String name, String pts) {
    bool isQualifying = int.parse(pos) <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Text(pos, style: TextStyle(color: isQualifying ? AppTheme.accentGreen : AppTheme.textGrey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
            ),
          ),
          Text(pts, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
