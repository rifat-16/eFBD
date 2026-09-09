import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityConfig {
  final String facebookGroup;
  final String facebookPage;
  final String whatsappGroup;

  CommunityConfig({
    required this.facebookGroup,
    required this.facebookPage,
    required this.whatsappGroup,
  });

  factory CommunityConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityConfig(
      facebookGroup: data['facebookGroup'] ?? '',
      facebookPage: data['facebookPage'] ?? '',
      whatsappGroup: data['whatsappGroup'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'facebookGroup': facebookGroup,
      'facebookPage': facebookPage,
      'whatsappGroup': whatsappGroup,
    };
  }

  CommunityConfig copyWith({
    String? facebookGroup,
    String? facebookPage,
    String? whatsappGroup,
  }) {
    return CommunityConfig(
      facebookGroup: facebookGroup ?? this.facebookGroup,
      facebookPage: facebookPage ?? this.facebookPage,
      whatsappGroup: whatsappGroup ?? this.whatsappGroup,
    );
  }
}
