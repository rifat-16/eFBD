import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ignController = TextEditingController();
  final _uidController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ignController.dispose();
    _uidController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    
    try {
      final updatedPlayer = authProvider.playerProfile!.copyWith(
        ign: _ignController.text.trim(),
        uid: _uidController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
      );

      await DatabaseService().updatePlayer(updatedPlayer);
      await authProvider.fetchPlayerProfile(authProvider.user!.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.accentGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_circle_outlined, color: AppTheme.primaryGold, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        'COMPLETE PROFILE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'We need a few more details before you can continue to the community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _ignController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'In-Game Name (IGN)',
                          prefixIcon: Icon(Icons.videogame_asset_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'IGN is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _uidController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'eFootball UID',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: '9-digit UID',
                        ),
                        validator: (v) => v == null || v.trim().length < 9 ? 'Valid UID is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _whatsappController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => v == null || v.trim().length < 11 ? 'Valid WhatsApp number is required' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('COMPLETE PROFILE'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.read<AuthProvider>().signOut(),
                        child: const Text('Logout', style: TextStyle(color: AppTheme.textGrey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
