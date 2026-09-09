import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'group_stage_table.dart';
import 'knockout_bracket_view.dart';
import '../../../match_hub/views/widgets/match_hub.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerHubFeatures extends StatelessWidget {
  const PlayerHubFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MatchHub(),
        const SizedBox(height: 48),
        const GroupStageTable(),
        const SizedBox(height: 48),
        const KnockoutBracket(),
        const SizedBox(height: 48),
        _buildMechanicsGrid(),
      ],
    );
  }

  Widget _buildMechanicsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveHelper.tabletBreakpoint;
        final isMobile = constraints.maxWidth < ResponsiveHelper.mobileBreakpoint;
        int crossAxisCount = isDesktop ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isMobile ? 1.5 : 2.5,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          children: [
            _buildFeatureCard(
              'A. প্রোফাইল ও সোশ্যাল কানেক্টিভিটি',
              [
                'eFootball আইডিডিটি: IGN এবং UID বাধ্যতামূলক।',
                'WhatsApp/Messenger: এক ক্লিকেই অপোনেন্টের সাথে যোগাযোগ।',
                'ড্যাশবোর্ড: লাইফটাইম পয়েন্ট, জয়/পরাজয় ও ট্রফি ডিসপ্লে।',
              ],
            ),
            _buildFeatureCard(
              'B. রেজিস্ট্রেশন ও পেমেন্ট হাব',
              [
                'ফ্রি টুর্নামেন্ট: ইনস্ট্যান্ট জয়েন ও সিট লক।',
                'পেইড টুর্নামেন্ট: বিকাশ ও নগদ ম্যানুয়াল পেমেন্ট ভেরিফিকেশন।',
                'অটো-স্লট লক: ফি জমা দেওয়ার পর স্লট রিজার্ভ রাখা।',
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(String title, List<String> points) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 4, color: AppTheme.primaryGold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
