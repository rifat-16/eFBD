import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTechStack extends StatelessWidget {
  const AdminTechStack({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        return Column(
          children: [
            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildSimpleFeatureCard(
                    'অ্যাডমিন কন্ট্রোল সেন্টার',
                    [
                      'টুর্নামেন্ট ম্যানেজার: টুর্নামেন্ট ক্রিয়েশন, ব্র্যাকেট অটোমেশন ও ডেডলাইন কন্ট্রোল।',
                      'পেমেন্ট ভেরিফাইয়ার: বিকাশ/নগদ TrxID কপি, এক ক্লিকে Approve/Reject অ্যাকশন।',
                      'ডিসপিউট জাজ: উভয় প্লেয়ারের স্ক্রিনশট মিলিয়ে ৩-০ ওয়াকওভার জয় ঘোষণা।',
                    ],
                  ),
                ),
                if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildSimpleFeatureCard(
                    'টেকনিক্যাল স্ট্যাক (Flutter & Firebase)',
                    [
                      'ফ্রন্টএন্ড: Flutter Web (ভবিষ্যতে অ্যান্ড্রয়েড/আইওএস কনভার্টেবল)।',
                      'রাউটিং & গার্ড: go_router দিয়ে সিকিউর অ্যাডমিন রাউটিং গার্ড।',
                      'ডেটাবেজ & স্টোরেজ: Firebase Firestore ও Cloud Storage।',
                      'ডিপ-লিংকিং: url_launcher দিয়ে দ্রুত চ্যাট রিডাইরেক্ট।',
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                'গোল্ডেন বুট টাই-ব্রেকার রুল: টুর্নামেন্ট ফাইনাল শেষে ক্লাউড ফাংশন যদি দেখে একাধিক প্লেয়ার সমান গোল করেছে, তবে প্রথম প্রায়োরিটি পাবে কম ম্যাচ খেলে বেশি গোল করা প্লেয়ার (Goals-per-game ratio); দ্বিতীয় প্রায়োরিটি নকআউট পর্বে বেশি গোল দেওয়া প্লেয়ার।',
                style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleFeatureCard(String title, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.rajdhani(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...points.map((point) => Padding(
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
                      child: Text(
                        point,
                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
