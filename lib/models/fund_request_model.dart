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
    return FundRequestModel(
      id: map['id'] as String,
      requestedBy: map['requested_by'] as String,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num).toInt(),
      reason: map['reason'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      requesterName: profiles?['full_name'] as String?,
      requesterNis: profiles?['nis'] as String?,
    );
  }

  bool get isPending => status == 'pending';
}
