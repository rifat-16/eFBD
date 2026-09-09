import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';
import '../../../../core/widgets/web_safe_image.dart';
import '../../models/player_profile_model.dart';
import '../../models/trophy_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileDialog extends StatefulWidget {
  final Player? player; // If null, it's a new registration

  const ProfileDialog({super.key, this.player});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _updateFormKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _nameController;
  late TextEditingController _ignController;
  late TextEditingController _uidController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  Uint8List? _imageBytes;
  String? _currentPhotoUrl;
  bool _isUploading = false;
  bool _isLogin = true;
  String? _errorMessage;

  void _showUpdateForm() {
    // Create temporary controllers for the update form to avoid modifying the main view's state prematurely
    final nameEditController = TextEditingController(text: _nameController.text);
    final ignEditController = TextEditingController(text: _ignController.text);
    final uidEditController = TextEditingController(text: _uidController.text);
    final whatsappEditController = TextEditingController(text: _whatsappController.text);
    final reasonEditController = TextEditingController();

    bool localLoading = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.isMobile(context) ? MediaQuery.of(context).size.width * 0.9 : 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _updateFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'REQUEST PROFILE UPDATE',
                            style: GoogleFonts.rajdhani(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (!localLoading)
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.textGrey),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ENTER NEW DETAILS. ADMIN WILL VERIFY AND UPDATE YOUR PROFILE.',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.textGrey, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Divider(height: 32),
                      if (localError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            localError!,
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: nameEditController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'NEW REAL NAME', 
                          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ignEditController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'NEW IGN', 
                          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.sports_esports),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.trim().toLowerCase() == 'loading..') return 'Invalid IGN';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: uidEditController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'NEW EFOOTBALL UID', 
                          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: whatsappEditController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'NEW WHATSAPP', 
                          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonEditController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'REASON FOR CHANGE',
                          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                          hintText: 'e.g. Changed my in-game name or phone number',
                          hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please provide a reason' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: localLoading ? null : () async {
                            if (_updateFormKey.currentState!.validate()) {
                              setDialogState(() {
                                localLoading = true;
                                localError = null;
                              });

                              try {
                                final authProvider = this.context.read<AuthProvider>();
                                final userId = authProvider.user?.uid;
                                if (userId == null) throw Exception("Session expired. Please login again.");

                                final requestData = {
                                  'userId': userId,
                                  'currentData': {
                                    'realName': widget.player?.name,
                                    'ign': widget.player?.ign,
                                    'eFootballUid': widget.player?.uid,
                                    'whatsapp': widget.player?.whatsapp,
                                  },
                                  'requestedData': {
                                    'realName': nameEditController.text.trim(),
                                    'ign': ignEditController.text.trim(),
                                    'eFootballUid': uidEditController.text.trim(),
                                    'whatsapp': whatsappEditController.text.trim(),
                                  },
                                  'reason': reasonEditController.text.trim(),
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                };

                                await DatabaseService().submitProfileUpdateRequest(requestData);
                                
                                if (mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppTheme.accentGreen,
                                      content: Text('Update request submitted! Admin will review it and notify you.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  String error = e.toString().replaceFirst('Exception: ', '');
                                  if (error.contains('INTERNAL ASSERTION FAILED')) {
                                    error = 'Database synchronization error. Please refresh the page and try again.';
                                  }
                                  setDialogState(() {
                                    localLoading = false;
                                    localError = error;
                                  });
                                }
                              }
                            }
                          },
                          child: localLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('SUBMIT UPDATE REQUEST'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Clean up temporary controllers
      nameEditController.dispose();
      ignEditController.dispose();
      uidEditController.dispose();
      whatsappEditController.dispose();
      reasonEditController.dispose();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _ignController.dispose();
    _uidController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildDetailedTrophy(Trophy trophy) {
    Color tierColor;
    switch (trophy.tier) {
      case TrophyTier.gold:
        tierColor = AppTheme.primaryGold;
        break;
      case TrophyTier.silver:
        tierColor = Colors.white70;
        break;
      case TrophyTier.bronze:
        tierColor = const Color(0xFFCD7F32);
        break;
      case TrophyTier.special:
        tierColor = Colors.purpleAccent;
        break;
    }

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            color: tierColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            trophy.title,
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            trophy.description,
            style: GoogleFonts.poppins(
              color: AppTheme.textGrey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyStat(String label, int count, String emoji, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: GoogleFonts.rajdhani(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppTheme.textGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    if (widget.player != null) _isLogin = false;
    _nameController = TextEditingController(text: widget.player?.name ?? '');
    _ignController = TextEditingController(text: widget.player?.ign ?? '');
    _uidController = TextEditingController(text: widget.player?.uid ?? '');
    _whatsappController = TextEditingController(text: widget.player?.whatsapp ?? '');
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _currentPhotoUrl = widget.player?.profileImageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });

      // Auto-save if editing an existing profile
      if (widget.player != null) {
        await _autoSaveProfilePicture(bytes);
      }
    }
  }

  Future<void> _autoSaveProfilePicture(Uint8List bytes) async {
    final authProvider = context.read<AuthProvider>();
    setState(() => _isUploading = true);

    try {
      // 1. Upload to Storage
      final photoUrl = await StorageService().uploadPlayerAvatar(
        playerId: widget.player!.id,
        fileBytes: bytes,
      );

      // 2. Update Firestore using copyWith to preserve all other fields
      final updatedPlayer = widget.player!.copyWith(
        profileImageUrl: photoUrl,
      );

      await DatabaseService().updatePlayer(updatedPlayer);
      await authProvider.fetchPlayerProfile(widget.player!.id);

      if (mounted) {
        setState(() => _currentPhotoUrl = photoUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentGreen,
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to auto-save photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading || _isUploading;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  widget.player != null
                      ? 'EDIT PROFILE'
                      : (_isLogin ? 'WELCOME BACK' : 'CREATE PLAYER PROFILE'),
                  style: GoogleFonts.rajdhani(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to access your profile and tournaments.'
                      : 'Join the elite eFootball community of Bangladesh.',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textGrey, 
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                Divider(height: isMobile ? 32 : 48),
              if (widget.player != null)
                StreamBuilder<Map<String, dynamic>?>(
                  stream: DatabaseService().getLatestProfileRequest(widget.player!.id),
                  builder: (context, snapshot) {
                    final latestRequest = snapshot.data;
                    final status = latestRequest?['status'] as String?;
                    final hasPending = status == 'pending';
                    final isRejected = status == 'rejected';
                    
                    if (!hasPending && !isRejected) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      key: ValueKey(latestRequest?['id'] ?? 'pending_banner'),
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (hasPending ? AppTheme.primaryGold : Colors.redAccent).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (hasPending ? AppTheme.primaryGold : Colors.redAccent).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasPending ? Icons.pending_actions : Icons.gpp_bad,
                                color: hasPending ? AppTheme.primaryGold : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                hasPending ? 'UPDATE PENDING' : 'REQUEST REJECTED',
                                style: GoogleFonts.rajdhani(
                                  color: hasPending ? AppTheme.primaryGold : Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasPending 
                              ? 'Your profile update request is being reviewed by an admin. You cannot submit another request until this is processed.'
                              : 'Reason: ${latestRequest?['rejectionReason'] ?? "No reason provided."}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'ERROR OCCURRED',
                            style: GoogleFonts.rajdhani(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (!_isLogin) ...[
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.darkBackground,
                          backgroundImage: _imageBytes != null 
                              ? MemoryImage(_imageBytes!) 
                              : (!kIsWeb && _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty 
                                  ? NetworkImage(_currentPhotoUrl!) as ImageProvider 
                                  : null),
                          child: ClipOval(
                            child: _imageBytes == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 60, color: Colors.white10)
                              : (kIsWeb && _imageBytes == null && _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                  ? WebSafeImage(imageUrl: _currentPhotoUrl!, width: 120, height: 120, fit: BoxFit.cover)
                                  : null),
                          ),
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryGold,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickImage,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _isUploading ? Colors.grey : AppTheme.primaryGold,
                            child: Icon(
                              _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.player != null) ...[
                  const SizedBox(height: 24),
                  // Trophy Showcase Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: AppTheme.primaryGold, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'TROPHY SHOWCASE',
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (widget.player!.trophies.isNotEmpty)
                        Text(
                          '${widget.player!.trophies.length} TOTAL',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.player!.trophies.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                    const Icon(Icons.emoji_events_outlined, color: Colors.white10, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'NO TROPHIES YET',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.2),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.player!.trophies.length,
                        itemBuilder: (context, index) {
                          return _buildDetailedTrophy(widget.player!.trophies[index]);
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Legacy Stats Summary
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTrophyStat('CHAMPIONS', widget.player!.champions, '🏆', AppTheme.primaryGold),
                        _buildTrophyStat('RUNNERS-UP', widget.player!.runnersUp, '🥈', Colors.white70),
                        _buildTrophyStat('GOLDEN BOOT', widget.player!.goldenBoots, '👟', Colors.blueAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isMobile ? 1.2 : 0.85,
                    children: [
                      _buildStatItem('Played', widget.player!.matchesPlayed.toString(), Icons.history, AppTheme.accentBlue),
                      _buildStatItem('Wins', widget.player!.wins.toString(), Icons.trending_up, AppTheme.accentGreen),
                      _buildStatItem('Draws', widget.player!.draws.toString(), Icons.remove, Colors.grey),
                      _buildStatItem('Losses', widget.player!.losses.toString(), Icons.trending_down, Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isMobile ? 1.2 : 0.85,
                    children: [
                      _buildStatItem('Points', widget.player!.totalPoints.toString(), Icons.star, AppTheme.primaryGold),
                      _buildStatItem('GF', widget.player!.goalsFor.toString(), Icons.add_box, AppTheme.accentGreen),
                      _buildStatItem('GA', widget.player!.goalsAgainst.toString(), Icons.indeterminate_check_box, Colors.redAccent),
                      _buildStatItem('GD', widget.player!.goalDifference.toString(), Icons.compare_arrows, AppTheme.accentBlue),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  readOnly: widget.player != null,
                  enabled: widget.player == null,
                  style: GoogleFonts.poppins(color: widget.player != null ? Colors.white60 : Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'REAL NAME',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.person),
                    disabledBorder: widget.player != null ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)) : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ignController,
                  readOnly: widget.player != null,
                  enabled: widget.player == null,
                  style: GoogleFonts.poppins(color: widget.player != null ? Colors.white60 : Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'IN-GAME NAME (IGN)',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.sports_esports),
                    disabledBorder: widget.player != null ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)) : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _uidController,
                  readOnly: widget.player != null,
                  enabled: widget.player == null,
                  style: GoogleFonts.poppins(color: widget.player != null ? Colors.white60 : Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'EFOOTBALL USER ID (UID)',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.badge),
                    disabledBorder: widget.player != null ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)) : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _whatsappController,
                  readOnly: widget.player != null,
                  enabled: widget.player == null,
                  style: GoogleFonts.poppins(color: widget.player != null ? Colors.white60 : Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'WHATSAPP NUMBER',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.phone),
                    disabledBorder: widget.player != null ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)) : null,
                  ),
                ),
              ],
              if (widget.player == null) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'EMAIL ADDRESS',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
              ],
              const SizedBox(height: 40),
              if (widget.player != null) ...[
                StreamBuilder<Map<String, dynamic>?>(
                  stream: DatabaseService().getLatestProfileRequest(widget.player!.id),
                  builder: (context, snapshot) {
                    final latestRequest = snapshot.data;
                    final hasPending = latestRequest != null && latestRequest['status'] == 'pending';
                    final isRejected = latestRequest != null && latestRequest['status'] == 'rejected';
                    
                    return Column(
                      children: [
                        if (hasPending)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'An update request is already pending admin review.',
                                    style: GoogleFonts.poppins(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isRejected)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'LAST REQUEST REJECTED',
                                      style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${latestRequest['rejectionReason'] ?? "No reason provided."}',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (isLoading || hasPending) ? null : _showUpdateForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasPending ? Colors.grey.withValues(alpha: 0.2) : AppTheme.primaryGold,
                            ),
                            child: const Text('REQUEST PROFILE UPDATE'),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _save,
                    child: isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                      : Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
                  ),
                ),
              if (authProvider.isAuthenticated) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldContext = context;
                      await authProvider.signOut();
                      if (navigator.mounted) {
                        navigator.pop();
                        scaffoldContext.go('/');
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    label: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              if (widget.player == null) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: _isLogin
                        ? Text(
                            "DON'T HAVE AN ACCOUNT? REGISTER",
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          )
                        : Text(
                            "ALREADY HAVE AN ACCOUNT? SIGN IN",
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithEmail(email, password);
      
      // Crucial: Wait for the profile to be fetched after login
      await authProvider.fetchPlayerProfile(authProvider.user!.uid);

      if (mounted) {
        if (authProvider.playerProfile == null) {
          // USER LOGGED IN BUT HAS NO PROFILE -> Switch to Registration mode
          setState(() {
            _isLogin = false;
            _errorMessage = 'Login successful! Please complete your profile to continue.';
            // Pre-fill email from auth if available
            if (authProvider.user?.email != null) {
              _emailController.text = authProvider.user!.email!;
            }
          });
          // Scroll to top to show the message
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        } else {
          // SUCCESSFUL LOGIN WITH PROFILE
          Navigator.of(context).pop();
          
          // এডমিন হলে এডমিন প্যানেলে পাঠিয়ে দিবে
          if (mounted) {
            if (authProvider.isAdmin) {
              context.go('/admin');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged in successfully!'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMsg = 'Invalid email or password.';
          break;
        case 'invalid-email':
          errorMsg = 'The email address provided is not valid.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network connection failed. Please check your internet.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMsg = e.message ?? 'An authentication error occurred.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        String error = e.toString();
        if (error.contains('INTERNAL ASSERTION FAILED')) {
          error = 'A temporary database error occurred. Please refresh the page.';
        } else {
          error = 'An unexpected error occurred. Please try again.';
        }
        setState(() {
          _errorMessage = error;
        });
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _save() async {
    if (widget.player == null && _isLogin) {
      _handleLogin();
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final dbService = DatabaseService();
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      try {
        final whatsapp = _whatsappController.text.trim();
        final efootballUid = _uidController.text.trim();
        String? playerId = widget.player?.id;
        String photoUrl = _currentPhotoUrl ?? '';

        // 1. Strict Uniqueness Validation
        // Check WhatsApp uniqueness
        final isMobileUnique = await dbService.isWhatsappUnique(whatsapp, excludePlayerId: playerId);
        if (!isMobileUnique) {
          throw Exception("This WhatsApp number is already in use.");
        }

        // Check eFootball UID uniqueness
        final isUidUnique = await dbService.isUidUnique(efootballUid, excludePlayerId: playerId);
        if (!isUidUnique) {
          throw Exception("This eFootball UID is already registered with another account.");
        }

        // Check Email uniqueness if it's a new registration
        if (widget.player == null && !authProvider.isAuthenticated) {
          final isEmailUnique = await dbService.isEmailUnique(_emailController.text.trim());
          if (!isEmailUnique) {
            throw Exception("An account with this email already exists.");
          }
        }

        // 2. Handle Account Creation or Linking
        if (widget.player == null) {
          // Check if user is already logged in but somehow trying to create a new profile
          if (authProvider.isAuthenticated && authProvider.playerProfile != null) {
            throw Exception("You already have a linked player profile!");
          }

          if (!authProvider.isAuthenticated) {
            // New User Registration
            await authProvider.signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
              ign: _ignController.text.trim(),
              whatsapp: whatsapp,
              efootballUid: efootballUid,
            );
            playerId = authProvider.user?.uid;
          } else {
            // Authenticated user linking a profile for the first time
            playerId = authProvider.user?.uid;
          }
        }

        if (playerId == null) throw Exception("Failed to identify Player Account");

        // 3. Handle Image Upload
        if (_imageBytes != null) {
          photoUrl = await StorageService().uploadPlayerAvatar(
            playerId: playerId,
            fileBytes: _imageBytes!,
          );
        }

        // 4. Save/Update Profile Document
        late final Player player;
        
        if (widget.player != null) {
          // Preserve all existing fields and only update changed ones
          player = widget.player!.copyWith(
            name: _nameController.text.trim(),
            ign: _ignController.text.trim(),
            uid: efootballUid,
            whatsapp: whatsapp,
            profileImageUrl: photoUrl,
          );
        } else {
          // New Registration
          player = Player(
            id: playerId,
            name: _nameController.text.trim(),
            email: authProvider.user?.email ?? _emailController.text.trim(),
            ign: _ignController.text.trim(),
            uid: efootballUid,
            whatsapp: whatsapp,
            profileImageUrl: photoUrl,
            totalPoints: 0,
            goalsFor: 0,
            goalsAgainst: 0,
            wins: 0,
            draws: 0,
            losses: 0,
            matchesPlayed: 0,
            monthlyPoints: 0,
            monthlyGoalsFor: 0,
            monthlyGoalsAgainst: 0,
            monthlyWins: 0,
            monthlyDraws: 0,
            monthlyLosses: 0,
            monthlyMatchesPlayed: 0,
            champions: 0,
            runnersUp: 0,
            goldenBoots: 0,
            achievements: [],
            trophies: [],
            role: 'player',
          );
        }

        await dbService.updatePlayer(player);
        await authProvider.fetchPlayerProfile(playerId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentGreen,
              content: Text(
                widget.player == null ? 'Welcome to the eFootballers Bangladesh family!' : 'Profile successfully updated!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMsg;
        switch (e.code) {
          case 'email-already-in-use':
            errorMsg = 'This email is already registered. Please use a different email or log in.';
            break;
          case 'invalid-email':
            errorMsg = 'The email address provided is not valid.';
            break;
          case 'weak-password':
            errorMsg = 'The password is too weak. Please use at least 6 characters.';
            break;
          case 'network-request-failed':
            errorMsg = 'Network connection failed. Please check your internet.';
            break;
          default:
            errorMsg = e.message ?? 'Registration failed. Please try again.';
        }

        if (mounted) {
          setState(() {
            _errorMessage = errorMsg;
          });
          // Scroll to top to make error visible
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      } catch (e) {
        if (mounted) {
          String userFriendlyError = e.toString().replaceAll('Exception: ', '').trim();
          
          if (userFriendlyError.contains('permission-denied')) {
            userFriendlyError = 'Access denied. Please make sure you are logged in and try again.';
          } else if (userFriendlyError.contains('network-request-failed')) {
            userFriendlyError = 'No internet connection. Please check your network.';
          } else if (userFriendlyError.contains('user-not-found')) {
            userFriendlyError = 'No account found with this email.';
          } else if (userFriendlyError.contains('wrong-password')) {
            userFriendlyError = 'Incorrect password. Please try again.';
          } else if (userFriendlyError.contains('INTERNAL ASSERTION FAILED')) {
            userFriendlyError = 'Database synchronization error. Please refresh the page and try again.';
          }

          setState(() {
            _errorMessage = userFriendlyError;
          });
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
}
