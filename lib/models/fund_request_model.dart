class FundRequestModel {
  final String id;
  final String requestedBy;
  final String title;
  final int amount;
  final String reason;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final String? requesterName;
  final String? requesterNis;

  const FundRequestModel({
    required this.id,
    required this.requestedBy,
    required this.title,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.requesterName,
    this.requesterNis,
  });

  factory FundRequestModel.fromMap(Map<String, dynamic> map) {
    final profiles = map['profiles'] as Map<String, dynamic>?;
    
    final requestedBy = map['student_id'] as String? ?? map['requested_by'] as String? ?? '';
    
    final description = map['description'] as String? ?? '';
    String title = map['title'] as String? ?? '';
    String reason = map['reason'] as String? ?? '';
    
    if (description.isNotEmpty && title.isEmpty) {
      final parts = description.split('\n\nAlasan: ');
      title = parts.isNotEmpty ? parts[0] : description;
      if (parts.length > 1) {
        reason = parts[1];
      }
    }

    return FundRequestModel(
      id: map['id'] as String,
      requestedBy: requestedBy,
      title: title,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      reason: reason,
      status: map['status'] as String? ?? 'pending',
      reviewedBy: map['resolved_by'] as String? ?? map['reviewed_by'] as String?,
      reviewedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'] as String)
          : (map['reviewed_at'] != null ? DateTime.tryParse(map['reviewed_at'] as String) : null),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      requesterName: profiles?['full_name'] as String?,
      requesterNis: profiles?['nis'] as String?,
    );
  }

  bool get isPending => status == 'pending';
}
