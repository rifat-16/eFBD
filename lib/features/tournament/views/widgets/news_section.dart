import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LATEST UPDATES',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 300,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildNewsCard(
                'Independence Cup 2026 Announced!',
                'Registration starts from August 15. Prize pool 50,000 BDT.',
                'assets/news1.jpg',
                'AUG 10',
              ),
              const SizedBox(width: 20),
              _buildNewsCard(
                'RT6TEEN Wins Monsoon Showdown',
                'A thrilling final against SIAM_ESPORT ends in 3-2 victory.',
                'assets/news2.jpg',
                'JUL 28',
              ),
              const SizedBox(width: 20),
              _buildNewsCard(
                'New Ranking System Live',
                'Point calculation logic updated for Season 2024 Phase 2.',
                'assets/news3.jpg',
                'JUL 15',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(String title, String desc, String img, String date) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveHelper.isMobile(context);
        final cardWidth = isMobile ? MediaQuery.of(context).size.width * 0.8 : 400.0;
        
        return Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage(img),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
