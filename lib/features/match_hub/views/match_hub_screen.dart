import 'package:flutter/material.dart';
import 'widgets/match_hub.dart';
import '../../../core/theme/app_theme.dart';

class MatchHubScreen extends StatelessWidget {
  const MatchHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: const MatchHub(),
          ),
        ),
      ),
    );
  }
}
