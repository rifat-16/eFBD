import '../models/registration_model.dart';
import '../models/tournament_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TournamentRegistrationDialog extends StatefulWidget {
  final Tournament tournament;

  const TournamentRegistrationDialog({super.key, required this.tournament});

  @override
  State<TournamentRegistrationDialog> createState() => _TournamentRegistrationDialogState();
}

class _TournamentRegistrationDialogState extends State<TournamentRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _trxIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _ignController = TextEditingController();
  final _uidController = TextEditingController();
  final _whatsappController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    _trxIdController.dispose();
    _nameController.dispose();
    _ignController.dispose();
    _uidController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tournamentProvider = context.watch<TournamentProvider>();
    final isLoading = tournamentProvider.isLoading;

    // Prefill if player is logged in
    if (authProvider.playerProfile != null) {
      if (_nameController.text.isEmpty) _nameController.text = authProvider.playerProfile!.name;
      if (_ignController.text.isEmpty) _ignController.text = authProvider.playerProfile!.ign;
      if (_uidController.text.isEmpty) _uidController.text = authProvider.playerProfile!.uid;
      _whatsappController.text = authProvider.playerProfile?.whatsapp ?? '';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.isMobile(context) ? MediaQuery.of(context).size.width * 0.9 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOURNAMENT ENTRY',
                style: GoogleFonts.rajdhani(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tournament.title,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const Divider(height: 32, color: Colors.white10),
              
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _nameController,
                readOnly: true,
                enabled: false,
                style: const TextStyle(color: Colors.white60),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ignController,
                readOnly: true,
                enabled: false,
                style: const TextStyle(color: Colors.white60),
                decoration: const InputDecoration(
                  labelText: 'eFootball IGN',
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uidController,
                readOnly: true,
                enabled: false,
                style: const TextStyle(color: Colors.white60),
                decoration: const InputDecoration(
                  labelText: 'eFootball UID',
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                readOnly: true,
                enabled: false,
                style: const TextStyle(color: Colors.white60),
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Number',
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              
              if (!widget.tournament.isFree) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT REQUIRED',
                        style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send ${widget.tournament.entryFee} BDT to 017XXXXXXXX (bKash/Nagad Personal)',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _trxIdController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction ID (TrxID)',
                    hintText: 'e.g. 8N7X2L9P',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required for paid entry';
                    if (val.length < 8) return 'TrxID is too short';
                    // Basic alphanumeric check
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(val.toUpperCase())) {
                      return 'Invalid TrxID format';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('SUBMIT APPLICATION'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'YOUR SEAT WILL BE LOCKED ONCE VERIFIED BY ADMIN.',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textGrey, 
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _errorMessage = null);
      final authProvider = context.read<AuthProvider>();
      final tournamentProvider = context.read<TournamentProvider>();
      final userId = authProvider.user?.uid;

      if (userId == null) {
        setState(() => _errorMessage = 'You must be logged in to register.');
        return;
      }

      // Check if already registered in the tournament model (verified)
      if (widget.tournament.registeredPlayers.contains(userId)) {
        setState(() => _errorMessage = 'You are already a verified participant in this tournament.');
        return;
      }

      try {
        // Check for existing pending registration
        final registrationsStream = DatabaseService().getRegistrations(widget.tournament.id);
        final registrations = await registrationsStream.first;
        final alreadyPending = registrations.any((r) => r.playerId == userId && r.status == RegistrationStatus.pending);
        
        if (alreadyPending) {
          setState(() => _errorMessage = 'You already have a pending registration for this tournament.');
          return;
        }

        final registration = Registration(
          id: '', // Generated by Firestore
          tournamentId: widget.tournament.id,
          playerId: userId,
          playerName: _nameController.text,
          playerIgn: _ignController.text,
          playerUid: _uidController.text,
          playerWhatsapp: _whatsappController.text,
          playerEmail: authProvider.playerProfile?.email ?? (authProvider.user?.email ?? 'N/A'),
          playerProfileImageUrl: authProvider.playerProfile?.profileImageUrl,
          trxId: widget.tournament.isFree ? 'FREE' : _trxIdController.text,
          status: RegistrationStatus.pending,
          timestamp: DateTime.now(),
        );

        await tournamentProvider.registerForTournament(registration);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentGreen,
              content: Text(
                'Registration submitted! Wait for admin verification.',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String userFriendlyError = 'Something went wrong. Please try again.';
          
          if (e.toString().contains('permission-denied')) {
            userFriendlyError = 'You do not have permission to register. Please ensure your profile is complete and you are logged in correctly.';
          } else if (e.toString().contains('network-request-failed')) {
            userFriendlyError = 'Network error. Please check your internet connection.';
          }

          setState(() => _errorMessage = userFriendlyError);
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    }
  }
}
