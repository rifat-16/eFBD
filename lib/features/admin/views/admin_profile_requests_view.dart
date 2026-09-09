import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminProfileRequestsView extends StatefulWidget {
  const AdminProfileRequestsView({super.key});

  @override
  State<AdminProfileRequestsView> createState() => _AdminProfileRequestsViewState();
}

class _AdminProfileRequestsViewState extends State<AdminProfileRequestsView> {
  final DatabaseService _db = DatabaseService();

  void _handleApprove(Map<String, dynamic> request) async {
    try {
      await _db.approveProfileUpdateRequest(
        request['id'],
        request['userId'],
        request['requestedData'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentGreen,
            content: Text(
              'REQUEST APPROVED AND PLAYER PROFILE UPDATED.',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'ERROR UPDATING PROFILE: ${e.toString().toUpperCase()}',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }
  }

  void _handleReject(Map<String, dynamic> request) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'REJECT UPDATE REQUEST',
          style: GoogleFonts.rajdhani(
            color: Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection. This will be visible to the user.',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'REJECTION REASON',
                labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                hintText: 'e.g. Invalid UID provided',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              await _db.rejectProfileUpdateRequest(request['id'], reasonController.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('REQUEST REJECTED.', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'REJECT',
              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE UPDATE REQUESTS',
            style: GoogleFonts.rajdhani(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getProfileUpdateRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading requests',
                          style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            snapshot.error.toString(),
                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No pending update requests.',
                          style: GoogleFonts.rajdhani(color: AppTheme.textGrey, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _RequestCard(
                      request: req,
                      onApprove: () => _handleApprove(req),
                      onReject: () => _handleReject(req),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final current = request['currentData'] as Map<String, dynamic>? ?? {};
    final requested = request['requestedData'] as Map<String, dynamic>? ?? {};
    final createdAt = (request['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USER ID: ${request['userId']}',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'APPROVE',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'REJECT',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComparisonRow('Real Name', current['realName'], requested['realName']),
                    const SizedBox(height: 12),
                    _buildComparisonRow('In-Game Name', current['ign'], requested['ign']),
                    const SizedBox(height: 12),
                    _buildComparisonRow('eFootball UID', current['eFootballUid'], requested['eFootballUid']),
                    const SizedBox(height: 12),
                    _buildComparisonRow('WhatsApp', current['whatsapp'], requested['whatsapp']),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REASON FOR CHANGE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request['reason'] ?? 'No reason provided.',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, dynamic oldVal, dynamic newVal) {
    final bool isChanged = oldVal != newVal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            color: AppTheme.textGrey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              oldVal?.toString() ?? 'N/A',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
            ),
            if (isChanged) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.textGrey),
              ),
              Text(
                newVal?.toString() ?? 'N/A',
                style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
